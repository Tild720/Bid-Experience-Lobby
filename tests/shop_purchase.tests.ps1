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
	'trailImage.Image = trailObject.Texture',
	'colorGradient.Color = trailObject.Color',
	'trailObject.Texture == ""',
	'trailImage.ImageTransparency = 1',
	'trailImage.BackgroundTransparency = 0',
	'`Purchase [{formatMoney(item.Price)}P]`',
	'return "Equip"',
	'return "UnEquip"',
	'purchaseFunction:InvokeServer(categoryName, item.ModelName)',
	'selectedShopCard:WaitForChild("Button").Interactable = true',
	'{ BackgroundTransparency = 0.3, TextTransparency = 0 }',
	'Transparency = if isVisible then 0.4 else 1',
	'BackgroundTransparency = 0.5',
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

$pendingReset = $client.IndexOf('purchasePending = false', $client.IndexOf('purchaseFunction:InvokeServer'))
$staleResponseGuard = $client.IndexOf('if requestGeneration ~= shopCategoryGeneration', $pendingReset)
$safeRestoreGuard = $client.IndexOf('if not shopCategoryClosing and activeShopCategory', $pendingReset)
$interactableRestore = $client.IndexOf('selectedShopCard:WaitForChild("Button").Interactable = true', $safeRestoreGuard)
if ($pendingReset -lt 0 -or $staleResponseGuard -lt 0 -or $safeRestoreGuard -lt 0 -or $interactableRestore -lt 0 -or $safeRestoreGuard -gt $staleResponseGuard) {
	throw "The current selected card must be re-enabled before discarding a stale shop response"
}

Write-Output "shop purchase regression checks passed"
