$ErrorActionPreference = "Stop"

$server = Get-Content -Raw "src/ServerScriptService/LobbyRooms.server.lua"
$client = Get-Content -Raw "src/StarterPlayerScripts/MenuTitleEffects.client.lua"

function Assert-Contains {
	param(
		[string]$Text,
		[string]$Pattern,
		[string]$Message
	)

	if ($Text -notmatch $Pattern) {
		throw $Message
	}
}

Assert-Contains $server 'game:GetService\("VoiceChatService"\)' `
	"Room joins must check voice eligibility through VoiceChatService"
Assert-Contains $server 'roomPasswords' `
	"Room passwords must be held in server-only state"
Assert-Contains $server 'IsVoiceEnabledForUserIdAsync\(player\.UserId\)' `
	"VoiceOnly joins must check the joining player"
Assert-Contains $server 'pcall\(function\(\)[\s\S]*IsVoiceEnabledForUserIdAsync' `
	"Voice eligibility lookup failures must be handled"

if ($server -match 'SetAttribute\("Password",') {
	throw "Password text must not be replicated through room attributes"
}

foreach ($errorCode in @("IncorrectPassword", "RoomFull", "VoiceRequired", "RoomUnavailable")) {
	Assert-Contains $server ([regex]::Escape($errorCode)) `
		"JoinRoomFunction must return the $errorCode failure code"
}

$joinHandler = [regex]::Match(
	$server,
	'joinRoomFunction\.OnServerInvoke\s*=\s*function[\s\S]*?leaveRoomEvent\.OnServerEvent'
).Value
$createHandler = [regex]::Match(
	$server,
	'local function createRoom\(player,\s*settings\)[\s\S]*?createRoomFunction\.OnServerInvoke'
).Value
Assert-Contains $createHandler 'CreateRoomVoiceOnly[\s\S]*canUseVoice\(player\)[\s\S]*VoiceRequired' `
	"Creating a VoiceOnly room must reject a player without voice eligibility"

$createLeaveIndex = $createHandler.IndexOf("leaveAllRooms(player)")
$createVoiceIndex = $createHandler.IndexOf("VoiceRequired")
if ($createLeaveIndex -lt 0 -or $createVoiceIndex -lt 0 -or $createLeaveIndex -lt $createVoiceIndex) {
	throw "VoiceOnly creation must validate voice before leaving the player's current room"
}

Assert-Contains $server 'local function joinSuccess\(room\)[\s\S]*Success\s*=\s*true' `
	"JoinRoomFunction must return a structured success result"
Assert-Contains $joinHandler 'return joinSuccess\(room\)' `
	"JoinRoomFunction must use the structured success result"

$leaveIndex = $joinHandler.IndexOf("leaveAllRooms(player)")
$passwordIndex = $joinHandler.IndexOf("IncorrectPassword")
$capacityIndex = $joinHandler.IndexOf("RoomFull")
$voiceIndex = $joinHandler.IndexOf("VoiceRequired")
if (
	$leaveIndex -lt 0 -or
	$passwordIndex -lt 0 -or
	$capacityIndex -lt 0 -or
	$voiceIndex -lt 0 -or
	$leaveIndex -lt $passwordIndex -or
	$leaveIndex -lt $capacityIndex -or
	$leaveIndex -lt $voiceIndex
) {
	throw "Password, capacity, and voice checks must all succeed before leaving the current room"
}

Write-Output "room access server regression checks passed"

Assert-Contains $client 'roomPanel:WaitForChild\("Password"\)' `
	"The client must use MainGui.Room.Password"
Assert-Contains $client 'roomPassword:WaitForChild\("UIScale"\)' `
	"The password prompt must use its UIScale"
Assert-Contains $client 'roomPassword:WaitForChild\("TextBox"\)' `
	"The password prompt must submit its TextBox"
Assert-Contains $client 'roomPassword:WaitForChild\("Enter"\)' `
	"The password prompt must use its Enter button"
Assert-Contains $client 'roomFrame:WaitForChild\("Alert"\)' `
	"Room join failures must use Room.Frame.Alert"

foreach ($errorCode in @("IncorrectPassword", "RoomFull", "VoiceRequired", "RoomUnavailable")) {
	Assert-Contains $client ([regex]::Escape($errorCode)) `
		"The client must map the $errorCode failure code"
}

Assert-Contains $client 'joinRoomFunction:InvokeServer\(room\.Name,\s*password\)' `
	"The client must send the entered password to the server"
Assert-Contains $client 'result\.Success\s*==\s*true[\s\S]*typeof\(result\.RoomName\)\s*==\s*"string"' `
	"Malformed success responses must not pass a nil room name to FindFirstChild"
Assert-Contains $client 'roomPasswordTextBox\.FocusLost:Connect\(function\(enterPressed\)' `
	"The password TextBox must submit from Enter"
Assert-Contains $client 'if not enterPressed then' `
	"Losing focus without Enter must not submit a password"
Assert-Contains $client 'roomPasswordEnter\.Activated:Connect\(submitPassword\)' `
	"Clicking the Password.Enter button must submit the password"
Assert-Contains $client 'local function submitPassword\(\)[\s\S]*tween\(roomPasswordScale,\s*\{\s*Scale\s*=\s*0\s*\}\)' `
	"Button and keyboard submissions must share the prompt-closing path"
Assert-Contains $client 'tween\(roomPasswordScale,\s*\{\s*Scale\s*=\s*0\s*\}\)' `
	"Every password submission must hide the prompt"
Assert-Contains $client 'room:GetAttribute\("PasswordEnabled"\)\s*==\s*true\s*then\s*showPasswordPrompt\(room\)' `
	"Clicking a locked room must reveal the password prompt"
Assert-Contains $client 'local function showPasswordPrompt\(room\)[\s\S]*tween\(roomPasswordScale,\s*\{\s*Scale\s*=\s*1\s*\}\)' `
	"The password prompt must tween its UIScale to one"
Assert-Contains $client 'roomAlert\.Text\s*=' `
	"Join failures must write their message to Room.Frame.Alert"
Assert-Contains $client 'local function showRoomAlert\(message\)[\s\S]*tween\(roomAlert,\s*\{[\s\S]*TextTransparency\s*=\s*0' `
	"Room.Frame.Alert must fade in when a join fails"
Assert-Contains $client 'local roomName,\s*createError\s*=\s*createRoomFunction:InvokeServer\(createRoomSettings\)' `
	"VoiceOnly creation failures must be returned to the client"
Assert-Contains $client 'createError[\s\S]*JOIN_ERROR_MESSAGES' `
	"VoiceOnly creation failures must use the room Alert message mapping"

Write-Output "room access client regression checks passed"
