local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local statsStore = DataStoreService:GetDataStore("BidShowPlayerStatsV1")

local function setupPlayer(player)
	if player:FindFirstChild("leaderstats") then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local wins = Instance.new("IntValue")
	wins.Name = "Win"
	wins.Parent = leaderstats

	local points = Instance.new("IntValue")
	points.Name = "Points"
	points.Parent = leaderstats

	leaderstats.Parent = player

	local success, data
	for attempt = 1, 3 do
		success, data = pcall(function()
			return statsStore:GetAsync(`player_{player.UserId}`)
		end)
		if success or not player.Parent then
			break
		end
		if attempt < 3 then
			task.wait(attempt)
		end
	end

	if success and typeof(data) == "table" and player.Parent then
		wins.Value = math.max(0, tonumber(data.Wins) or 0)
		points.Value = math.max(0, tonumber(data.Points) or 0)
	elseif not success then
		warn("[LobbyStats] Failed to load", player.Name, data)
	end
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end
