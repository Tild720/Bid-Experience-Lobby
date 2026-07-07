local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

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

local GAME_PLACE_ID = 98624801635176
local nextRoomId = 0

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

local function getBoolean(settings, key)
	return settings[key] == true
end

local function updateRoomCount(room)
	local members = room:FindFirstChild("Members")
	local count = if members then #members:GetChildren() else 0
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
	room:SetAttribute("Theme", getString(settings, "CreateRoomTheme", "Roblox"))
	room:SetAttribute("Mode", getString(settings, "CreateRoomMode", "Crazy"))
	room:SetAttribute("PasswordEnabled", passwordEnabled)
	room:SetAttribute("Password", if passwordEnabled then getString(settings, "CreateRoomPassword", "") else "")
	room:SetAttribute("VoiceOnly", getBoolean(settings, "CreateRoomVoiceOnly"))
	local members = Instance.new("Folder")
	members.Name = "Members"
	members.Parent = room
	room.Parent = roomsFolder
	addMember(room, player)

	return room.Name
end

createRoomFunction.OnServerInvoke = createRoom
createRoomEvent.OnServerEvent:Connect(createRoom)

joinRoomFunction.OnServerInvoke = function(player, roomName)
	local room = roomsFolder:FindFirstChild(roomName)
	if not room then
		return nil
	end

	local members = room:FindFirstChild("Members")
	if not members then
		return nil
	end

	local capacity = room:GetAttribute("Capacity") or 0
	if not members:FindFirstChild(tostring(player.UserId)) and #members:GetChildren() >= capacity then
		return nil
	end

	leaveAllRooms(player)
	addMember(room, player)
	return room.Name
end

leaveRoomEvent.OnServerEvent:Connect(function(player, roomName)
	local room = roomsFolder:FindFirstChild(roomName)
	if room then
		leaveRoom(room, player)
	end
end)

startRoomEvent.OnServerEvent:Connect(function(player, roomName)
	local room = roomsFolder:FindFirstChild(roomName)
	local members = room and room:FindFirstChild("Members")
	if not room or not members then
		return
	end

	if room:GetAttribute("OwnerUserId") ~= player.UserId or #members:GetChildren() < 3 then
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

	if #players < 3 then
		return
	end

	local teleportData = {
		RoomName = room:GetAttribute("RoomName"),
		Capacity = room:GetAttribute("Capacity"),
		Round = room:GetAttribute("Round"),
		Theme = room:GetAttribute("Theme"),
		Mode = room:GetAttribute("Mode"),
		PasswordEnabled = room:GetAttribute("PasswordEnabled"),
		VoiceOnly = room:GetAttribute("VoiceOnly"),
		OwnerUserId = room:GetAttribute("OwnerUserId"),
		Members = memberData,
	}

	print(
		`Starting room "{teleportData.RoomName}" | players {#players}/{teleportData.Capacity} ({table.concat(memberNames, ", ")}) | round={teleportData.Round}, theme={teleportData.Theme}, mode={teleportData.Mode}, voiceOnly={teleportData.VoiceOnly}`
	)

	TeleportService:TeleportPartyAsync(GAME_PLACE_ID, players, teleportData)
end)

Players.PlayerRemoving:Connect(function(player)
	leaveAllRooms(player)
end)
