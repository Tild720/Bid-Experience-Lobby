local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local VoiceChatService = game:GetService("VoiceChatService")

local roomsFolder = ReplicatedStorage:FindFirstChild("Rooms")
if not roomsFolder then
	roomsFolder = Instance.new("Folder")
	roomsFolder.Name = "Rooms"
	roomsFolder.Parent = ReplicatedStorage
end

local createRoomEvent = ReplicatedStorage:FindFirstChild("CreateRoomEvent")
if not createRoomEvent then
	createRoomEvent = Instance.new("RemoteEvent")
	createRoomEvent.Name = "CreateRoomEvent"
	createRoomEvent.Parent = ReplicatedStorage
end

local createRoomFunction = ReplicatedStorage:FindFirstChild("CreateRoomFunction")
if not createRoomFunction then
	createRoomFunction = Instance.new("RemoteFunction")
	createRoomFunction.Name = "CreateRoomFunction"
	createRoomFunction.Parent = ReplicatedStorage
end

local joinRoomFunction = ReplicatedStorage:FindFirstChild("JoinRoomFunction")
if not joinRoomFunction then
	joinRoomFunction = Instance.new("RemoteFunction")
	joinRoomFunction.Name = "JoinRoomFunction"
	joinRoomFunction.Parent = ReplicatedStorage
end

local leaveRoomEvent = ReplicatedStorage:FindFirstChild("LeaveRoomEvent")
if not leaveRoomEvent then
	leaveRoomEvent = Instance.new("RemoteEvent")
	leaveRoomEvent.Name = "LeaveRoomEvent"
	leaveRoomEvent.Parent = ReplicatedStorage
end

local startRoomEvent = ReplicatedStorage:FindFirstChild("StartRoomEvent")
if not startRoomEvent then
	startRoomEvent = Instance.new("RemoteEvent")
	startRoomEvent.Name = "StartRoomEvent"
	startRoomEvent.Parent = ReplicatedStorage
end

local debugFillRoomEvent = ReplicatedStorage:FindFirstChild("DebugFillRoomEvent")
if not debugFillRoomEvent then
	debugFillRoomEvent = Instance.new("RemoteEvent")
	debugFillRoomEvent.Name = "DebugFillRoomEvent"
	debugFillRoomEvent.Parent = ReplicatedStorage
end

local GAME_PLACE_ID = 98624801635176
local nextRoomId = 0
local roomPasswords = setmetatable({}, { __mode = "k" })
local VALID_SPEEDS = {
	Slow = true,
	Normal = true,
	Fast = true,
}

local function getString(settings, key, fallback)
	local value = settings[key]
	if typeof(value) == "string" and value ~= "" then
		return value
	end

	return fallback
end

local function getCapacity(capacityText)
	return tonumber(string.match(capacityText, "%d+")) or 3
end

local function getSpeed(settings)
	local speed = getString(settings, "CreateRoomSpeed", "Normal")
	return if VALID_SPEEDS[speed] then speed else "Normal"
end

local function getBoolean(settings, key)
	return settings[key] == true
end

local function canUseVoice(player)
	local success, enabled = pcall(function()
		return VoiceChatService:IsVoiceEnabledForUserIdAsync(player.UserId)
	end)

	return success and enabled == true
end

local function joinFailure(errorCode)
	return {
		Success = false,
		Error = errorCode,
	}
end

local function joinSuccess(room)
	return {
		Success = true,
		RoomName = room.Name,
	}
end

local function updateRoomCount(room)
	local members = room:FindFirstChild("Members")
	local count = if members then #members:GetChildren() else 0
	room:SetAttribute("DebugFillUserId", nil)
	room:SetAttribute("CurrentPlayers", count)

	if count <= 0 then
		room:Destroy()
	end
end

local function addMember(room, player)
	local members = room:WaitForChild("Members")
	if members:FindFirstChild(tostring(player.UserId)) then
		return
	end

	local member = Instance.new("Folder")
	member.Name = tostring(player.UserId)
	member:SetAttribute("UserId", player.UserId)
	member:SetAttribute("Name", player.Name)
	member:SetAttribute("IsOwner", room:GetAttribute("OwnerUserId") == player.UserId)
	member.Parent = members
	updateRoomCount(room)
end

local function leaveRoom(room, player)
	local members = room:FindFirstChild("Members")
	local member = members and members:FindFirstChild(tostring(player.UserId))
	if not member then
		return
	end

	local wasOwner = member:GetAttribute("IsOwner") == true
	member:Destroy()

	if wasOwner and members and #members:GetChildren() > 0 then
		local newOwner = members:GetChildren()[1]
		newOwner:SetAttribute("IsOwner", true)
		room:SetAttribute("OwnerUserId", newOwner:GetAttribute("UserId"))
		room:SetAttribute("OwnerName", newOwner:GetAttribute("Name"))
		room:SetAttribute("RoomName", `{newOwner:GetAttribute("Name")}'s Room`)
	end

	updateRoomCount(room)
end

local function leaveAllRooms(player)
	for _, room in roomsFolder:GetChildren() do
		leaveRoom(room, player)
	end
end

local function createRoom(player, settings)
	if typeof(settings) ~= "table" then
		return nil
	end

	leaveAllRooms(player)
	nextRoomId += 1

	local capacityText = getString(settings, "CreateRoomCapacity", "3 Person")
	local passwordEnabled = getBoolean(settings, "CreateRoomPasswordEnabled")
	local room = Instance.new("Folder")
	room.Name = `Room_{nextRoomId}`
	room:SetAttribute("OwnerUserId", player.UserId)
	room:SetAttribute("OwnerName", player.Name)
	room:SetAttribute("RoomName", `{player.Name}'s Room`)
	room:SetAttribute("CreatedOrder", nextRoomId)
	room:SetAttribute("Capacity", getCapacity(capacityText))
	room:SetAttribute("CurrentPlayers", 1)
	room:SetAttribute("Round", getString(settings, "CreateRoomRound", "3 Round"))
	room:SetAttribute("Theme", "Roblox")
	room:SetAttribute("Speed", getSpeed(settings))
	room:SetAttribute("PasswordEnabled", passwordEnabled)
	room:SetAttribute("VoiceOnly", getBoolean(settings, "CreateRoomVoiceOnly"))
	roomPasswords[room] = if passwordEnabled then getString(settings, "CreateRoomPassword", "") else nil
	room.Destroying:Connect(function()
		roomPasswords[room] = nil
	end)
	local members = Instance.new("Folder")
	members.Name = "Members"
	members.Parent = room
	room.Parent = roomsFolder
	addMember(room, player)

	return room.Name
end

createRoomFunction.OnServerInvoke = createRoom
createRoomEvent.OnServerEvent:Connect(createRoom)

joinRoomFunction.OnServerInvoke = function(player, roomName, password)
	if typeof(roomName) ~= "string" then
		return joinFailure("RoomUnavailable")
	end

	local room = roomsFolder:FindFirstChild(roomName)
	if not room then
		return joinFailure("RoomUnavailable")
	end

	local members = room:FindFirstChild("Members")
	if not members then
		return joinFailure("RoomUnavailable")
	end

	if members:FindFirstChild(tostring(player.UserId)) then
		return joinSuccess(room)
	end

	if room:GetAttribute("PasswordEnabled") == true and roomPasswords[room] ~= password then
		return joinFailure("IncorrectPassword")
	end

	local capacity = room:GetAttribute("Capacity") or 0
	if #members:GetChildren() >= capacity then
		return joinFailure("RoomFull")
	end

	if room:GetAttribute("VoiceOnly") == true and not canUseVoice(player) then
		return joinFailure("VoiceRequired")
	end

	if room.Parent ~= roomsFolder or room:FindFirstChild("Members") ~= members then
		return joinFailure("RoomUnavailable")
	end

	if #members:GetChildren() >= capacity then
		return joinFailure("RoomFull")
	end

	leaveAllRooms(player)
	addMember(room, player)
	return joinSuccess(room)
end

leaveRoomEvent.OnServerEvent:Connect(function(player, roomName)
	local room = roomsFolder:FindFirstChild(roomName)
	if room then
		leaveRoom(room, player)
	end
end)

debugFillRoomEvent.OnServerEvent:Connect(function(player)
	if player.Name ~= "TildStudio" then
		return
	end

	for _, room in roomsFolder:GetChildren() do
		local members = room:FindFirstChild("Members")
		if members and members:FindFirstChild(tostring(player.UserId)) then
			room:SetAttribute("DebugFillUserId", player.UserId)
			room:SetAttribute("CurrentPlayers", 3)
			return
		end
	end
end)

startRoomEvent.OnServerEvent:Connect(function(player, roomName)
	local room = roomsFolder:FindFirstChild(roomName)
	local members = room and room:FindFirstChild("Members")
	if not room or not members then
		return
	end

	local debugFilled = player.Name == "TildStudio" and room:GetAttribute("DebugFillUserId") == player.UserId
	if room:GetAttribute("OwnerUserId") ~= player.UserId or (#members:GetChildren() < 3 and not debugFilled) then
		return
	end

	local players = {}
	local memberData = {}
	local memberNames = {}
	for _, member in members:GetChildren() do
		local memberPlayer = Players:GetPlayerByUserId(member:GetAttribute("UserId"))
		if memberPlayer then
			table.insert(players, memberPlayer)
			table.insert(memberData, {
				UserId = memberPlayer.UserId,
				Name = memberPlayer.Name,
				IsOwner = member:GetAttribute("IsOwner") == true,
			})
			table.insert(memberNames, memberPlayer.Name)
		end
	end

	if #players < 3 and not debugFilled then
		return
	end

	local teleportData = {
		LobbyPlaceId = game.PlaceId,
		RoomName = room:GetAttribute("RoomName"),
		Capacity = room:GetAttribute("Capacity"),
		Round = room:GetAttribute("Round"),
		Theme = room:GetAttribute("Theme"),
		Speed = room:GetAttribute("Speed"),
		PasswordEnabled = room:GetAttribute("PasswordEnabled"),
		VoiceOnly = room:GetAttribute("VoiceOnly"),
		OwnerUserId = room:GetAttribute("OwnerUserId"),
		Members = memberData,
	}

	print(
		`Starting room "{teleportData.RoomName}" | players {#players}/{teleportData.Capacity} ({table.concat(memberNames, ", ")}) | round={teleportData.Round}, theme={teleportData.Theme}, speed={teleportData.Speed}, voiceOnly={teleportData.VoiceOnly}`
	)

	TeleportService:TeleportPartyAsync(GAME_PLACE_ID, players, teleportData)
end)

Players.PlayerRemoving:Connect(function(player)
	leaveAllRooms(player)
end)
