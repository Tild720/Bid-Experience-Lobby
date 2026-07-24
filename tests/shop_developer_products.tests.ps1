$ErrorActionPreference = "Stop"

$server = Get-Content -Raw "src/ServerScriptService/LobbyPlayerStats.server.lua"
$client = Get-Content -Raw "src/StarterPlayerScripts/MenuTitleEffects.client.lua"

foreach ($required in @(
	'game:GetService("MarketplaceService")',
	'[3611489162] = 2000',
	'[3611489310] = 7000',
	'[3611489343] = 20000',
	'MarketplaceService.ProcessReceipt',
	'Enum.ProductPurchaseDecision.PurchaseGranted',
	'Enum.ProductPurchaseDecision.NotProcessedYet',
	'ProcessedReceipts',
	'ShopPurchaseAlert'
)) {
	if (-not $server.Contains($required)) {
		throw "Server developer-product flow is missing: $required"
	}
}

foreach ($required in @(
	'game:GetService("MarketplaceService")',
	'shopFrame:WaitForChild("2000P")',
	'shopFrame:WaitForChild("7000P")',
	'shopFrame:WaitForChild("20000P")',
	'shopFrame:WaitForChild("Deco")',
	'MarketplaceService:PromptProductPurchase(player, productId)',
	'openMoneyShop()',
	'closeMoneyShop()',
	'showShopAlert(message)'
)) {
	if (-not $client.Contains($required)) {
		throw "Client developer-product flow is missing: $required"
	}
}

Write-Output "shop developer-product regression checks passed"
