local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ANIMATION_ID = "rbxassetid://100993945872309"

local player = Players.LocalPlayer
local originalDummy = Workspace:WaitForChild("Dummy")
local dummyPivot = originalDummy:GetPivot()

local function waitForAppearance(character)
	if player:HasAppearanceLoaded() then
		return
	end

	local loaded = false
	local connection = player.CharacterAppearanceLoaded:Connect(function(loadedCharacter)
		if loadedCharacter == character then
			loaded = true
		end
	end)

	local startedAt = os.clock()
	while not loaded and not player:HasAppearanceLoaded() and os.clock() - startedAt < 10 do
		task.wait()
	end

	connection:Disconnect()
end

local function cloneCharacter(character)
	local oldArchivable = character.Archivable
	character.Archivable = true
	local clone = character:Clone()
	character.Archivable = oldArchivable
	return clone
end

local function cleanClone(clone)
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
		end
	end

	local humanoidRootPart = clone:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		humanoidRootPart.Anchored = true
	end
end

local function playAnimation(humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local animation = Instance.new("Animation")
	animation.AnimationId = ANIMATION_ID

	local track = animator:LoadAnimation(animation)
	track.Looped = true
	track:Play()
end

local function hideHumanoidDisplay(humanoid)
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.NameDisplayDistance = 0
	humanoid.HealthDisplayDistance = 0
end

local character = player.Character or player.CharacterAdded:Wait()
character:WaitForChild("Humanoid")
character:WaitForChild("HumanoidRootPart")
waitForAppearance(character)

local dummyClone = cloneCharacter(character)
dummyClone.Name = "Dummy"
cleanClone(dummyClone)
dummyClone.Parent = Workspace
dummyClone:PivotTo(dummyPivot)

originalDummy:Destroy()
local dummyHumanoid = dummyClone:WaitForChild("Humanoid")
hideHumanoidDisplay(dummyHumanoid)
playAnimation(dummyHumanoid)
