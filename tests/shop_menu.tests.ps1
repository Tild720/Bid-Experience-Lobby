$ErrorActionPreference = "Stop"

$client = Get-Content -Raw "src/StarterPlayerScripts/MenuTitleEffects.client.lua"

foreach ($required in @(
	'buttons:WaitForChild("2Shop")',
	'mainGui:WaitForChild("Shop")',
	'shopPanel:WaitForChild("Frame")',
	'shopFrame:WaitForChild("UIScale")',
	'shopFrame:WaitForChild("SignSkin")',
	'shopFrame:WaitForChild("Trail")',
	'shopFrame:WaitForChild("AddSoon")',
	'local shopItemTweens = {}',
	'local function cancelShopItemTweens()',
	'local function fadeOutShopItems()',
	'local function restoreShopItems()',
	'table.insert(shopItemTweens, tween(',
	'if shopClosing then',
	'instance:IsA("TextLabel")',
	'instance:IsA("ViewportFrame")',
	'instance:IsA("UIStroke")',
	'{ BackgroundTransparency = 0.35 }',
	'openShopCategory("SignSkin")',
	'openShopCategory("Trail")',
	'closeShopCategory(openMoneyShopContent)',
	'if activeShopCategory then',
	'closeShopCategory()',
	'clearGeneratedShopCards()',
	'setShopChromeHidden(true, true)',
	'setShopChromeHidden(false, true)',
	'tween(shopFrame, { BackgroundTransparency = 0.35 })',
	'tween(shopFrame, { BackgroundTransparency = 1 }).Completed:Once',
	'shopPanel.Visible = true',
	'shopPanel.Visible = false',
	'shopBack.Activated:Connect'
)) {
	if (-not $client.Contains($required)) {
		throw "Shop menu flow is missing: $required"
	}
}

$openMoneyShop = [regex]::Match(
	$client,
	'local function openMoneyShop\(\)[\s\S]*?local function closeMoneyShop'
).Value
if (
	$openMoneyShop -notmatch 'if activeShopCategory then' -or
	$openMoneyShop -notmatch 'closeShopCategory\(openMoneyShopContent\)'
) {
	throw "PlusMoney must scale out an active SignSkin or Trail category before showing point products"
}

$closeCategory = [regex]::Match(
	$client,
	'closeShopCategory\s*=\s*function\(onClosed\)[\s\S]*?ownedSignSkins\.ChildAdded'
).Value
if (
	$closeCategory -notmatch 'tween\(card:WaitForChild\("UIScale"\),\s*\{\s*Scale\s*=\s*0\s*\},\s*CATEGORY_CLOSE_TIME\)' -or
	$closeCategory -notmatch 'if onClosed then[\s\S]*onClosed\(\)'
) {
	throw "Category cards must scale out before the PlusMoney content callback runs"
}

if ($client -match 'addSoon\.Activated:Connect') {
	throw "AddSoon must not perform any action when clicked"
}

if ($client -match 'tween\(shopScale') {
	throw "Shop open and close must use fades instead of frame scale tweens"
}

$closeHandler = $client.IndexOf('shopBack.Activated:Connect')
$closeFade = $client.IndexOf('fadeOutShopItems()', $closeHandler)
$closeLock = $client.IndexOf('shopClosing = true', $closeHandler)
if ($closeHandler -lt 0 -or $closeFade -lt 0 -or $closeLock -lt 0 -or $closeFade -gt $closeLock) {
	throw "Shop items must start fading out before shopClosing blocks repeated fades"
}

if ($client -match '2Credits|HowToPlay|How to play') {
	throw "Legacy Credits/HowToPlay menu references must be removed"
}

Write-Output "shop menu regression checks passed"
