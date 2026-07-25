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
Assert-Contains $server 'game:GetService\("LocalizationService"\)' `
	"Room names must resolve the owner's country through LocalizationService"
Assert-Contains $server 'GetCountryRegionForPlayerAsync\(player\)' `
	"Room names must use the player's country/region code"
Assert-Contains $server 'pcall\(function\(\)[\s\S]*GetCountryRegionForPlayerAsync' `
	"Country lookup failures must not block room creation or joining"
Assert-Contains $server 'utf8\.char' `
	"Two-letter country codes must be converted to regional-indicator flag emoji"
Assert-Contains $server 'local DEFAULT_COUNTRY_FLAG = "🌐"' `
	"Country lookup failures must use the globe fallback"
Assert-Contains $server 'local function formatRoomName\(ownerName,\s*countryFlag\)[\s\S]*Room \{countryFlag\}' `
	"Room names must end with one space followed by the country emoji"
Assert-Contains $server 'member:SetAttribute\("CountryFlag",\s*countryFlag(?:\s+or\s+DEFAULT_COUNTRY_FLAG)?\)' `
	"Room members must retain their flag for ownership transfer"
Assert-Contains $server 'formatRoomName\(newOwner:GetAttribute\("Name"\),\s*newOwner:GetAttribute\("CountryFlag"\)\)' `
	"Ownership transfer must rebuild the room name with the new owner's flag"

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
$createCountryIndex = $createHandler.IndexOf("getCountryFlag(player)")
if (
	$createLeaveIndex -lt 0 -or
	$createVoiceIndex -lt 0 -or
	$createCountryIndex -lt 0 -or
	$createLeaveIndex -lt $createVoiceIndex -or
	$createLeaveIndex -lt $createCountryIndex
) {
	throw "Voice and country lookups must finish before room creation leaves the player's current room"
}

Assert-Contains $server 'local function joinSuccess\(room\)[\s\S]*Success\s*=\s*true' `
	"JoinRoomFunction must return a structured success result"
Assert-Contains $joinHandler 'return joinSuccess\(room\)' `
	"JoinRoomFunction must use the structured success result"

$leaveIndex = $joinHandler.IndexOf("leaveAllRooms(player)")
$passwordIndex = $joinHandler.IndexOf("IncorrectPassword")
$capacityIndex = $joinHandler.IndexOf("RoomFull")
$voiceIndex = $joinHandler.IndexOf("VoiceRequired")
$countryIndex = $joinHandler.IndexOf("getCountryFlag(player)")
if (
	$leaveIndex -lt 0 -or
	$passwordIndex -lt 0 -or
	$capacityIndex -lt 0 -or
	$voiceIndex -lt 0 -or
	$countryIndex -lt 0 -or
	$leaveIndex -lt $passwordIndex -or
	$leaveIndex -lt $capacityIndex -or
	$leaveIndex -lt $voiceIndex -or
	$leaveIndex -lt $countryIndex
) {
	throw "Password, capacity, voice, and country checks must all finish before leaving the current room"
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
Assert-Contains $client 'roomPassword\.Visible\s*=\s*false' `
	"The password prompt must be fully hidden by default"
Assert-Contains $client 'local function hidePasswordPrompt\(shouldTween\)[\s\S]*Completed:Once[\s\S]*roomPassword\.Visible\s*=\s*false' `
	"The password prompt must become invisible after its scale-out finishes"
Assert-Contains $client 'local function showPasswordPrompt\(room\)[\s\S]*roomPassword\.Visible\s*=\s*true[\s\S]*Scale\s*=\s*1' `
	"Only selecting a password-protected room may reveal the password prompt"
Assert-Contains $client 'roomFrame:WaitForChild\("Alert"\)' `
	"Room join failures must use Room.Frame.Alert"
Assert-Contains $client 'local roomPasswordTexts = \{\}' `
	"The room details panel must track all of its Password text objects"
Assert-Contains $client 'for _,\s*instance in roomFrame:GetDescendants\(\) do' `
	"The room details panel must inspect Studio-authored descendant text objects"
Assert-Contains $client 'string\.find\(string\.lower\(instance\.Name\),\s*"password"' `
	"Password text discovery must support names such as PasswordText"
Assert-Contains $client 'local text = string\.lower\(instance\.Text\)[\s\S]*string\.find\(text,\s*"password"' `
	"Password text discovery must support generic TextLabel names"
Assert-Contains $client 'for _,\s*passwordText in roomPasswordTexts do[\s\S]*passwordText\.Visible\s*=\s*room:GetAttribute\("PasswordEnabled"\)\s*==\s*true' `
	"Every room details Password text must stay hidden for rooms without passwords"
Assert-Contains $client 'local function showRoomPanel\(room,\s*password\)[\s\S]*roomPanel:SetAttribute\("CurrentPassword",\s*password\s+or\s+""\)[\s\S]*updateRoomPanel\(room\)' `
	"The room panel must retain the password supplied by its current member"
Assert-Contains $client 'local function updateRoomPanel\(room\)[\s\S]*roomFrame:FindFirstChild\("Password"\)[\s\S]*passwordText\.Text\s*=\s*`PASSWORD : \{roomPanel:GetAttribute\("CurrentPassword"\)\s+or\s+""\}`' `
	"Room.Frame.Password must display PASSWORD : followed by the current room password"
Assert-Contains $client 'showRoomPanel\(joinedRoom,\s*password\)' `
	"A player who joins must see the password they submitted"
Assert-Contains $client 'showRoomPanel\(\s*room,\s*if createRoomSettings\.CreateRoomPasswordEnabled then createRoomSettings\.CreateRoomPassword else nil\s*\)' `
	"A room creator must see the password used to create the room"
Assert-Contains $client 'local function updateRoomPanel\(room\)[\s\S]*room:GetAttribute\("OwnerUserId"\)[\s\S]*roomFrame:FindFirstChild\("Icon"\)' `
	"Room.Frame.Icon must use the current room owner"
Assert-Contains $client 'rbxthumb://type=AvatarHeadShot&id=\{ownerUserId\}&w=420&h=420' `
	"Room.Frame.Icon must request the current owner's 420x420 Avatar HeadShot"
Assert-Contains $client 'local function updateRoomCard\(room,\s*card\)[\s\S]*room:GetAttribute\("OwnerUserId"\)[\s\S]*card:FindFirstChild\("Icon",\s*true\)[\s\S]*rbxthumb://type=AvatarHeadShot&id=\{ownerUserId\}&w=420&h=420' `
	"Each cloned UIObjects.Room card must show the current owner's 420x420 Avatar HeadShot"
Assert-Contains $server 'room:SetAttribute\("OwnerUserId",\s*newOwner:GetAttribute\("UserId"\)\)[\s\S]*formatRoomName\(newOwner:GetAttribute\("Name"\)' `
	"Ownership transfer must update both the current owner id and room name"
Assert-Contains $server 'leaveRoomEvent\.OnServerEvent:Connect\(function\(player,\s*roomName\)[\s\S]*room:GetAttribute\("Starting"\)\s*~=\s*true[\s\S]*leaveRoom\(room,\s*player\)' `
	"Players must not leave through LeaveRoomEvent after an auction starts"

$startHandler = [regex]::Match(
	$server,
	'startRoomEvent\.OnServerEvent:Connect\(function\(player,\s*roomName\)[\s\S]*?Players\.PlayerRemoving'
).Value
Assert-Contains $startHandler 'room:GetAttribute\("Starting"\)\s*==\s*true' `
	"StartAuction must ignore a room that is already starting"
Assert-Contains $startHandler 'room:SetAttribute\("Starting",\s*true\)[\s\S]*pcall\(function\(\)[\s\S]*TeleportService:TeleportPartyAsync' `
	"StartAuction must lock the room before teleporting"
Assert-Contains $startHandler 'if not teleportSucceeded[\s\S]*room:SetAttribute\("Starting",\s*false\)' `
	"A failed teleport must unlock the room"
Assert-Contains $client 'local function updateRoomPanel\(room\)[\s\S]*local isStarting\s*=\s*room:GetAttribute\("Starting"\)\s*==\s*true[\s\S]*roomBack\.Visible\s*=\s*not isStarting[\s\S]*roomBack\.Interactable\s*=\s*not isStarting' `
	"Room.Back must be hidden and disabled while StartAuction is running"
Assert-Contains $client 'roomBack\.Activated:Connect\(function\(\)[\s\S]*currentRoom:GetAttribute\("Starting"\)\s*==\s*true[\s\S]*return' `
	"Room.Back must refuse activation after StartAuction begins"

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
Assert-Contains $client 'local function submitPassword\(\)[\s\S]*hidePasswordPrompt\(true\)' `
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
Assert-Contains $client 'local function resetCreateRoomPassword\(\)[\s\S]*CreateRoomPasswordEnabled\s*=\s*false[\s\S]*CreateRoomPassword\s*=\s*""[\s\S]*createRoomPasswordLabel\.Text\s*=\s*"X"[\s\S]*createRoomPasswordTextBox\.Text\s*=\s*""[\s\S]*createRoomPasswordTextBox\.Visible\s*=\s*false' `
	"Opening CreateRoom must clear every stale password setting"
Assert-Contains $client 'mainGui:WaitForChild\("Play"\):WaitForChild\("CreateRoom"\)\.Activated:Connect\(function\(\)[\s\S]*resetCreateRoomPassword\(\)[\s\S]*revealCreateRoomPanel\(\)' `
	"The CreateRoom button must reset password state before showing the panel"

Write-Output "room access client regression checks passed"
