local Dependencies = script.Parent.Dependencies
local Promise = require(Dependencies.RbxLuaPromise)
local Signal = require(Dependencies.Signal)
local Networking = require(Dependencies.Networking)
local TNet = require(Dependencies.TNet)
local ServiceEventsFolder = Instance.new("Folder")
ServiceEventsFolder.Parent = script.Parent
ServiceEventsFolder.Name = "ServiceEvents"
local _warn = warn
local function warn(...)
    _warn("[TGFramework Server]:",...)
end

--[=[
    @type Service { Name: string, Client: { [any]: any }, TNet: any, [any]: any }
    @within TGFrameworkServer
]=]

type Service = {
    Name: string,
    Client: {
      [any]: any
    },
    TNet: any,
    [any]: any
}

local function formatMiddleware(Middleware: {}, ServiceName: string)
    local NewMiddleware = {}
    NewMiddleware = Middleware.RequestsPerMinute
    for MiddlewareType, Functions in Middleware do
        if MiddlewareType ~= "RequestsPerMinute" then
            assert(MiddlewareType == "Inbound" or MiddlewareType == "Outbound", "Invalid Middleware Type.")
            NewMiddleware[MiddlewareType] = {}
            for _, func in Functions do
                table.insert(NewMiddleware[MiddlewareType], function(...)
                    task.spawn(func, ServiceName, ...)
                end)
            end
        end
    end
    return NewMiddleware
end

local Services = {}

--[=[
    The Server Instance for TGFramework

    @class TGFrameworkServer
]=]
local TGFrameworkServer = {}

TGFrameworkServer.Started = false
TGFrameworkServer.OnStart = Signal.new()
TGFrameworkServer.Dependencies = Dependencies
TGFrameworkServer.Networking = Networking
TGFrameworkServer.TNet = TNet.new()

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

--[=[
    Gets the requested service.

    @param service string

    @error Isn't a Valid Service -- Happens when the service isn't registered.
]=]

function TGFrameworkServer:GetService(service: string): Service
    assert(Services[service], string.format("%s isn't a valid Service.", service))
    return Services[service]
end

--[=[
    Creates a service with the configuration data.

    @param config {Name: string, Client: {[any]: any}, [any]: any}
    @return Service
]=]

function TGFrameworkServer:CreateService(config): Service
    assert(config.Name, "A name must be specified for a Service.")
    assert(not Services[config.Name], string.format("A Service with the name of %s already exists.", config.Name))
    assert(not TGFrameworkServer.Started, "You can't create a service when TGFramework has already started.")
    local Service = config
    Services[Service.Name] = config
    return Service
end

function TGFrameworkServer:AddServices(directory: Folder, deep: boolean)
    local items = deep and directory:GetDescendants() or directory:GetChildren()
    for _, item in items do
        if item:IsA("ModuleScript") then
            Promise.try(function()
                require(item)
            end):catch(function(err)
                warn(err)
            end)
        end
    end
end

function TGFrameworkServer:Start(args: {})
    args = args or {}
    return Promise.new(function(resolve, reject, onCancel)
        local InitializationQueue = {}

        for Service, _ in Services do
            table.insert(InitializationQueue, Service)
        end

        for _, ServiceName in InitializationQueue do
            local Data = Services[ServiceName]
            local DepNumber = Data.Dependencies and #Data.Dependencies or 0
            local LastPos = table.find(InitializationQueue, ServiceName)
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
            table.insert(InitializationQueue, NewIndex, ServiceName)
        end

        -- Setup Networking

        for _, Service in Services do
            Service.TNet = Service.Middleware and TNet.new() or TGFrameworkServer.TNet
            if Service.Middleware then
                Service.TNet.Middleware = Service.Middleware
            end
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
                        local Handler = Service.TNet:HandleRemoteFunction(RemoteFunction)
                        if args.Middleware and not Service.Middleware then
                            Handler.Middleware = formatMiddleware(args.Middleware, Service.Name)
                        end
                        Handler:Connect(
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
                        local Handler = Remote:IsA("RemoteFunction") and Service.TNet:HandleRemoteFunction(Remote) or Service.TNet:HandleRemoteEvent(Remote)
                        if args.Middleware and not Service.Middleware then
                            Handler.Middleware = formatMiddleware(args.Middleware, Service.Name)
                        end
                        Services[Service.Name].Client[property] = Handler
                        Remote.Name = property
                        Remote.Parent = ClientSignalEvents
                    end
                end
            end
        end

        -- Initialize Services

        local InitializationPromises = {}

        for i, ServiceName: string in InitializationQueue do
            local Service = Services[ServiceName]
            if Service.Initialize then
                table.insert(InitializationPromises, #InitializationPromises + 1,
                    Promise.new(function(serviceResolve)
                        debug.setmemorycategory(Service.Name)
                        Service:Initialize()
                        serviceResolve()
                    end)
                )
            end
        end
        resolve(Promise.all(InitializationPromises))
    end):andThen(function()
        for _, Service in Services do
            task.spawn(function()
                if Service.Start then
                    debug.setmemorycategory(Service.Name)
                    Service:Start()
                end
            end)
        end

        self.OnStart:Fire()
        TGFrameworkServer.Started = true
    end)
end

return TGFrameworkServer