local RunService = game:GetService("RunService")

local Networking = {}

function Networking:HandleEvent(event)
  local self = {}
  if event:IsA("RemoteEvent") then
    function self:FireAllClients(...)
      assert(RunService:IsServer(), "This method can only be called on the server.")
      event:FireAllClients(...)
    end
    function self:FireToGroup(group, ...)
      assert(RunService:IsServer(), "This method can only be called on the server.")
      for _, player in group do
        self:Fire(player, ...)
      end
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