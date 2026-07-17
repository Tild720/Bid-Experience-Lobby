$ErrorActionPreference = "Stop"

$client = Get-Content -Raw "src/StarterPlayerScripts/MenuTitleEffects.client.lua"
$server = Get-Content -Raw "src/ServerScriptService/LobbyRooms.server.lua"

if ($client -notmatch 'name = "SpeedDropdown"' -or $client -notmatch 'attribute = "CreateRoomSpeed"') {
	throw "Mode dropdown must be replaced by SpeedDropdown"
}

foreach ($speed in @("Slow", "Normal", "Fast")) {
	if ($client -notmatch "text = `"$speed`"") {
		throw "SpeedDropdown must include $speed"
	}
}

if ($client -match 'text = "Meme"') {
	throw "ThemeDropdown must only offer Roblox"
}

if ($client -notmatch 'instance\.Name:lower\(\):find\("dropdown"\)') {
	throw "Dropdown fade detection must include SpeedDropdown regardless of casing"
}

if ($server -notmatch 'VALID_SPEEDS\[speed\]' -or $server -notmatch 'room:SetAttribute\("Speed", getSpeed\(settings\)\)') {
	throw "Rooms must validate and store the selected speed"
}

if ($server -notmatch 'room:SetAttribute\("Theme", "Roblox"\)') {
	throw "Rooms must force the only supported Roblox theme"
}

if ($server -notmatch 'Speed = room:GetAttribute\("Speed"\)') {
	throw "TeleportData must include Speed"
}

Write-Output "lobby speed dropdown regression checks passed"
