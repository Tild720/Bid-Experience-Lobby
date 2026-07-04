local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CAMERA_POSITION = Vector3.new(47.48, 12.907, -98.295)
local CAMERA_ORIENTATION = Vector3.new(28, -141.069, 0)
local CAMERA_FOV = 50

local function lockCamera()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = CAMERA_FOV
	camera.CFrame = CFrame.new(CAMERA_POSITION) * CFrame.Angles(
		math.rad(CAMERA_ORIENTATION.X),
		math.rad(CAMERA_ORIENTATION.Y),
		math.rad(CAMERA_ORIENTATION.Z)
	)
end

lockCamera()
RunService.RenderStepped:Connect(lockCamera)
 