local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui")
local menu = mainGui:WaitForChild("Menu")
local title = menu:WaitForChild("Title")
local buttons = menu:WaitForChild("Buttons")
local playButton = buttons:WaitForChild("1Play")
local shopButton = buttons:WaitForChild("2Shop")
shopButton.Text = "Shop"
local shopPanel = mainGui:WaitForChild("Shop")
local shopBack = shopPanel:WaitForChild("Back")
shopPanel.Visible = false
local menuButtons = { playButton, shopButton }
local menuButtonResetters = {}
local menuClosing = false
local playPanelClosing = false
local CLICK_SCALE_DOWN_TIME = 0.06
local CLICK_SCALE_UP_TIME = 0.08
local CLICK_FADE_PROGRESS = 0.7

if player.Name == "TildStudio" then
	local debugFillRoomEvent = ReplicatedStorage:WaitForChild("DebugFillRoomEvent")
	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if not gameProcessedEvent and input.KeyCode == Enum.KeyCode.F then
			debugFillRoomEvent:FireServer()
		end
	end)
end

local gradient = title:FindFirstChild("TitleShimmer")
if not gradient then
	gradient = Instance.new("UIGradient")
	gradient.Name = "TitleShimmer"
	gradient.Parent = title
end

gradient.Rotation = 0
gradient.Offset = Vector2.new(-1, 0)
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 197, 66)),
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 231, 128)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 231, 128)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 197, 66)),
})

TweenService:Create(
	gradient,
	TweenInfo.new(1.4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
	{ Offset = Vector2.new(1, 0) }
):Play()

local basePosition = title.Position
title.Position = basePosition + UDim2.fromOffset(0, -5)

TweenService:Create(
	title,
	TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Position = basePosition + UDim2.fromOffset(0, 5) }
):Play()

local function setMenuInteractable(isInteractable)
	for _, button in menuButtons do
		button.Interactable = isInteractable
	end
end

local function setMenuTextTransparency(transparency)
	TweenService:Create(
		title,
		TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ TextTransparency = transparency }
	):Play()

	for _, button in menuButtons do
		TweenService:Create(
			button,
			TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ TextTransparency = transparency }
		):Play()
	end
end

local function resetMenuButtons()
	for _, resetButton in menuButtonResetters do
		resetButton()
	end
end

local function tween(instance, properties, duration)
	local tweenObject = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		properties
	)
	tweenObject:Play()
	return tweenObject
end

local function revealPlayPanel()
	local playPanel = mainGui:WaitForChild("Play")
	local frame = playPanel:WaitForChild("Frame")
	local frameStroke = frame:WaitForChild("UIStroke")
	local scrollingFrame = frame:WaitForChild("ScrollingFrame")
	local alertDeco = frame:WaitForChild("AlertDeco")
	local alert = frame:WaitForChild("Alert")
	local createRoom = playPanel:WaitForChild("CreateRoom")
	local createRoomStroke = createRoom:WaitForChild("UIStroke")
	local back = playPanel:WaitForChild("Back")
	local backStroke = back:WaitForChild("UIStroke")

	tween(frame, { BackgroundTransparency = 0.85 })
	tween(frameStroke, { Transparency = 0.61 })
	tween(scrollingFrame, { ScrollBarImageTransparency = 0 })
	tween(createRoom, { BackgroundTransparency = 0, TextTransparency = 0 })
	tween(createRoomStroke, { Transparency = 0.61 })
	tween(back, { BackgroundTransparency = 0, TextTransparency = 0 })
	tween(backStroke, { Transparency = 0.61 })
	createRoom.Interactable = true
	back.Interactable = true

	if alertDeco.Visible then
		tween(alertDeco, { TextTransparency = 0 })
	end

	if alert.Visible then
		tween(alert, { TextTransparency = 0 })
	end
end

local function hidePlayPanel()
	local playPanel = mainGui:WaitForChild("Play")
	local frame = playPanel:WaitForChild("Frame")
	local frameStroke = frame:WaitForChild("UIStroke")
	local scrollingFrame = frame:WaitForChild("ScrollingFrame")
	local alertDeco = frame:WaitForChild("AlertDeco")
	local alert = frame:WaitForChild("Alert")
	local createRoom = playPanel:WaitForChild("CreateRoom")
	local createRoomStroke = createRoom:WaitForChild("UIStroke")
	local back = playPanel:WaitForChild("Back")
	local backStroke = back:WaitForChild("UIStroke")

	tween(frame, { BackgroundTransparency = 1 })
	tween(frameStroke, { Transparency = 1 })
	tween(scrollingFrame, { ScrollBarImageTransparency = 1 })
	tween(createRoom, { BackgroundTransparency = 1, TextTransparency = 1 })
	tween(createRoomStroke, { Transparency = 1 })
	tween(back, { BackgroundTransparency = 1, TextTransparency = 1 })
	tween(backStroke, { Transparency = 1 })
	createRoom.Interactable = false
	back.Interactable = false
	tween(alertDeco, { TextTransparency = 1 })
	tween(alert, { TextTransparency = 1 })
end

local createRoomPanel = mainGui:WaitForChild("CreateRoom")
local createRoomSetting = createRoomPanel:WaitForChild("Setting")
local createRoomBack = createRoomPanel:WaitForChild("Back")
local createRoomBackStroke = createRoomBack:FindFirstChild("UIStroke")
local createRoomCreate = createRoomSetting:WaitForChild("Create")
local createRoomPassword = createRoomSetting:WaitForChild("Password")
local createRoomPasswordLabel = createRoomPassword:WaitForChild("TextLabel")
local createRoomPasswordTextBox = createRoomPassword:WaitForChild("TextBox")
local createRoomVoiceOnly = createRoomSetting:WaitForChild("VoiceOnly")
local createRoomVoiceOnlyLabel = createRoomVoiceOnly:WaitForChild("TextLabel")
local uiObjects = ReplicatedStorage:WaitForChild("UIObjects")
local roomsFolder = ReplicatedStorage:WaitForChild("Rooms")
local createRoomFunction = ReplicatedStorage:WaitForChild("CreateRoomFunction")
local joinRoomFunction = ReplicatedStorage:WaitForChild("JoinRoomFunction")
local leaveRoomEvent = ReplicatedStorage:WaitForChild("LeaveRoomEvent")
local startRoomEvent = ReplicatedStorage:WaitForChild("StartRoomEvent")
local createRoomSettings = {}
local openDropDown
local closeDropDown
local DROPDOWN_SCALE_TIME = 0.08
local legacyModeDropDown = createRoomSetting:FindFirstChild("ModeDropDown")
if legacyModeDropDown and not createRoomSetting:FindFirstChild("SpeedDropdown") then
	legacyModeDropDown.Name = "SpeedDropdown"
end
local dropDownConfigs = {
	{
		name = "CapacityDropDown",
		attribute = "CreateRoomCapacity",
		default = "3Person",
		buttons = {
			{ name = "3Person", text = "3 Person" },
			{ name = "4Person", text = "4 Person" },
			{ name = "5Person", text = "5 Person" },
			{ name = "6Person", text = "6 Person" },
		},
	},
	{
		name = "SpeedDropdown",
		attribute = "CreateRoomSpeed",
		default = "2Normal",
		buttons = {
			{ name = "1Slow", text = "Slow" },
			{ name = "2Normal", text = "Normal" },
			{ name = "3Fast", text = "Fast" },
		},
	},
	{
		name = "RoundDropDown",
		attribute = "CreateRoomRound",
		buttons = {
			{ name = "3Round", text = "3 Round" },
			{ name = "5Round", text = "5 Round" },
			{ name = "7Round", text = "7 Round" },
			{ name = "9Round", text = "9 Round" },
		},
	},
	{
		name = "ThemeDropDown",
		attribute = "CreateRoomTheme",
		default = "1Roblox",
		buttons = {
			{ name = "1Roblox", text = "Roblox" },
		},
	},
}

local function setZIndexRecursive(instance, zIndex)
	if instance:IsA("GuiObject") then
		instance.ZIndex = zIndex
	end

	for _, child in instance:GetChildren() do
		setZIndexRecursive(child, zIndex)
	end
end

local function isDropDownInnerContent(instance)
	for _, config in dropDownConfigs do
		local dropDown = createRoomSetting:FindFirstChild(config.name)
		local frame = dropDown and dropDown:FindFirstChild("Frame")
		if frame and instance:IsDescendantOf(frame) then
			return true
		end
	end

	return false
end

local function setCreateRoomOuterTransparency(transparency)
	createRoomSetting.BackgroundTransparency = transparency
	createRoomBack.BackgroundTransparency = transparency
	createRoomBack.TextTransparency = transparency
	createRoomBack.Interactable = transparency < 1
	createRoomCreate.BackgroundTransparency = transparency
	createRoomCreate.TextTransparency = transparency
	createRoomCreate.Interactable = transparency < 1
	createRoomPassword.BackgroundTransparency = transparency
	createRoomVoiceOnly.BackgroundTransparency = transparency

	if createRoomBackStroke then
		createRoomBackStroke.Transparency = transparency
	end

	for _, instance in createRoomSetting:GetDescendants() do
		if not isDropDownInnerContent(instance) then
			if instance:IsA("GuiButton") then
				instance.Interactable = transparency < 1
			end

			if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
				instance.TextTransparency = transparency
			end

			if instance:IsA("TextBox") then
				instance.BackgroundTransparency = transparency
			elseif instance:IsA("GuiObject") and instance.Name:lower():find("dropdown") then
				instance.BackgroundTransparency = transparency
			elseif instance:IsA("Frame") and instance.Name == "Setting" then
				instance.BackgroundTransparency = transparency
			end
		end
	end
end

local function revealCreateRoomPanel()
	createRoomPanel.Visible = true
	createRoomBack.Interactable = true
	createRoomCreate.Interactable = true

	for _, instance in createRoomSetting:GetDescendants() do
		if not isDropDownInnerContent(instance) then
			if instance:IsA("GuiButton") then
				instance.Interactable = true
			end

			if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
				tween(instance, { TextTransparency = 0 })
			end

			if instance:IsA("TextBox") then
				tween(instance, { BackgroundTransparency = 0 })
			elseif instance:IsA("GuiObject") and instance.Name:lower():find("dropdown") then
				tween(instance, { BackgroundTransparency = 0 })
			end
		end
	end

	tween(createRoomSetting, { BackgroundTransparency = 0.65 })
	tween(createRoomBack, { BackgroundTransparency = 0, TextTransparency = 0 })
	tween(createRoomCreate, { BackgroundTransparency = 0, TextTransparency = 0 })
	tween(createRoomPassword, { BackgroundTransparency = 0 })
	tween(createRoomVoiceOnly, { BackgroundTransparency = 0 })

	if createRoomBackStroke then
		tween(createRoomBackStroke, { Transparency = 0.61 })
	end
end

local function hideCreateRoomPanel()
	if openDropDown then
		closeDropDown(openDropDown)
	end

	createRoomBack.Interactable = false
	createRoomCreate.Interactable = false

	for _, instance in createRoomSetting:GetDescendants() do
		if not isDropDownInnerContent(instance) then
			if instance:IsA("GuiButton") then
				instance.Interactable = false
			end

			if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
				tween(instance, { TextTransparency = 1 })
			end

			if instance:IsA("TextBox") then
				tween(instance, { BackgroundTransparency = 1 })
			elseif instance:IsA("GuiObject") and instance.Name:lower():find("dropdown") then
				tween(instance, { BackgroundTransparency = 1 })
			end
		end
	end

	tween(createRoomSetting, { BackgroundTransparency = 1 })
	tween(createRoomBack, { BackgroundTransparency = 1, TextTransparency = 1 })
	tween(createRoomCreate, { BackgroundTransparency = 1, TextTransparency = 1 })
	tween(createRoomPassword, { BackgroundTransparency = 1 })
	tween(createRoomVoiceOnly, { BackgroundTransparency = 1 })

	if createRoomBackStroke then
		tween(createRoomBackStroke, { Transparency = 1 })
	end
end

function closeDropDown(dropDown)
	if not dropDown then
		return
	end

	local frame = dropDown:WaitForChild("Frame")
	local scale = frame:WaitForChild("UIScale")
	local arrow = dropDown:WaitForChild("Arrow")

	if openDropDown == dropDown then
		openDropDown = nil
	end

	arrow.Rotation = 90
	tween(scale, { Scale = 0 }, DROPDOWN_SCALE_TIME).Completed:Connect(function()
		if openDropDown ~= dropDown then
			setZIndexRecursive(dropDown, 1)
		end
	end)
end

local function openDropDownMenu(dropDown)
	if openDropDown and openDropDown ~= dropDown then
		closeDropDown(openDropDown)
	end

	openDropDown = dropDown
	setZIndexRecursive(dropDown, 2)
	dropDown:WaitForChild("Arrow").Rotation = -90
	tween(dropDown:WaitForChild("Frame"):WaitForChild("UIScale"), { Scale = 1 }, DROPDOWN_SCALE_TIME)
end

local dropDownButtonTemplate = uiObjects:WaitForChild("DropDown")
local roomTemplate = uiObjects:WaitForChild("Room")
local memberTemplate = uiObjects:WaitForChild("Member")
local roomList = mainGui:WaitForChild("Play"):WaitForChild("Frame"):WaitForChild("ScrollingFrame")
local roomPanel = mainGui:WaitForChild("Room")
local roomFrame = roomPanel:WaitForChild("Frame")
local roomStart = roomFrame:WaitForChild("Start")
local roomStartFrame = roomStart:FindFirstChild("Frame")
local roomDesc = roomFrame:FindFirstChild("Desc")
local roomBack = roomPanel:WaitForChild("Back")
local memberParent = roomFrame:WaitForChild("MemberParent")
local roomCards = {}
local roomCardsTransparency = 1
local currentRoom
local roomConnections = {}
local tweenRoomCardsTransparency
roomPanel.Visible = false

local function clearDropDownButtons(frame)
	for _, child in frame:GetChildren() do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end
end

local function createDropDownButton(frame, option, layoutOrder, optionCount)
	local button = dropDownButtonTemplate:Clone()
	button.Name = option.name
	button.LayoutOrder = layoutOrder
	button.Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, 1 / optionCount, button.Size.Y.Offset)
	button.Visible = true
	button.Parent = frame

	local label = button:FindFirstChildWhichIsA("TextLabel", true)
	if label then
		label.Text = option.text
	end

	return button
end

local function getDefaultOption(config)
	for _, option in config.buttons do
		if option.name == config.default then
			return option
		end
	end

	return config.buttons[1]
end

local function setupDropDown(config)
	local dropDown = createRoomSetting:WaitForChild(config.name)
	local frame = dropDown:WaitForChild("Frame")
	local scale = frame:WaitForChild("UIScale")
	local current = dropDown:WaitForChild("Current")
	local arrow = dropDown:WaitForChild("Arrow")

	clearDropDownButtons(frame)
	frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, #config.buttons, frame.Size.Y.Offset)
	scale.Scale = 0
	arrow.Rotation = 90
	setZIndexRecursive(dropDown, 1)

	local defaultOption = getDefaultOption(config)
	local currentText = current.Text
	if defaultOption and (config.default or currentText == "") then
		currentText = defaultOption.text
		current.Text = currentText
	end

	if currentText ~= "" then
		createRoomSettings[config.attribute] = currentText
		player:SetAttribute(config.attribute, currentText)
	end

	dropDown.Activated:Connect(function()
		if openDropDown == dropDown then
			closeDropDown(dropDown)
		else
			openDropDownMenu(dropDown)
		end
	end)

	for index, option in config.buttons do
		local button = createDropDownButton(frame, option, index, #config.buttons)
		button.Activated:Connect(function()
			local value = option.text
			createRoomSettings[config.attribute] = value
			player:SetAttribute(config.attribute, value)
			current.Text = value
			print(config.attribute, value)
			closeDropDown(dropDown)
		end)
	end
end

for _, config in dropDownConfigs do
	setupDropDown(config)
end

setCreateRoomOuterTransparency(1)

createRoomSettings.CreateRoomPasswordEnabled = false
createRoomSettings.CreateRoomPassword = ""
createRoomSettings.CreateRoomVoiceOnly = false
createRoomPasswordLabel.Text = "X"
createRoomPasswordTextBox.Visible = false
createRoomVoiceOnlyLabel.Text = "X"

createRoomPassword.Activated:Connect(function()
	local isEnabled = not createRoomSettings.CreateRoomPasswordEnabled
	createRoomSettings.CreateRoomPasswordEnabled = isEnabled
	createRoomPasswordLabel.Text = if isEnabled then "O" else "X"
	createRoomPasswordTextBox.Visible = isEnabled
end)

createRoomPasswordTextBox:GetPropertyChangedSignal("Text"):Connect(function()
	createRoomSettings.CreateRoomPassword = createRoomPasswordTextBox.Text
end)

createRoomVoiceOnly.Activated:Connect(function()
	local isEnabled = not createRoomSettings.CreateRoomVoiceOnly
	createRoomSettings.CreateRoomVoiceOnly = isEnabled
	createRoomVoiceOnlyLabel.Text = if isEnabled then "O" else "X"
end)

local function setText(instance, childName, text)
	local label = instance:FindFirstChild(childName, true)
	if label and (label:IsA("TextLabel") or label:IsA("TextButton")) then
		label.Text = text
	end
end

local function getRoomSetup(room)
	local round = room:GetAttribute("Round") or "3 Round"
	local theme = room:GetAttribute("Theme") or "Roblox"
	local speed = room:GetAttribute("Speed") or "Normal"
	local voiceOnly = if room:GetAttribute("VoiceOnly") then ", Voice Only" else ""

	return `{round}, {theme} Theme, {speed} Speed{voiceOnly}`
end

local function updateRoomCard(room, card)
	setText(card, "RoomName", room:GetAttribute("RoomName") or "Room")
	setText(card, "Setup", getRoomSetup(room))
	setText(card, "Count", `{room:GetAttribute("CurrentPlayers") or 0}/{room:GetAttribute("Capacity") or 0}`)

	local locked = card:FindFirstChild("Locked", true)
	if locked and locked:IsA("GuiObject") then
		locked.Visible = room:GetAttribute("PasswordEnabled") == true
	end
end

local function clearRoomConnections()
	for _, connection in roomConnections do
		connection:Disconnect()
	end

	table.clear(roomConnections)
end

local function clearMemberCards()
	for _, child in memberParent:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function renderMember(member)
	local card = memberTemplate:Clone()
	card.Name = member.Name
	card.LayoutOrder = member:GetAttribute("IsOwner") and 0 or 1
	card.Visible = true
	card.Parent = memberParent
	setText(card, "TextLabel", member:GetAttribute("Name") or "Player")

	local owner = card:FindFirstChild("Owner", true)
	if owner and owner:IsA("GuiObject") then
		owner.Visible = member:GetAttribute("IsOwner") == true
	end

	local icon = card:FindFirstChild("Icon", true)
	local userId = member:GetAttribute("UserId")
	if icon and icon:IsA("ImageLabel") and userId then
		icon.Image = `rbxthumb://type=AvatarHeadShot&id={userId}&w=150&h=150`
	end
end

local function renderMembers(room)
	clearMemberCards()

	local members = room:FindFirstChild("Members")
	if not members then
		return
	end

	for _, member in members:GetChildren() do
		renderMember(member)
	end
end

local function getRoomStartReady(room)
	return room:GetAttribute("OwnerUserId") == player.UserId and (room:GetAttribute("CurrentPlayers") or 0) >= 3
end

local function setRoomStartTransparency(room, panelTransparency)
	local ready = room and getRoomStartReady(room)
	local transparency = if panelTransparency >= 1 then 1 else 0
	roomStart.Visible = true
	roomStart.BackgroundTransparency = transparency
	roomStart.TextTransparency = transparency
	roomStart.Interactable = panelTransparency < 1 and ready

	if roomStartFrame then
		roomStartFrame.BackgroundTransparency = if panelTransparency >= 1 then 1 elseif ready then 1 else 0.32
	end
end

local function tweenRoomStartTransparency(room, panelTransparency)
	local ready = room and getRoomStartReady(room)
	local transparency = if panelTransparency >= 1 then 1 else 0
	roomStart.Visible = true
	roomStart.Interactable = panelTransparency < 1 and ready
	tween(roomStart, {
		BackgroundTransparency = transparency,
		TextTransparency = transparency,
	})

	if roomStartFrame then
		tween(roomStartFrame, { BackgroundTransparency = if panelTransparency >= 1 then 1 elseif ready then 1 else 0.32 })
	end
end

local function getRoomDescHidden(room)
	return room and (room:GetAttribute("CurrentPlayers") or 0) >= 3
end

local function setRoomDescTransparency(room, panelTransparency)
	if roomDesc then
		roomDesc.TextTransparency = if panelTransparency >= 1 or getRoomDescHidden(room) then 1 else 0
	end
end

local function tweenRoomDescTransparency(room, panelTransparency)
	if roomDesc then
		tween(roomDesc, { TextTransparency = if panelTransparency >= 1 or getRoomDescHidden(room) then 1 else 0 })
	end
end

local function setRoomPanelTransparency(transparency)
	roomFrame.BackgroundTransparency = if transparency >= 1 then 1 else 0.65
	roomBack.BackgroundTransparency = transparency

	for _, instance in roomPanel:GetDescendants() do
		if instance ~= roomStart and instance ~= roomDesc and (instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")) then
			instance.TextTransparency = transparency
		elseif instance:IsA("UIStroke") then
			instance.Transparency = transparency
		end
	end

	local icon = roomFrame:FindFirstChild("Icon")
	if icon and icon:IsA("ImageLabel") then
		icon.BackgroundTransparency = transparency
		icon.ImageTransparency = transparency

		local stroke = icon:FindFirstChild("UIStroke")
		if stroke then
			stroke.Transparency = transparency
		end
	end

	setRoomStartTransparency(currentRoom, transparency)
	setRoomDescTransparency(currentRoom, transparency)
end

local function tweenRoomPanelTransparency(transparency)
	tween(roomFrame, { BackgroundTransparency = if transparency >= 1 then 1 else 0.65 })
	tween(roomBack, { BackgroundTransparency = transparency })

	for _, instance in roomPanel:GetDescendants() do
		if instance:IsA("GuiButton") then
			instance.Interactable = transparency < 1
		end

		if instance ~= roomStart and instance ~= roomDesc and (instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")) then
			tween(instance, { TextTransparency = transparency })
		elseif instance:IsA("UIStroke") then
			tween(instance, { Transparency = transparency })
		end
	end

	roomBack.Interactable = transparency < 1

	local icon = roomFrame:FindFirstChild("Icon")
	if icon and icon:IsA("ImageLabel") then
		tween(icon, {
			BackgroundTransparency = transparency,
			ImageTransparency = transparency,
		})

		local stroke = icon:FindFirstChild("UIStroke")
		if stroke then
			tween(stroke, { Transparency = transparency })
		end
	end

	tweenRoomStartTransparency(currentRoom, transparency)
	tweenRoomDescTransparency(currentRoom, transparency)
end

local function updateRoomPanel(room)
	setText(roomPanel, "RoomName", room:GetAttribute("RoomName") or "Room")
	setText(roomPanel, "Setup", getRoomSetup(room))
	setText(roomPanel, "Count", `{room:GetAttribute("CurrentPlayers") or 0}/{room:GetAttribute("Capacity") or 0}`)
	setText(roomPanel, "Password", if room:GetAttribute("PasswordEnabled") then room:GetAttribute("Password") or "" else "")
	tweenRoomStartTransparency(room, 0)
	tweenRoomDescTransparency(room, 0)

	local locked = roomPanel:FindFirstChild("Locked", true)
	if locked and locked:IsA("GuiObject") then
		locked.Visible = room:GetAttribute("PasswordEnabled") == true
	end

	renderMembers(room)
end

local function hideRoomPanel()
	clearRoomConnections()
	clearMemberCards()
	tweenRoomPanelTransparency(1)
	roomBack.Interactable = false
	currentRoom = nil
	task.delay(0.25, function()
		if not currentRoom then
			roomPanel.Visible = false
		end
	end)
end

local function showRoomPanel(room)
	currentRoom = room
	setRoomPanelTransparency(1)
	roomPanel.Visible = true
	roomBack.Interactable = true
	hidePlayPanel()
	tweenRoomCardsTransparency(1)
	updateRoomPanel(room)
	tweenRoomPanelTransparency(0)
	clearRoomConnections()

	table.insert(roomConnections, room.AttributeChanged:Connect(function()
		updateRoomPanel(room)
	end))

	local members = room:WaitForChild("Members")
	table.insert(roomConnections, members.ChildAdded:Connect(function(member)
		renderMembers(room)
		table.insert(roomConnections, member.AttributeChanged:Connect(function()
			renderMembers(room)
		end))
	end))
	table.insert(roomConnections, members.ChildRemoved:Connect(function()
		renderMembers(room)
	end))

	for _, member in members:GetChildren() do
		table.insert(roomConnections, member.AttributeChanged:Connect(function()
			renderMembers(room)
		end))
	end
end

local function tweenStoredTransparency(instance, propertyName, transparency)
	local attributeName = "RoomBase" .. propertyName
	local baseTransparency = instance:GetAttribute(attributeName)
	if baseTransparency == nil then
		baseTransparency = instance[propertyName]
		instance:SetAttribute(attributeName, baseTransparency)
	end

	local properties = {}
	properties[propertyName] = if transparency >= 1 then 1 else baseTransparency
	tween(instance, properties)
end

local function setStoredTransparency(instance, propertyName, transparency)
	local attributeName = "RoomBase" .. propertyName
	local baseTransparency = instance:GetAttribute(attributeName)
	if baseTransparency == nil then
		baseTransparency = instance[propertyName]
		instance:SetAttribute(attributeName, baseTransparency)
	end

	instance[propertyName] = if transparency >= 1 then 1 else baseTransparency
end

local function tweenRoomCardTransparency(card, transparency)
	local function apply(instance)
		if instance:IsA("GuiButton") then
			instance.Interactable = transparency < 1
		end

		if instance:IsA("GuiObject") then
			tweenStoredTransparency(instance, "BackgroundTransparency", transparency)
		end

		if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
			tweenStoredTransparency(instance, "TextTransparency", transparency)
		elseif instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
			tweenStoredTransparency(instance, "ImageTransparency", transparency)
		elseif instance:IsA("UIStroke") then
			tweenStoredTransparency(instance, "Transparency", transparency)
		end
	end

	apply(card)
	for _, instance in card:GetDescendants() do
		apply(instance)
	end
end

local function setRoomCardTransparency(card, transparency)
	local function apply(instance)
		if instance:IsA("GuiButton") then
			instance.Interactable = transparency < 1
		end

		if instance:IsA("GuiObject") then
			setStoredTransparency(instance, "BackgroundTransparency", transparency)
		end

		if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
			setStoredTransparency(instance, "TextTransparency", transparency)
		elseif instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
			setStoredTransparency(instance, "ImageTransparency", transparency)
		elseif instance:IsA("UIStroke") then
			setStoredTransparency(instance, "Transparency", transparency)
		end
	end

	apply(card)
	for _, instance in card:GetDescendants() do
		apply(instance)
	end
end

function tweenRoomCardsTransparency(transparency)
	roomCardsTransparency = transparency

	for _, card in roomCards do
		tweenRoomCardTransparency(card, transparency)
	end
end

local function renderRoom(room)
	if roomCards[room] then
		updateRoomCard(room, roomCards[room])
		return
	end

	local card = roomTemplate:Clone()
	card.Name = room.Name
	card.LayoutOrder = room:GetAttribute("CreatedOrder") or #roomList:GetChildren()
	card.Visible = true
	setRoomCardTransparency(card, roomCardsTransparency)
	card.Parent = roomList
	roomCards[room] = card
	updateRoomCard(room, card)

	if card:IsA("GuiButton") then
		card.Activated:Connect(function()
			local roomName = joinRoomFunction:InvokeServer(room.Name)
			local joinedRoom = roomName and roomsFolder:FindFirstChild(roomName)
			if joinedRoom then
				showRoomPanel(joinedRoom)
			end
		end)
	end

	room.AttributeChanged:Connect(function()
		if roomCards[room] then
			updateRoomCard(room, roomCards[room])
		end
	end)
end

local function removeRoom(room)
	local card = roomCards[room]
	if card then
		card:Destroy()
		roomCards[room] = nil
	end
end

for _, room in roomsFolder:GetChildren() do
	renderRoom(room)
end

roomsFolder.ChildAdded:Connect(renderRoom)
roomsFolder.ChildRemoved:Connect(function(room)
	removeRoom(room)

	if currentRoom == room then
		hideRoomPanel()
		revealPlayPanel()
		tweenRoomCardsTransparency(0)
	end
end)

local function addButtonEffects(button, hoverText, printText, onActivated)
	local normalText = button.Text
	local scale = button:WaitForChild("UIScale")
	local activeScaleTween

	local function tweenScale(targetScale, duration)
		if activeScaleTween then
			activeScaleTween:Cancel()
		end

		activeScaleTween = TweenService:Create(
			scale,
			TweenInfo.new(duration or 0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Scale = targetScale }
		)
		activeScaleTween:Play()
		return activeScaleTween
	end

	table.insert(menuButtonResetters, function()
		button.Text = normalText
		tweenScale(1)
	end)

	button.MouseEnter:Connect(function()
		if menuClosing then
			return
		end

		button.Text = hoverText
		tweenScale(1.2)
	end)

	button.MouseLeave:Connect(function()
		if menuClosing then
			return
		end

		button.Text = normalText
		tweenScale(1)
	end)

	button.Activated:Connect(function()
		if menuClosing then
			return
		end

		menuClosing = true
		button.Text = hoverText
		setMenuInteractable(false)

		local activated = false
		local function activate()
			if activated then
				return
			end

			activated = true
			setMenuTextTransparency(1)
			if onActivated then
				onActivated()
			end
			print(printText)
		end

		task.delay((CLICK_SCALE_DOWN_TIME + CLICK_SCALE_UP_TIME) * CLICK_FADE_PROGRESS, activate)
		tweenScale(0.8, CLICK_SCALE_DOWN_TIME).Completed:Wait()
		tweenScale(1.2, CLICK_SCALE_UP_TIME).Completed:Wait()
		activate()
	end)
end

addButtonEffects(playButton, "> Play", "Play", function()
	revealPlayPanel()
	tweenRoomCardsTransparency(0)
end)
addButtonEffects(shopButton, "> Shop", "Shop", function()
	shopPanel.Visible = true
end)

shopBack.Activated:Connect(function()
	shopPanel.Visible = false
	resetMenuButtons()
	setMenuTextTransparency(0)
	setMenuInteractable(true)
	menuClosing = false
end)

mainGui:WaitForChild("Play"):WaitForChild("CreateRoom").Activated:Connect(function()
	tweenRoomCardsTransparency(1)
	hidePlayPanel()
	revealCreateRoomPanel()
end)

createRoomBack.Activated:Connect(function()
	hideCreateRoomPanel()
	revealPlayPanel()
	tweenRoomCardsTransparency(0)
end)

createRoomCreate.Activated:Connect(function()
	createRoomSettings.CreateRoomPassword = createRoomPasswordTextBox.Text
	local roomName = createRoomFunction:InvokeServer(createRoomSettings)
	local room = roomName and roomsFolder:WaitForChild(roomName, 5)
	hideCreateRoomPanel()

	if room then
		showRoomPanel(room)
	else
		revealPlayPanel()
		tweenRoomCardsTransparency(0)
	end
end)

roomBack.Activated:Connect(function()
	if currentRoom then
		leaveRoomEvent:FireServer(currentRoom.Name)
	end

	hideRoomPanel()
	revealPlayPanel()
	tweenRoomCardsTransparency(0)
end)

roomStart.Activated:Connect(function()
	if currentRoom then
		startRoomEvent:FireServer(currentRoom.Name)
	end
end)

mainGui:WaitForChild("Play"):WaitForChild("Back").Activated:Connect(function()
	if playPanelClosing then
		return
	end

	playPanelClosing = true
	tweenRoomCardsTransparency(1)
	hidePlayPanel()
	resetMenuButtons()
	setMenuTextTransparency(0)
	setMenuInteractable(true)
	menuClosing = false
	task.delay(0.25, function()
		playPanelClosing = false
	end)
end)
