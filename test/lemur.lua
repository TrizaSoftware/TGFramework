local lemur = require("lemur")

local ModulesToLoad = {
    TGFramework = "src",
    TestEZ = "modules/testez/src"
}

local habitat = lemur.Habitat.new()

local ReplicatedStorage = habitat.game:GetService("ReplicatedStorage")

for moduleName, modulePath in pairs(ModulesToLoad) do
    local loadedModule = habitat:loadFromFs(modulePath)
    loadedModule.Name = moduleName
    loadedModule.Parent = ReplicatedStorage
end