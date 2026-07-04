local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local item = Workspace:WaitForChild("Item")
local spinTween = TweenService:Create(
	item,
	TweenInfo.new(18, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
	{ Orientation = item.Orientation + Vector3.new(0, 360, 0) }
)

spinTween:Play()
