local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Networking = {}

function Networking:HandleEvent(event)
  local self = {}
  if event:IsA("RemoteEvent") then
    function self:FireAllClients(plr, ...)
      assert(RunService:IsServer(), "This method can only be called on the server.")
      event:FireAllClients(...)
    end
    function self:Fire(...)
      if RunService:IsServer() then
        event:FireClient(...)
      else
        event:FireServer(...)
      end
    end
    function self:Connect(...)
      if RunService:IsServer() then
        return event.OnServerEvent:Connect(...)
      else
        return event.OnClientEvent:Connect(...)
      end
    end
  elseif event:IsA("RemoteFunction") then
    function self:Fire(...)
      if RunService:IsServer() then
        return event:InvokeClient(...)
      else
        return event:InvokeServer(...)
      end
    end
    function self:Connect(...)
      if RunService:IsServer() then
        event.OnServerInvoke = ...
      else
        event.OnClientInvoke = ...
      end
    end
  end
  return self
end

return Networking