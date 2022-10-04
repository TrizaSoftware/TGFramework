local RunService = game:GetService("RunService")
local Signal = {}
Signal.SignalTypes = {
	"BindableEvent",
	"RemoteEvent",
	"RemoteFunction"
}
Signal.__index = Signal

function Signal.new(type:string)
	type = type or "BindableEvent"
	assert(table.find(Signal.SignalTypes, type), string.format("%s isn't a valid SignalType", type))
	local self = setmetatable({}, Signal)
	self.Type = type

	self.Event = if type == "RemoteEvent" then Instance.new("RemoteEvent") elseif type == "RemoteFunction" then Instance.new("RemoteFunction") else Instance.new("BindableEvent")
	return self	
end

function Signal:createNewFromExisting(event)
	assert(table.find(Signal.SignalTypes, event.ClassName), string.format("%s isn't a valid SignalType", event.ClassName))
	local self = setmetatable({}, Signal)
	self.Type = event.ClassName
	self.Event = event
	return self
end

function Signal:Connect(...)
	local Connection
	if self.Type == "BindableEvent" then
		Connection = self.Event.Event:Connect(...)
	elseif self.Type == "RemoteEvent" then
		if RunService:IsServer() then
			Connection = self.Event.OnServerEvent:Connect(...)
		else
			Connection = self.Event.OnClientEvent:Connect(...)
		end
	elseif self.Type == "RemoteFunction" then
		if RunService:IsServer() then
			self.Event.OnServerInvoke = ...
		else
			self.Event.OnClientInvoke = ...
		end
	end
	return Connection
end

function Signal:Fire(...)
	assert(self.Type == "BindableEvent", "Fire is only available on BindableEvents")
	self.Event:Fire(...)
end

function Signal:FireAllClients(...)
	assert(self.Type == "RemoteEvent", "FireAllClients is only available on RemoteEvents")
	if RunService:IsServer() then
		self.Event:FireAllClients(...)
	else
		self.Event:FireAllClients(...)
	end
end

function Signal:FireToGroup(group, ...)
	assert(self.Type == "RemoteEvent", "FireToGroup is only available on RemoteEvents")
	for _, player in group do
		self.Event:FireClient(player, ...)
	end
end

function Signal:InvokeServer(...)
	assert(self.Type == "RemoteFunction", "InvokeServer is only available on RemoteFunctions")
	self.Event:InvokeServer(...)
end

function Signal:InvokeClient(...)
	assert(self.Type == "RemoteFunction", "InvokeClient is only available on RemoteFunctions")
	self.Event:InvokeClient(...)
end

function Signal:Wait()
	assert(self.Type == "BindableEvent", "Wait is only available on BindableEvents")
	self.Event.Event:Wait()
end

function Signal:Destroy()
	self.Event:Destroy()
	self.Event = nil
	setmetatable(self, nil)
end

return Signal