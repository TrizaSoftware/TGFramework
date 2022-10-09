local Dependencies = script.Parent.Dependencies
local Promise = require(Dependencies.RbxLuaPromise)
local Signal = require(Dependencies.Signal)
local Networking = require(Dependencies.Networking)
local ServiceEventsFolder = script.Parent:WaitForChild("ServiceEvents")
local _warn = warn
local function warn(...)
    _warn("[t:Engine Client]:",...)
end
local ClientServices = {}
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

function tEngineClient:GetClientService(service)
  assert(ClientServices[service], string.format("%s isn't a valid ClientService.", service))
  return ClientServices[service]
end

function tEngineClient:CreateClientService(config)
  assert(config.Name, "A name must be specified for a ClientService.")
  assert(not ClientServices[config.Name], string.format("A ClientService with the name of %s already exists.", config.Name))
  local service = config
  ClientServices[config.Name] = config
  return service
end

function tEngineClient:AddClientServices(directory:Folder)
  for _, item in directory:GetDescendants() do
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
    for _, ClientService in ClientServices do
        task.spawn(function()
            if ClientService["Initialize"] then
              ClientService:Initialize()
            end
        end)
    end
    self.OnStart:Fire()
    resolve(true)
end)
end

tEngineClient.OnStart = Signal.new()
tEngineClient.Dependencies = Dependencies

return tEngineClient