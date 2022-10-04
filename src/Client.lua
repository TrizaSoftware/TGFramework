local Dependencies = script.Parent.Dependencies
local Promise = require(Dependencies.RbxLuaPromise)
local Signal = require(Dependencies.Signal)
local _warn = warn
local function warn(...)
    _warn("[t:Engine Client]:",...)
end
local ClientServices = {}
local tEngineClient = {}

function tEngineClient:GetService(service)
 return self.MainSignal:InvokeServer("getService", service)
end

function tEngineClient:GetClientService(service)
  assert(ClientServices[service], string.format("%s isn't a valid ClientService.", service))
  return ClientServices[service]
end

function tEngineClient:CreateClientService(config)
  assert(config.Name, "A name must be specified for a ClientService.")
  assert(not ClientServices[config.Name], string.format("A ClientService with the name of %s already exists.", config.Name))
  local service = config
  ClientServices[service] = config
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
    self.MainSignal:Connect(function(plr, req)

    end)
    resolve(true)
end)
end

tEngineClient.MainSignal = Signal:createNewFromExisting(script.Parent:WaitForChild("tEngineGateway"))
tEngineClient.OnStart = Signal.new()
tEngineClient.Dependencies = Dependencies

return tEngineClient