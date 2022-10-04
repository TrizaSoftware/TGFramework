local Dependencies = script.Parent.Dependencies
local Promise = require(Dependencies.RbxLuaPromise)
local Signal = require(Dependencies.Signal)
local _warn = warn
local function warn(...)
    _warn("[t:Engine Server]:",...)
end
local Services = {}
local tEngineServer = {}

local function formatService(service)
    assert(Services[service], string.format("%s isn't a valid Service.", service))
    local newService = {}
    for property, value in Services[service] do
        if property == "Client" then
            continue
        elseif typeof(property) == "function" then
            newService[property] = function()
            end
        end
    end
end

function tEngineServer:GetService(service:string)
    assert(Services[service], string.format("%s isn't a valid Service.", service))
    return Services[Services]
end

function tEngineServer:CreateService(config)
    assert(config.Name, "A service must have a name.")
    assert(not Services[config.Name], string.format("A Service with the name of %s already exists.", config.Name))
    local service = config
    Services[service] = config
    return service
end

function tEngineServer:AddServices(directory:Folder)
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

function tEngineServer:Start()
    return Promise.new(function(resolve, reject, onCancel)
        for _, Service in Services do
            task.spawn(function()
                if Service["Initialize"] then
                    Service:Initialize()
                end
                for property, value in Service do
                    if typeof(property) == "function" then
                    end
                end
            end)
        end
        self.OnStart:Fire()
        self.MainSignal:Connect(function(plr, req, ...)
            local Data = {...}
            if req == "getService" then
                return 
            end
        end)
        resolve(true)
    end)
end

tEngineServer.OnStart = Signal.new()
tEngineServer.MainSignal = Signal.new("RemoteFunction")
tEngineServer.MainSignal.Event.Parent = script.Parent
tEngineServer.MainSignal.Event.Name = "tEngineGateway"
tEngineServer.Dependencies = Dependencies

return tEngineServer