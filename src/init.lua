--[[

   __    ______            _          
  / /__ / ____/___  ____ _(_)___  ___ 
 / __(_) __/ / __ \/ __ `/ / __ \/ _ \
/ /__ / /___/ / / / /_/ / / / / /  __/
\__(_)_____/_/ /_/\__, /_/_/ /_/\___/ 
                 /____/    
                 
Programmer(s): CodedJimmy

]]

local RunService = game:GetService("RunService")
if RunService:IsClient() then
    return require(script.Client)
else
    return require(script.Server)
end