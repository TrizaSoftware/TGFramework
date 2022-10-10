local Dependencies = script.Parent.Dependencies
local Promise = require(Dependencies.RbxLuaPromise)
local Signal = require(Dependencies.Signal)
local Networking = require(Dependencies.Networking)
local ServiceEventsFolder = script.Parent:WaitForChild("ServiceEvents")
local _warn = warn
local function warn(...)
    _warn("[t:Engine Client]:",...)
end
local Controllers = {}
local tEngineClient = {}

local function formatService(service)
  local serviceFolder = ServiceEventsFolder:FindFirstChild(service)
  local formattedService = {}
  for _, item in serviceFolder.RemoteFunctions:GetChildren() do
    formattedService[item.Name] = function(...)
      return item:InvokeServer(...)
    end
  end
  for _, item in serviceFolder.ClientSignalEvents:GetChildren() do
    formattedService[item.Name] = if item:IsA("RemoteFunction") then Networking:HandleRemoteFunction(item) else Networking:HandleRemoteEvent(item)
  end
  return formattedService
end

function tEngineClient:GetService(service)
  assert(ServiceEventsFolder:FindFirstChild(service), string.format("%s isn't a valid Service.", service))
  return formatService(service)
end

function tEngineClient:GetController(controller)
  assert(tEngineClient.Started, "You can't get a Controller when t:Engine hasn't started.")
  assert(Controllers[controller], string.format("%s isn't a valid Controller.", controller))
  return Controllers[controller]
end

function tEngineClient:CreateController(config)
  assert(config.Name, "A name must be specified for a Controller.")
  assert(not Controllers[config.Name], string.format("A Controller with the name of %s already exists.", config.Name))
  local service = config
  Controllers[config.Name] = config
  return service
end

function tEngineClient:AddControllers(directory:Folder, deep:boolean)
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

function tEngineClient:Start()
  return Promise.new(function(resolve, reject, onCancel)
    for _, Controller in Controllers do
        task.spawn(function()
            if Controller["Initialize"] then
              Controller:Initialize()
            end
        end)
    end
    self.OnStart:Fire()
    tEngineClient.Started = true
    resolve(true)
end)
end

tEngineClient.Started = false
tEngineClient.OnStart = Signal.new()
tEngineClient.Dependencies = Dependencies

return tEngineClient