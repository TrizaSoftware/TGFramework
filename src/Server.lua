local Dependencies = script.Parent.Dependencies
local Promise = require(Dependencies.RbxLuaPromise)
local Signal = require(Dependencies.Signal)
local Networking = require(Dependencies.Networking)
local ServiceEventsFolder = Instance.new("Folder")
ServiceEventsFolder.Parent = script.Parent
ServiceEventsFolder.Name = "ServiceEvents"
local _warn = warn
local function warn(...)
    _warn("[TGFramework Server]:",...)
end
local Services = {}
local TGFrameworkServer = {}

--[[
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
]]

function TGFrameworkServer:GetService(service:string)
    assert(TGFrameworkServer.Started, "You can't get a Service when t:Engine hasn't started.")
    assert(Services[service], string.format("%s isn't a valid Service.", service))
    return Services[Services]
end

function TGFrameworkServer:CreateService(config)
    assert(config.Name, "A service must have a name.")
    assert(not Services[config.Name], string.format("A Service with the name of %s already exists.", config.Name))
    local Service = config
    Services[Service.Name] = config
    return Service
end

function TGFrameworkServer:AddServices(directory:Folder, deep:boolean)
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

function TGFrameworkServer:Start()
    return Promise.new(function(resolve, reject, onCancel)
        for _, Service in Services do
            task.spawn(function()
                if Service.Client then
                    local ServiceFolder = Instance.new("Folder")
                    ServiceFolder.Parent = ServiceEventsFolder
                    ServiceFolder.Name = Service.Name
                    local RemoteFunctions = Instance.new("Folder")
                    RemoteFunctions.Parent = ServiceFolder
                    RemoteFunctions.Name = "RemoteFunctions"
                    local ClientSignalEvents = Instance.new("Folder")
                    ClientSignalEvents.Parent = ServiceFolder
                    ClientSignalEvents.Name = "ClientSignalEvents"
                    for property, value in Service.Client do
                        if typeof(value) == "function" then
                            local RemoteFunction = Instance.new("RemoteFunction")
                            RemoteFunction.Parent = RemoteFunctions
                            RemoteFunction.Name = property
                            Networking:HandleRemoteFunction(RemoteFunction):Connect(
                                function(...)
                                    return value(...)
                                end
                            )
                        elseif typeof(value) == "string" and value:find("Signal") then
                            local SignalType = value:split(":")[2]
                            local Remote = nil
                            if SignalType == "Event" then
                                Remote = Instance.new("RemoteEvent")
                            else
                                Remote = Instance.new("RemoteFunction")
                            end
                            Services[Service.Name].Client[property] = if Remote:IsA("RemoteFunction") then Networking:HandleRemoteFunction(Remote) else Networking:HandleRemoteEvent(Remote)
                            Remote.Name = property
                            Remote.Parent = ClientSignalEvents
                        end
                    end
                end
				if Service["Initialize"] then
					Service:Initialize()
				end
            end)
        end
        self.OnStart:Fire()
        TGFrameworkServer.Started = true
        resolve(true)
    end)
end

TGFrameworkServer.Started = false
TGFrameworkServer.OnStart = Signal.new()
TGFrameworkServer.Dependencies = Dependencies
TGFrameworkServer.Networking = Networking

return TGFrameworkServer