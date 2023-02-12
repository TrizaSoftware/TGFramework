local Dependencies = script.Parent.Dependencies
local Promise = require(Dependencies.RbxLuaPromise)
local Signal = require(Dependencies.Signal)
local TNet = require(Dependencies.TNet)
local TNetMain = TNet.new()
local ServiceEventsFolder = script.Parent:WaitForChild("ServiceEvents")
local _warn = warn
local function warn(...)
    _warn("[TGFramework Client]:",...)
end

type Controller = {
  Name: string,
  [any]: any
}

type Service = {
  [any]: any | (any) -> any
}


local Controllers = {}
local TGFrameworkClient = {}
local SignalEvents = {}

local function setupMiddleware(Controller, remoteHandler)
  if Controller.Middleware then
    if not remoteHandler.Middleware.Inbound and not remoteHandler.Middleware.Outbound then
      remoteHandler.Middleware = {
        Inbound = {},
        Outbound = {}
      }
    end
    if Controller.Middleware.Inbound then
      for _, func in Controller.Middleware.Inbound do
        table.insert(remoteHandler.Middleware.Inbound, func)
      end
    end
    if Controller.Middleware.Outbound then
      for _, func in Controller.Middleware.Outbound do
        table.insert(remoteHandler.Middleware.Outbound, func)
      end
    end
  end
end

local function formatService(controllerName, service)
  local serviceFolder = ServiceEventsFolder:FindFirstChild(service)
  local formattedService = {}
  local Controller = Controllers[controllerName]
  for _, item in serviceFolder.RemoteFunctions:GetChildren() do
    local remoteHandler = SignalEvents[item]
    if not remoteHandler then
      local createdRH = TNetMain:HandleRemoteFunction(item)
      SignalEvents[item] = createdRH
      remoteHandler = createdRH
    end
    setupMiddleware(Controller, remoteHandler)
    formattedService[item.Name] = function(...)
      return remoteHandler:Fire(...)
    end
  end
  for _, item in serviceFolder.ClientSignalEvents:GetChildren() do
    local remoteHandler = SignalEvents[item]
    if not remoteHandler then
      local createdRH = item:IsA("RemoteFunction") and TNetMain:HandleRemoteFunction(item) or TNetMain:HandleRemoteEvent(item)
      SignalEvents[item] = createdRH
      remoteHandler = createdRH
    end
    setupMiddleware(Controller, remoteHandler)
    formattedService[item.Name] = remoteHandler
  end
  return formattedService
end

function TGFrameworkClient:GetService(service: string, timeToWait: number): Service
  assert(timeToWait and ServiceEventsFolder:WaitForChild(service, timeToWait) or ServiceEventsFolder:FindFirstChild(service), string.format("%s isn't a valid Service.", service))
  local items = debug.traceback():split("GetService")[2]:split(":")[1]:split(".")
  local controllerName = items[#items]
  return formatService(controllerName, service)
end

function TGFrameworkClient:GetController(controller: string): Controller
  assert(Controllers[controller], string.format("%s isn't a valid Controller.", controller))
  return Controllers[controller]
end

function TGFrameworkClient:CreateController(config): Controller
  assert(config.Name, "A name must be specified for a Controller.")
  assert(not Controllers[config.Name], string.format("A Controller with the name of %s already exists.", config.Name))
  assert(not TGFrameworkClient.Started, "You can't create a controller when TGFramework has already started.")
  local service = config
  Controllers[config.Name] = config
  return service
end

function TGFrameworkClient:AddControllers(directory: Folder, deep: boolean)
  for _, item in if deep then directory:GetDescendants() else directory:GetChildren() do
      if item:IsA("ModuleScript") then
          Promise.try(function()
              require(item)
          end):catch(function(err)
              warn(err)
          end)
      end
  end
end

function TGFrameworkClient:Start(args: {})
  args = args or {}
  return Promise.new(function(resolve, reject, onCancel)
    local InitializationQueue = {}

    for Controller, _ in Controllers do
      table.insert(InitializationQueue, Controller)
    end

    for _, ControllerName in InitializationQueue do
        local Data = Controllers[ControllerName]
        local DepNumber = Data.Dependencies and #Data.Dependencies or 0
        local LastPos = table.find(InitializationQueue, ControllerName)
        local NewIndex = 0
        if DepNumber > 0 then
          for _, Dependency in Data.Dependencies do
              local DepIndex = table.find(InitializationQueue, Dependency)
              if DepIndex > NewIndex then
                   NewIndex = DepIndex + 1
              end
          end
        else
            NewIndex = 1
        end
        table.remove(InitializationQueue, LastPos)
        table.insert(InitializationQueue, NewIndex, ControllerName)
    end

    -- Setup Middleware

    if args.Middleware then
      for middlewareType, tab in args.Middleware do
        assert(middlewareType == "Inbound" or middlewareType == "Outbound", "Invalid Middleware Type.")
        for _, func in tab do
          for _, handler in SignalEvents do
            if not handler.Middleware.Inbound and not handler.Middleware.Outbound then
              handler.Middleware = {
                Inbound = {},
                Outbound = {}
              }
            end
            table.insert(handler.Middleware[middlewareType], func)
          end
        end
      end
    end

    -- Initialize Controllers

    local InitializationPromiseFunctions = {}

    for i, ControllerName in InitializationQueue do
      local Controller = Controllers[ControllerName]
      if Controller.Initialize then
        table.insert(InitializationPromiseFunctions, i, function()
          return Promise.new(function(controllerResolve)
            debug.setmemorycategory(Controller.Name)
            Controller:Initialize()
            controllerResolve()
          end)
        end)
      end
    end
    resolve(Promise.all(InitializationPromiseFunctions))
  end):andThen(function()
    for _, Controller in Controllers do
      task.spawn(function()
        if Controller.Start then
          debug.setmemorycategory(Controller.Name)
          Controller:Start()
        end
      end)
    end

    self.OnStart:Fire()
    TGFrameworkClient.Started = true
  end)
end

TGFrameworkClient.Started = false
TGFrameworkClient.OnStart = Signal.new()
TGFrameworkClient.Dependencies = Dependencies
TGFrameworkClient.TNet = TNetMain

return TGFrameworkClient