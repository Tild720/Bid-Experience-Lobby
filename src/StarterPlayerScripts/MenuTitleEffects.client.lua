local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
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
local shopFrame = shopPanel:WaitForChild("Frame")
local shopScale = shopFrame:WaitForChild("UIScale")
local signSkin = shopFrame:WaitForChild("SignSkin")
local trail = shopFrame:WaitForChild("Trail")
local addSoon = shopFrame:WaitForChild("AddSoon")
local shopContainer = shopFrame:WaitForChild("Container")
local shopAlert = shopFrame:WaitForChild("Alert")
local shopAlertStroke = shopAlert:WaitForChild("UIStroke")
local plusMoney = shopFrame:WaitForChild("PlusMoney")
local moneyLabel = shopFrame:WaitForChild("Money")
local moneyShopDeco = shopFrame:WaitForChild("Deco")
local moneyProductButtons = {
	{ button = shopFrame:WaitForChild("2000P"), productId = 3611489162 },
	{ button = shopFrame:WaitForChild("7000P"), productId = 3611489310 },
	{ button = shopFrame:WaitForChild("20000P"), productId = 3611489343 },
}
local modules = ReplicatedStorage:WaitForChild("Modules")
local signSkinConfig = require(modules:WaitForChild("SignSkinConfig"))
local trailConfig = require(modules:WaitForChild("TrailConfig"))
local signSkinsFolder = ReplicatedStorage:WaitForChild("SignSkins")
local trailFolder = ReplicatedStorage:WaitForChild("Trail")
local purchaseFunction = ReplicatedStorage:WaitForChild("ShopPurchaseFunction")
local purchaseAlert = ReplicatedStorage:WaitForChild("ShopPurchaseAlert")
local uiObjects = ReplicatedStorage:WaitForChild("UIObjects")
local skinButtonTemplate = uiObjects:WaitForChild("SkinButton")
local trailButtonTemplate = uiObjects:WaitForChild("TrailButton")
local leaderstats = player:WaitForChild("leaderstats")
local money = leaderstats:WaitForChild("Money")
local ownedSignSkins = player:WaitForChild("OwnedSignSkins")
local ownedTrails = player:WaitForChild("OwnedTrails")
local equippedSignSkin = player:WaitForChild("EquippedSignSkin")
local equippedTrail = player:WaitForChild("EquippedTrail")
local shopItems = { signSkin, trail, addSoon }
local shopItemTweens = {}
local shopAlertGeneration = 0
shopPanel.Visible = false
shopPanel.BackgroundTransparency = 1
shopScale.Scale = 1
local menuButtons = { playButton, shopButton }
local menuButtonResetters = {}
local menuClosing = false
local playPanelClosing = false
local shopClosing = false
local CLICK_SCALE_DOWN_TIME = 0.06
local CLICK_SCALE_UP_TIME = 0.08
local CLICK_FADE_PROGRESS = 0.7
local SHOP_CARD_STAGGER = 0.05
local ALERT_DISPLAY_TIME = 1.25
local ALERT_TWEEN_TIME = 0.12
local CATEGORY_CLOSE_TIME = 0.15
local CARD_ACTION_TWEEN_TIME = 0.12

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

local function cancelShopItemTweens()
	for _, tweenObject in shopItemTweens do
		tweenObject:Cancel()
	end

	table.clear(shopItemTweens)
end

local function setShopProperty(instance, propertyName, value, shouldTween)
	if shouldTween then
		table.insert(shopItemTweens, tween(instance, { [propertyName] = value }))
	else
		instance[propertyName] = value
	end
end

local function setShopItemHidden(button, isHidden, shouldTween)
	button.Interactable = not isHidden
	setShopProperty(button, "BackgroundTransparency", if isHidden then 1 else 0.35, shouldTween)

	for _, instance in button:GetDescendants() do
		if instance:IsA("TextLabel") then
			setShopProperty(instance, "TextTransparency", if isHidden then 1 else 0, shouldTween)
		elseif instance:IsA("ViewportFrame") then
			setShopProperty(instance, "ImageTransparency", if isHidden then 1 else 0, shouldTween)
		elseif instance:IsA("UIStroke") then
			setShopProperty(instance, "Transparency", if isHidden then 1 else 0, shouldTween)
		end
	end
end

local function fadeOutShopItems()
	if shopClosing then
		return
	end

	cancelShopItemTweens()
	for _, item in shopItems do
		setShopItemHidden(item, true, true)
	end
end

local function restoreShopItems()
	cancelShopItemTweens()
	for _, item in shopItems do
		setShopItemHidden(item, false, false)
	end
end

local function fadeInShopItems()
	cancelShopItemTweens()
	for _, item in shopItems do
		setShopItemHidden(item, false, true)
	end
end

local function setShopChromeHidden(isHidden, shouldTween)
	local function apply(instance, properties)
		if shouldTween then
			tween(instance, properties)
		else
			for propertyName, value in properties do
				instance[propertyName] = value
			end
		end
	end

	plusMoney.Interactable = not isHidden
	shopBack.Interactable = not isHidden
	apply(plusMoney, { TextTransparency = if isHidden then 1 else 0 })
	apply(moneyLabel, {
		BackgroundTransparency = if isHidden then 1 else 0.65,
		TextTransparency = if isHidden then 1 else 0,
	})
	apply(shopBack, {
		BackgroundTransparency = if isHidden then 1 else 0,
		TextTransparency = if isHidden then 1 else 0,
	})

	local backStroke = shopBack:FindFirstChild("UIStroke")
	if backStroke then
		apply(backStroke, { Transparency = if isHidden then 1 else 0.4 })
	end
end

local function hideShopAlert(shouldTween)
	shopAlertGeneration += 1
	if shouldTween then
		tween(shopAlert, {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		}, ALERT_TWEEN_TIME)
		tween(shopAlertStroke, { Transparency = 1 }, ALERT_TWEEN_TIME)
	else
		shopAlert.BackgroundTransparency = 1
		shopAlert.TextTransparency = 1
		shopAlertStroke.Transparency = 1
	end
end

local function showShopAlert(message)
	shopAlertGeneration += 1
	local generation = shopAlertGeneration
	shopAlert.Text = message
	tween(shopAlert, {
		BackgroundTransparency = 0.3,
		TextTransparency = 0,
	}, ALERT_TWEEN_TIME)
	tween(shopAlertStroke, { Transparency = 0.7 }, ALERT_TWEEN_TIME)

	task.delay(ALERT_DISPLAY_TIME, function()
		if generation ~= shopAlertGeneration then
			return
		end

		hideShopAlert(true)
	end)
end

for _, item in shopItems do
	setShopItemHidden(item, true, false)
end
setShopChromeHidden(true, false)
hideShopAlert(false)

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
local roomAlert = roomFrame:WaitForChild("Alert")
local roomAlertStroke = roomAlert:WaitForChild("UIStroke")
local roomPassword = roomPanel:WaitForChild("Password")
local roomPasswordScale = roomPassword:WaitForChild("UIScale")
local roomPasswordTextBox = roomPassword:WaitForChild("TextBox")
local roomPasswordEnter = roomPassword:WaitForChild("Enter")
local roomBack = roomPanel:WaitForChild("Back")
local memberParent = roomFrame:WaitForChild("MemberParent")
local roomCards = {}
local roomCardsTransparency = 1
local currentRoom
local pendingPasswordRoom
local roomAlertGeneration = 0
local roomConnections = {}
local tweenRoomCardsTransparency
local JOIN_ERROR_MESSAGES = {
	IncorrectPassword = "Incorrect password.",
	RoomFull = "This room is full.",
	VoiceRequired = "Voice chat is required to join this room.",
	RoomUnavailable = "This room is no longer available.",
}
roomPasswordScale.Scale = 0
roomPasswordEnter.Interactable = false
roomAlert.BackgroundTransparency = 1
roomAlert.TextTransparency = 1
roomAlertStroke.Transparency = 1
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

local function isRoomOverlay(instance)
	return instance == roomAlert or instance == roomPassword or instance:IsDescendantOf(roomPassword)
end

local function setRoomPanelTransparency(transparency)
	roomFrame.BackgroundTransparency = if transparency >= 1 then 1 else 0.65
	roomBack.BackgroundTransparency = transparency

	for _, instance in roomPanel:GetDescendants() do
		if
			not isRoomOverlay(instance)
			and instance ~= roomStart
			and instance ~= roomDesc
			and (instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox"))
		then
			instance.TextTransparency = transparency
		elseif not isRoomOverlay(instance) and instance:IsA("UIStroke") then
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
		if not isRoomOverlay(instance) and instance:IsA("GuiButton") then
			instance.Interactable = transparency < 1
		end

		if
			not isRoomOverlay(instance)
			and instance ~= roomStart
			and instance ~= roomDesc
			and (instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox"))
		then
			tween(instance, { TextTransparency = transparency })
		elseif not isRoomOverlay(instance) and instance:IsA("UIStroke") then
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
	tweenRoomStartTransparency(room, 0)
	tweenRoomDescTransparency(room, 0)

	local locked = roomPanel:FindFirstChild("Locked", true)
	if locked and locked:IsA("GuiObject") then
		locked.Visible = room:GetAttribute("PasswordEnabled") == true
	end

	renderMembers(room)
end

local function hideRoomAlert(shouldTween)
	roomAlertGeneration += 1
	if shouldTween then
		tween(roomAlert, {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		}, ALERT_TWEEN_TIME)
		tween(roomAlertStroke, { Transparency = 1 }, ALERT_TWEEN_TIME)
	else
		roomAlert.BackgroundTransparency = 1
		roomAlert.TextTransparency = 1
		roomAlertStroke.Transparency = 1
	end
end

local function showRoomAlert(message)
	roomAlertGeneration += 1
	local generation = roomAlertGeneration

	if not currentRoom then
		setRoomPanelTransparency(1)
		roomPanel.Visible = true
	end

	roomAlert.Text = message
	tween(roomAlert, {
		BackgroundTransparency = 0.3,
		TextTransparency = 0,
	}, ALERT_TWEEN_TIME)
	tween(roomAlertStroke, { Transparency = 0.7 }, ALERT_TWEEN_TIME)

	task.delay(ALERT_DISPLAY_TIME, function()
		if generation ~= roomAlertGeneration then
			return
		end

		tween(roomAlert, {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		}, ALERT_TWEEN_TIME)
		tween(roomAlertStroke, { Transparency = 1 }, ALERT_TWEEN_TIME)
		task.delay(ALERT_TWEEN_TIME, function()
			if
				generation == roomAlertGeneration
				and not currentRoom
				and not pendingPasswordRoom
				and roomPasswordScale.Scale <= 0
			then
				roomPanel.Visible = false
			end
		end)
	end)
end

local function showPasswordPrompt(room)
	pendingPasswordRoom = room
	currentRoom = nil
	clearRoomConnections()
	clearMemberCards()
	hideRoomAlert(false)
	setRoomPanelTransparency(1)
	roomPanel.Visible = true
	roomPasswordTextBox.Text = ""
	roomPasswordEnter.Interactable = true
	tween(roomPasswordScale, { Scale = 1 })

	task.defer(function()
		if pendingPasswordRoom == room then
			roomPasswordTextBox:CaptureFocus()
		end
	end)
end

local function hideRoomPanel()
	clearRoomConnections()
	clearMemberCards()
	pendingPasswordRoom = nil
	roomPasswordEnter.Interactable = false
	tween(roomPasswordScale, { Scale = 0 })
	hideRoomAlert(true)
	tweenRoomPanelTransparency(1)
	roomBack.Interactable = false
	currentRoom = nil
	task.delay(0.25, function()
		if not currentRoom and not pendingPasswordRoom then
			roomPanel.Visible = false
		end
	end)
end

local function showRoomPanel(room)
	pendingPasswordRoom = nil
	roomPasswordEnter.Interactable = false
	roomPasswordScale.Scale = 0
	hideRoomAlert(false)
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

local function requestJoin(room, password)
	local invoked, result = pcall(function()
		return joinRoomFunction:InvokeServer(room.Name, password)
	end)

	if invoked and typeof(result) == "table" and result.Success == true and typeof(result.RoomName) == "string" then
		local joinedRoom = roomsFolder:FindFirstChild(result.RoomName)
		if joinedRoom then
			showRoomPanel(joinedRoom)
			return
		end
	end

	local errorCode = if invoked and typeof(result) == "table" then result.Error else "RoomUnavailable"
	showRoomAlert(JOIN_ERROR_MESSAGES[errorCode] or JOIN_ERROR_MESSAGES.RoomUnavailable)
end

local function submitPassword()
	local room = pendingPasswordRoom
	local password = roomPasswordTextBox.Text
	pendingPasswordRoom = nil
	roomPasswordEnter.Interactable = false
	tween(roomPasswordScale, { Scale = 0 })

	if room then
		requestJoin(room, password)
	else
		showRoomAlert(JOIN_ERROR_MESSAGES.RoomUnavailable)
	end
end

roomPasswordTextBox.FocusLost:Connect(function(enterPressed)
	if not enterPressed then
		return
	end

	submitPassword()
end)
roomPasswordEnter.Activated:Connect(submitPassword)

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
			if room:GetAttribute("PasswordEnabled") == true then
				showPasswordPrompt(room)
			else
				pendingPasswordRoom = nil
				roomPasswordEnter.Interactable = false
				tween(roomPasswordScale, { Scale = 0 })
				requestJoin(room, nil)
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
	elseif pendingPasswordRoom == room then
		pendingPasswordRoom = nil
		roomPasswordEnter.Interactable = false
		tween(roomPasswordScale, { Scale = 0 })
		showRoomAlert(JOIN_ERROR_MESSAGES.RoomUnavailable)
	end
end)

local function formatMoney(value)
	local formatted = tostring(math.max(0, math.floor(value)))
	while true do
		local updated, replacements = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		formatted = updated
		if replacements == 0 then
			break
		end
	end
	return formatted
end

local function updateMoneyLabel()
	moneyLabel.Text = `{formatMoney(money.Value)}P`
end

updateMoneyLabel()
money:GetPropertyChangedSignal("Value"):Connect(updateMoneyLabel)

local generatedShopCards = {}
local shopCardRecords = {}
local activeShopCategory
local selectedShopCard
local shopCategoryGeneration = 0
local shopCategoryClosing = false
local purchasePending = false
local moneyShopOpen = false
local closeShopCategory

local function setMoneyShopVisible(isVisible, shouldTween)
	local textTransparency = if isVisible then 0 else 1
	local backgroundTransparency = if isVisible then 0.35 else 1

	if shouldTween then
		tween(moneyShopDeco, { TextTransparency = textTransparency })
	else
		moneyShopDeco.TextTransparency = textTransparency
	end

	for _, product in moneyProductButtons do
		local button = product.button
		button.Interactable = isVisible
		if shouldTween then
			tween(button, {
				BackgroundTransparency = backgroundTransparency,
				TextTransparency = textTransparency,
			})
		else
			button.BackgroundTransparency = backgroundTransparency
			button.TextTransparency = textTransparency
		end
	end
end

local function setMoneyShopEntryHidden(isHidden, shouldTween)
	local function apply(instance, properties)
		if shouldTween then
			tween(instance, properties)
		else
			for propertyName, value in properties do
				instance[propertyName] = value
			end
		end
	end

	plusMoney.Interactable = not isHidden
	apply(plusMoney, { TextTransparency = if isHidden then 1 else 0 })
	apply(moneyLabel, {
		BackgroundTransparency = if isHidden then 1 else 0.65,
		TextTransparency = if isHidden then 1 else 0,
	})
end

local function openMoneyShopContent()
	moneyShopOpen = true
	setMoneyShopEntryHidden(true, true)
	hideShopAlert(true)
	setMoneyShopVisible(true, true)
end

local function openMoneyShop()
	if shopCategoryClosing or shopClosing or moneyShopOpen then
		return
	end

	if activeShopCategory then
		closeShopCategory(openMoneyShopContent)
		return
	end

	fadeOutShopItems()
	openMoneyShopContent()
end

local function closeMoneyShop()
	if not moneyShopOpen then
		return
	end

	moneyShopOpen = false
	setMoneyShopVisible(false, true)
	setMoneyShopEntryHidden(false, true)
	fadeInShopItems()
end

setMoneyShopVisible(false, false)

local function getActionButtonText(categoryName, item)
	local ownedFolder = if categoryName == "SignSkin" then ownedSignSkins else ownedTrails
	local equippedValue = if categoryName == "SignSkin" then equippedSignSkin else equippedTrail
	if equippedValue.Value == item.ModelName then
		return "Unequip"
	end
	if ownedFolder:FindFirstChild(item.ModelName) then
		return "Equip"
	end
	return `Purchase [{formatMoney(item.Price)}P]`
end

local CARD_STROKE_TRANSPARENCIES = {
	UIStroke1 = 0.83,
	UIStroke2 = 0,
}

local function getCardStrokes(card)
	local strokes = {}
	for strokeName, visibleTransparency in CARD_STROKE_TRANSPARENCIES do
		local stroke = card:FindFirstChild(strokeName, true)
		if stroke and stroke:IsA("UIStroke") then
			table.insert(strokes, {
				instance = stroke,
				visibleTransparency = visibleTransparency,
			})
		end
	end
	return strokes
end

local function setCardActionVisible(card, isVisible, shouldTween)
	local actionButton = card:WaitForChild("Button")
	actionButton.Interactable = isVisible and not purchasePending

	if shouldTween then
		local properties = if isVisible
			then { BackgroundTransparency = 0.3, TextTransparency = 0 }
			else { BackgroundTransparency = 1, TextTransparency = 1 }
		tween(actionButton, properties, CARD_ACTION_TWEEN_TIME)
	else
		actionButton.BackgroundTransparency = if isVisible then 0.3 else 1
		actionButton.TextTransparency = if isVisible then 0 else 1
	end

	for _, strokeRecord in getCardStrokes(card) do
		local transparency = if isVisible then strokeRecord.visibleTransparency else 1
		if shouldTween then
			tween(strokeRecord.instance, { Transparency = transparency }, CARD_ACTION_TWEEN_TIME)
		else
			strokeRecord.instance.Transparency = transparency
		end
	end
end

local function selectShopCard(card)
	if selectedShopCard == card or shopCategoryClosing then
		return
	end

	if selectedShopCard and selectedShopCard.Parent then
		setCardActionVisible(selectedShopCard, false, true)
	end

	selectedShopCard = card
	hideShopAlert(true)
	setCardActionVisible(card, true, true)
end

local function updateShopCardButtons()
	for card, record in shopCardRecords do
		if card.Parent then
			card:WaitForChild("Button").Text = getActionButtonText(record.categoryName, record.item)
		end
	end
end

local function setupSignSkinPreview(card, item)
	local viewport = card:WaitForChild("ViewportFrame")
	local source = signSkinsFolder:FindFirstChild(item.ModelName)
	if not source then
		return
	end

	local worldModel = Instance.new("WorldModel")
	worldModel.Name = "Preview"
	worldModel.Parent = viewport

	local preview = source:Clone()
	for _, descendant in preview:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	preview.Parent = worldModel
	worldModel:PivotTo(CFrame.new())

	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, -4), Vector3.zero)
	camera.Parent = viewport
	viewport.CurrentCamera = camera
end

local function setupTrailPreview(card, item)
	local trailImage = card:WaitForChild("TrailImage")
	local trailObject = trailFolder:FindFirstChild(item.ModelName)
	if not trailObject or not trailObject:IsA("Trail") then
		return
	end

	local colorGradient = trailImage:FindFirstChildWhichIsA("UIGradient")
	if not colorGradient then
		colorGradient = Instance.new("UIGradient")
		colorGradient.Name = "TrailColor"
		colorGradient.Parent = trailImage
	end
	colorGradient.Color = trailObject.Color
	trailImage.ImageColor3 = Color3.new(1, 1, 1)
	trailImage.BackgroundColor3 = Color3.new(1, 1, 1)
	trailImage.Image = trailObject.Texture

	if trailObject.Texture == "" then
		trailImage.ImageTransparency = 1
		trailImage.BackgroundTransparency = 0
	else
		trailImage.ImageTransparency = 0
		trailImage.BackgroundTransparency = 1
	end
end

local function applyPurchaseResult(actionButton, result)
	if result.Status == "Purchased" then
		actionButton.Text = "Equip"
	elseif result.Status == "Equipped" then
		actionButton.Text = "Unequip"
	elseif result.Status == "Unequipped" then
		actionButton.Text = "Equip"
	end
end

local function createShopCard(categoryName, item, index, generation)
	local template = if categoryName == "SignSkin" then skinButtonTemplate else trailButtonTemplate
	local card = template:Clone()
	card.Name = item.ModelName
	card.LayoutOrder = index
	card.Visible = true

	local nameLabel = card:WaitForChild("Name")
	local priceLabel = card:WaitForChild("Price")
	local actionButton = card:WaitForChild("Button")
	local scale = card:WaitForChild("UIScale")
	nameLabel.Text = item.Name
	priceLabel.Text = `{formatMoney(item.Price)}P`
	actionButton.Text = getActionButtonText(categoryName, item)
	scale.Scale = 0
	setCardActionVisible(card, false, false)

	if categoryName == "SignSkin" then
		setupSignSkinPreview(card, item)
	else
		setupTrailPreview(card, item)
	end

	shopCardRecords[card] = {
		categoryName = categoryName,
		item = item,
	}
	table.insert(generatedShopCards, card)
	card.Parent = shopContainer

	task.delay((index - 1) * SHOP_CARD_STAGGER, function()
		if generation == shopCategoryGeneration and activeShopCategory == categoryName and card.Parent then
			tween(scale, { Scale = 1 })
		end
	end)

	if card:IsA("GuiButton") then
		card.Activated:Connect(function()
			selectShopCard(card)
		end)
	end

	actionButton.Activated:Connect(function()
		if selectedShopCard ~= card or purchasePending then
			return
		end

		purchasePending = true
		actionButton.Interactable = false
		local requestGeneration = shopCategoryGeneration
		local requestSucceeded, result = pcall(function()
			return purchaseFunction:InvokeServer(categoryName, item.ModelName)
		end)
		purchasePending = false

		if not shopCategoryClosing and activeShopCategory and selectedShopCard and selectedShopCard.Parent then
			selectedShopCard:WaitForChild("Button").Interactable = true
		end
		if requestGeneration ~= shopCategoryGeneration or activeShopCategory ~= categoryName then
			return
		end

		if not requestSucceeded or typeof(result) ~= "table" then
			showShopAlert("Could not contact shop. Try again.")
		else
			applyPurchaseResult(actionButton, result)
			if result.Status ~= "Equipped" and result.Status ~= "Unequipped" then
				showShopAlert(result.Message or "Something went wrong. Try again.")
			else
				hideShopAlert(true)
			end
		end

	end)
end

local function clearGeneratedShopCards()
	for _, card in generatedShopCards do
		shopCardRecords[card] = nil
		card:Destroy()
	end
	table.clear(generatedShopCards)
	selectedShopCard = nil
end

local function openShopCategory(categoryName)
	if activeShopCategory or shopCategoryClosing or shopClosing then
		return
	end

	local config = if categoryName == "SignSkin" then signSkinConfig else trailConfig
	activeShopCategory = categoryName
	shopCategoryGeneration += 1
	local generation = shopCategoryGeneration
	fadeOutShopItems()
	hideShopAlert(true)
	clearGeneratedShopCards()

	for index, item in ipairs(config) do
		createShopCard(categoryName, item, index, generation)
	end
end

closeShopCategory = function(onClosed)
	if not activeShopCategory or shopCategoryClosing then
		return
	end

	shopCategoryClosing = true
	activeShopCategory = nil
	shopCategoryGeneration += 1
	hideShopAlert(true)

	local lastTween
	for _, card in generatedShopCards do
		card:WaitForChild("Button").Interactable = false
		lastTween = tween(card:WaitForChild("UIScale"), { Scale = 0 }, CATEGORY_CLOSE_TIME)
	end

	local function finishClosing()
		clearGeneratedShopCards()
		shopCategoryClosing = false
		if onClosed then
			onClosed()
		else
			fadeInShopItems()
		end
	end

	if lastTween then
		lastTween.Completed:Once(finishClosing)
	else
		finishClosing()
	end
end

ownedSignSkins.ChildAdded:Connect(updateShopCardButtons)
ownedSignSkins.ChildRemoved:Connect(updateShopCardButtons)
ownedTrails.ChildAdded:Connect(updateShopCardButtons)
ownedTrails.ChildRemoved:Connect(updateShopCardButtons)
equippedSignSkin:GetPropertyChangedSignal("Value"):Connect(updateShopCardButtons)
equippedTrail:GetPropertyChangedSignal("Value"):Connect(updateShopCardButtons)

for _, product in moneyProductButtons do
	local productId = product.productId
	product.button.Activated:Connect(function()
		MarketplaceService:PromptProductPurchase(player, productId)
	end)
end

purchaseAlert.OnClientEvent:Connect(function(message)
	showShopAlert(message)
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
	shopFrame.BackgroundTransparency = 1
	shopScale.Scale = 1
	for _, item in shopItems do
		setShopItemHidden(item, true, false)
	end
	setShopChromeHidden(true, false)
	moneyShopOpen = false
	setMoneyShopVisible(false, false)
	hideShopAlert(false)
	updateMoneyLabel()
	shopPanel.Visible = true
	tween(shopFrame, { BackgroundTransparency = 0.35 })
	setShopChromeHidden(false, true)
	fadeInShopItems()
end)

signSkin.Activated:Connect(function()
	openShopCategory("SignSkin")
end)
trail.Activated:Connect(function()
	openShopCategory("Trail")
end)
plusMoney.Activated:Connect(function()
	openMoneyShop()
end)

shopBack.Activated:Connect(function()
	if shopClosing or shopCategoryClosing then
		return
	end

	if activeShopCategory then
		closeShopCategory()
		return
	end
	if moneyShopOpen then
		closeMoneyShop()
		return
	end

	fadeOutShopItems()
	setMoneyShopVisible(false, true)
	shopClosing = true
	shopBack.Interactable = false
	hideShopAlert(true)
	setShopChromeHidden(true, true)
	tween(shopFrame, { BackgroundTransparency = 1 }).Completed:Once(function()
		shopPanel.Visible = false
		clearGeneratedShopCards()
		resetMenuButtons()
		setMenuTextTransparency(0)
		setMenuInteractable(true)
		menuClosing = false
		shopClosing = false
		shopBack.Interactable = true
	end)
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
	local roomName, createError = createRoomFunction:InvokeServer(createRoomSettings)
	local room = roomName and roomsFolder:WaitForChild(roomName, 5)
	hideCreateRoomPanel()

	if room then
		showRoomPanel(room)
	else
		revealPlayPanel()
		tweenRoomCardsTransparency(0)
		if createError then
			showRoomAlert(JOIN_ERROR_MESSAGES[createError] or JOIN_ERROR_MESSAGES.RoomUnavailable)
		end
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
