--[[
  __________________                                             __  
 /_  __/ ____/ ____/________ _____ ___  ___ _      ______  _____/ /__
  / / / / __/ /_  / ___/ __ `/ __ `__ \/ _ \ | /| / / __ \/ ___/ //_/
 / / / /_/ / __/ / /  / /_/ / / / / / /  __/ |/ |/ / /_/ / /  / ,<   
/_/  \____/_/   /_/   \__,_/_/ /_/ /_/\___/|__/|__/\____/_/  /_/|_|  
                                    

Programmer(s): CodedJimmy

]]

local RunService = game:GetService("RunService")
if RunService:IsClient() then
    return require(script.Client)
else
    return require(script.Server)
end