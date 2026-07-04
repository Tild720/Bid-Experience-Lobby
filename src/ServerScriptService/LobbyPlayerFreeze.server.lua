local Players = game:GetService("Players")

local function freezeCharacter(character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid.WalkSpeed = 0
	end
end

local function freezePlayer(player)
	player.CharacterAdded:Connect(freezeCharacter)

	if player.Character then
		freezeCharacter(player.Character)
	end
end

Players.PlayerAdded:Connect(freezePlayer)

for _, player in Players:GetPlayers() do
	freezePlayer(player)
end
