$ErrorActionPreference = "Stop"

$client = Get-Content -Raw "src/StarterPlayerScripts/MenuTitleEffects.client.lua"
$server = Get-Content -Raw "src/ServerScriptService/LobbyRooms.server.lua"

foreach ($required in @(
	'game:GetService("UserInputService")',
	'Enum.KeyCode.F',
	'player.Name == "TildStudio"',
	'debugFillRoomEvent:FireServer()'
)) {
	if (-not $client.Contains($required)) {
		throw "TildStudio F shortcut is missing client behavior: $required"
	}
}

foreach ($required in @(
	'debugFillRoomEvent.OnServerEvent:Connect',
	'player.Name ~= "TildStudio"',
	'room:SetAttribute("CurrentPlayers", 3)',
	'room:SetAttribute("DebugFillUserId", player.UserId)',
	'local debugFilled = player.Name == "TildStudio"',
	'#members:GetChildren() < 3 and not debugFilled',
	'#players < 3 and not debugFilled',
	'LobbyPlaceId = game.PlaceId'
)) {
	if (-not $server.Contains($required)) {
		throw "TildStudio F shortcut is missing server validation: $required"
	}
}

Write-Output "TildStudio room override regression checks passed"
