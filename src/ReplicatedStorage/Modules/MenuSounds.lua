local SoundService = game:GetService("SoundService")

return function(mainGui)
	local sounds = {
		FadeTransitionOnce = SoundService:FindFirstChild("FadeTransitionOnce"),
		BGM = SoundService:FindFirstChild("BGM"),
		JoinRoom = SoundService:FindFirstChild("JoinRoom"),
		Purchase = SoundService:FindFirstChild("Purchase"),
		Click = SoundService:FindFirstChild("Click"),
		GameStartAndCreateRoom = SoundService:FindFirstChild("GameStartAndCreateRoom"),
	}

	local function playNamedSound(soundName)
		local sound = sounds[soundName]
		if not sound or not sound:IsA("Sound") then
			return
		end

		sound.TimePosition = 0
		sound:Play()
	end

	local bgm = sounds.BGM
	if bgm and bgm:IsA("Sound") then
		bgm.Looped = true
		if not bgm.Playing then
			bgm:Play()
		end
	end

	local clickSoundBound = setmetatable({}, { __mode = "k" })
	local function bindClickSound(instance)
		if not instance:IsA("GuiButton") or instance.Name == "AddSoon" or clickSoundBound[instance] then
			return
		end

		clickSoundBound[instance] = true
		instance.Activated:Connect(function()
			playNamedSound("Click")
		end)
	end

	for _, instance in mainGui:GetDescendants() do
		bindClickSound(instance)
	end
	mainGui.DescendantAdded:Connect(bindClickSound)

	return playNamedSound
end
