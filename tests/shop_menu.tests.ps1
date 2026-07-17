$ErrorActionPreference = "Stop"

$client = Get-Content -Raw "src/StarterPlayerScripts/MenuTitleEffects.client.lua"

foreach ($required in @(
	'buttons:WaitForChild("2Shop")',
	'mainGui:WaitForChild("Shop")',
	'shopPanel.Visible = true',
	'shopPanel.Visible = false',
	'shopBack.Activated:Connect'
)) {
	if (-not $client.Contains($required)) {
		throw "Shop menu flow is missing: $required"
	}
}

if ($client -match '2Credits|HowToPlay|How to play') {
	throw "Legacy Credits/HowToPlay menu references must be removed"
}

Write-Output "shop menu regression checks passed"
