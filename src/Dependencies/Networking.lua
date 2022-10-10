local RunService = game:GetService("RunService")

local Networking = {}

function Networking:CreateSignal(type)
  assert(type == "Event" or type == "Function", "Invalid type for signal.")
  return string.format("Signal:%s", type)
end

local RemoteFunction = {}
RemoteFunction.__index = RemoteFunction

function Networking:HandleRemoteFunction(event)
  local self = setmetatable({}, RemoteFunction)
  self.Event = event
  return self
end

function RemoteFunction:Fire(...)
  if RunService:IsServer() then
    return self.Event:InvokeClient(...)
  else
    return self.Event:InvokeServer(...)
  end
end

function RemoteFunction:Connect(...)
  if RunService:IsServer() then
    self.Event.OnServerInvoke = ...
  else
    self.Event.OnClientInvoke = ...
  end
end

local RemoteEvent = {}
RemoteEvent.__index = RemoteEvent

function Networking:HandleRemoteEvent(event)
  local self = setmetatable({}, RemoteEvent)
  self.Event = event
  return self
end

function RemoteEvent:FireAllClients(...)
  assert(RunService:IsServer(), "This method can only be called on the server.")
  self.Event:FireAllClients(...)
end

function RemoteEvent:FireToGroup(group, ...)
  assert(RunService:IsServer(), "This method can only be called on the server.")
  for _, player in group do
    self:Fire(player, ...)
  end
end

function RemoteEvent:Fire(...)
  if RunService:IsServer() then
    self.Event:FireClient(...)
  else
    self.Event:FireServer(...)
  end
end

function RemoteEvent:Connect(...)
  if RunService:IsServer() then
    return self.Event.OnServerEvent:Connect(...)
  else
    return self.Event.OnClientEvent:Connect(...)
  end
end

return Networking