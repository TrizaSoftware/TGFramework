local Dependencies = script.Parent.Dependencies
local Promise = require(Dependencies.RbxLuaPromise)
local _warn = warn
local function warn(...)
    _warn("[t:Engine Server]:",...)
end
local Services = {}
local tEngineServer = {}

function tEngineServer:GetService(service:string)
    assert(Services[service], string.format("%s isn't a valid service.", service))
    return Services[Services]
end

function tEngineServer:CreateService(config)
    assert(config.Name, "A service must have a name.")
    assert(not Services[config.Name], string.format("A service with the name of %s already exists.", config.Name))
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
            if Service["Initialize"] then
                Service:Initialize()
            end
        end
        resolve(true)
    end)
end

return tEngineServer