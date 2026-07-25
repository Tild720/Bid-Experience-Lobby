$ErrorActionPreference = "Stop"

$server = Get-Content -Raw "src/ServerScriptService/LobbyPlayerStats.server.lua"
$client = Get-Content -Raw "src/StarterPlayerScripts/MenuTitleEffects.client.lua"

foreach ($required in @(
	'ReplicatedStorage:WaitForChild("Modules")',
	'require(modules:WaitForChild("SignSkinConfig"))',
	'require(modules:WaitForChild("TrailConfig"))',
	'ReplicatedStorage:FindFirstChild("ShopPurchaseFunction")',
	'purchaseFunction.OnServerInvoke',
	'money.Name = "Money"',
	'data.Money',
	'data.Points',
	'OwnedSignSkins',
	'OwnedTrails',
	'EquippedSignSkin',
	'EquippedTrail',
	'player:SetAttribute("ShopDataLoaded", true)',
	'player:SetAttribute("ShopDataLoadFailed", true)',
	'player:GetAttribute("ShopDataLoadFailed")',
	'local loadingPlayers = {}',
	'local saveLocks = {}',
	'local requestHistory = {}',
	'typeof(data) ~= "table"',
	'SessionStartedAt',
	'storedSessionStart > snapshot.SessionStartedAt',
	'money.Value < item.Price',
	'money.Value -= item.Price',
	'makeResult(true, "Purchased"',
	'"Purchased! Click again to Equip"',
	'"Not enough Money."',
	'makeResult(true, "Equipped"',
	'makeResult(true, "Unequipped"',
	'statsStore:UpdateAsync',
	'Players.PlayerRemoving:Connect',
	'game:BindToClose'
)) {
	if (-not $server.Contains($required)) {
		throw "Server shop purchase flow is missing: $required"
	}
}

if ($server -match 'Price\s*=\s*request|request\.Price|priceFromClient') {
	throw "The server must use Config prices instead of client-provided prices"
}

$invokeHandler = $server.IndexOf('purchaseFunction.OnServerInvoke')
$rateLimitCheck = $server.IndexOf('if not isShopRequestAllowed(player)', $invokeHandler)
$purchaseLockCheck = $server.IndexOf('if purchaseLocks[player]', $invokeHandler)
if ($invokeHandler -lt 0 -or $rateLimitCheck -lt 0 -or $purchaseLockCheck -lt 0 -or $rateLimitCheck -gt $purchaseLockCheck) {
	throw "Every shop invocation must be rate-limited before the purchase lock early return"
}

if ($client -match 'Purchase[^\r\n]*\$|moneyLabel\.Text[^\r\n]*\$|priceLabel\.Text[^\r\n]*\$') {
	throw "Shop prices and Money must use P instead of dollar signs"
}

if ($client -match 'shopAlert:WaitForChild\("TextLabel"\)') {
	throw "Shop.Frame.Alert is the TextLabel and must not look for a child TextLabel"
}

foreach ($required in @(
	'shopFrame:WaitForChild("Container")',
	'shopFrame:WaitForChild("Alert")',
	'shopFrame:WaitForChild("PlusMoney")',
	'shopFrame:WaitForChild("Money")',
	'uiObjects:WaitForChild("SkinButton")',
	'uiObjects:WaitForChild("TrailButton")',
	'require(modules:WaitForChild("SignSkinConfig"))',
	'require(modules:WaitForChild("TrailConfig"))',
	'ReplicatedStorage:WaitForChild("SignSkins")',
	'ReplicatedStorage:WaitForChild("Trail")',
	'local SHOP_CARD_STAGGER = 0.05',
	'task.delay((index - 1) * SHOP_CARD_STAGGER',
	'CFrame.lookAt(Vector3.new(0, 0, -4), Vector3.zero)',
	'item.ModelName == "FutureSign"',
	'CFrame.Angles(0, math.rad(90), 0)',
	'trailImage.Image = trailObject.Texture',
	'colorGradient.Color = trailObject.Color',
	'trailObject.Texture == ""',
	'trailImage.ImageTransparency = 1',
	'trailImage.BackgroundTransparency = 0',
	'`Purchase [{formatMoney(item.Price)}P]`',
	'return "Equip"',
	'return "Unequip"',
	'purchaseFunction:InvokeServer(categoryName, item.ModelName)',
	'selectedShopCard:WaitForChild("Button").Interactable = true',
	'{ BackgroundTransparency = 0.3, TextTransparency = 0 }',
	'UIStroke1 = 0.83',
	'UIStroke2 = 0',
	'local CARD_ACTION_TWEEN_TIME = 0.12',
	'BackgroundTransparency = 0.3',
	'TextTransparency = 0',
	'OwnedSignSkins',
	'OwnedTrails',
	'EquippedSignSkin',
	'EquippedTrail',
	'money:GetPropertyChangedSignal("Value")',
	'moneyLabel.Text = `{formatMoney(money.Value)}P`'
)) {
	if (-not $client.Contains($required)) {
		throw "Client shop purchase flow is missing: $required"
	}
}

if ($client -cmatch '"UnEquip"') {
	throw 'Shop action buttons must spell "Unequip" consistently'
}

foreach ($required in @(
	'return "Unequip"',
	'actionButton.Text = "Unequip"',
	'local shopAlertGeneration = 0',
	'local shopAlertStroke = shopAlert:WaitForChild("UIStroke")',
	'local roomAlertStroke = roomAlert:WaitForChild("UIStroke")',
	'BackgroundTransparency = 0.3',
	'task.delay(ALERT_DISPLAY_TIME',
	'tween(shopAlert, {',
	'result.Status ~= "Equipped" and result.Status ~= "Unequipped"'
)) {
	if (-not $client.Contains($required)) {
		throw "Shop feedback flow is missing: $required"
	}
}

foreach ($alertPrefix in @("shopAlert", "roomAlert")) {
	$strokeName = "${alertPrefix}Stroke"
	if (
		$client -notmatch ([regex]::Escape($strokeName) + '\.Transparency\s*=\s*1') -or
		$client -notmatch ('tween\(' + [regex]::Escape($strokeName) + ',\s*\{\s*Transparency\s*=\s*0\.7\s*\},\s*ALERT_TWEEN_TIME\)')
	) {
		throw "$alertPrefix UIStroke must initialize hidden and tween to 0.7 with the Alert"
	}
}

$cardStrokeFunction = [regex]::Match(
	$client,
	'local function getCardStrokes\(card\)[\s\S]*?local function setCardActionVisible'
).Value
if (
	$cardStrokeFunction -notmatch 'FindFirstChild\(strokeName,\s*true\)' -or
	$cardStrokeFunction -notmatch 'visibleTransparency'
) {
	throw "SkinButton and TrailButton strokes must be resolved recursively by UIStroke1/UIStroke2 name"
}

$cardActionFunction = [regex]::Match(
	$client,
	'local function setCardActionVisible\(card,\s*isVisible,\s*shouldTween\)[\s\S]*?local function selectShopCard'
).Value
if ($cardActionFunction -notmatch 'CARD_ACTION_TWEEN_TIME') {
	throw "Card action button and stroke tweens must use the faster interaction duration"
}

$roomAlertFunction = [regex]::Match(
	$client,
	'local function showRoomAlert\(message\)[\s\S]*?local function showPasswordPrompt'
).Value
if (
	$roomAlertFunction -notmatch 'BackgroundTransparency\s*=\s*0\.3' -or
	$roomAlertFunction -notmatch 'task\.delay\(ALERT_DISPLAY_TIME'
) {
	throw "Room alerts must use the same faster auto-fade and 0.3 background transparency"
}

$roomOverlayFunction = [regex]::Match(
	$client,
	'local function isRoomOverlay\(instance\)[\s\S]*?local function setRoomPanelTransparency'
).Value
if ($roomOverlayFunction -notmatch 'instance:IsDescendantOf\(roomAlert\)') {
	throw "Room panel fades must not overwrite the Alert UIStroke transparency"
}

$pendingReset = $client.IndexOf('purchasePending = false', $client.IndexOf('purchaseFunction:InvokeServer'))
$staleResponseGuard = $client.IndexOf('if requestGeneration ~= shopCategoryGeneration', $pendingReset)
$safeRestoreGuard = $client.IndexOf('if not shopCategoryClosing and activeShopCategory', $pendingReset)
$interactableRestore = $client.IndexOf('selectedShopCard:WaitForChild("Button").Interactable = true', $safeRestoreGuard)
if ($pendingReset -lt 0 -or $staleResponseGuard -lt 0 -or $safeRestoreGuard -lt 0 -or $interactableRestore -lt 0 -or $safeRestoreGuard -gt $staleResponseGuard) {
	throw "The current selected card must be re-enabled before discarding a stale shop response"
}

$purchaseHandler = [regex]::Match(
	$client,
	'actionButton\.Activated:Connect\(function\(\)[\s\S]*?\n\tend\)\nend'
).Value
$insufficientFundsBranch = $purchaseHandler.IndexOf('if result.Status == "InsufficientFunds" then')
if ($insufficientFundsBranch -lt 0) {
	throw "InsufficientFunds must open PlusMoney before the generic purchase Alert branch"
}

$openMoneyShopCall = $purchaseHandler.IndexOf('openMoneyShop()', $insufficientFundsBranch)
$genericAlert = $purchaseHandler.IndexOf('showShopAlert(result.Message', $insufficientFundsBranch)
if (
	$openMoneyShopCall -lt 0 -or
	$genericAlert -lt 0 -or
	$openMoneyShopCall -gt $genericAlert
) {
	throw "InsufficientFunds must open PlusMoney before the generic purchase Alert branch"
}

Write-Output "shop purchase regression checks passed"
