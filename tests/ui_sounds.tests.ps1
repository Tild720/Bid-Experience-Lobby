$ErrorActionPreference = "Stop"

$client = Get-Content -Raw "src/StarterPlayerScripts/MenuTitleEffects.client.lua"
$soundsModulePath = "src/ReplicatedStorage/Modules/MenuSounds.lua"
if (-not (Test-Path -LiteralPath $soundsModulePath)) {
	throw "MenuSounds must be isolated from the main LocalScript to stay below Luau's 200-register limit"
}
$soundsModule = Get-Content -Raw $soundsModulePath

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

foreach ($soundName in @(
	"FadeTransitionOnce",
	"BGM",
	"JoinRoom",
	"Purchase",
	"Click",
	"GameStartAndCreateRoom"
)) {
	Assert-Contains $soundsModule ('SoundService:FindFirstChild\("' + $soundName + '"\)') `
		"MenuSounds must resolve the $soundName sound from SoundService"
}

Assert-Contains $client 'require\(modules:WaitForChild\("MenuSounds"\)\)\(mainGui\)' `
	"The client must initialize its isolated sound controller"
Assert-Contains $soundsModule 'local function playNamedSound\(soundName\)[\s\S]*TimePosition\s*=\s*0[\s\S]*sound:Play\(\)' `
	"One-shot sounds must restart cleanly when actions happen quickly"
Assert-Contains $soundsModule 'bgm\.Looped\s*=\s*true[\s\S]*if not bgm\.Playing then[\s\S]*bgm:Play\(\)' `
	"BGM must loop without restarting an already playing track"
Assert-Contains $soundsModule 'local function bindClickSound\(instance\)[\s\S]*instance:IsA\("GuiButton"\)[\s\S]*instance\.Activated:Connect[\s\S]*playNamedSound\("Click"\)' `
	"Every actionable GUI button must receive immediate click feedback"
Assert-Contains $soundsModule 'local function bindClickSound\(instance\)[\s\S]*instance\.Name\s*==\s*"AddSoon"[\s\S]*return' `
	"AddSoon must remain completely inert, including producing no click sound"
Assert-Contains $soundsModule 'for _,\s*instance in mainGui:GetDescendants\(\) do[\s\S]*bindClickSound\(instance\)[\s\S]*mainGui\.DescendantAdded:Connect\(bindClickSound\)' `
	"Dynamically cloned room and shop buttons must also receive click feedback"

$topLevelLocalCount = [regex]::Matches($client, '(?m)^local\s+').Count
if ($topLevelLocalCount -gt 198) {
	throw "MenuTitleEffects has $topLevelLocalCount top-level locals; keep it below the Luau register limit"
}

$joinFunction = [regex]::Match(
	$client,
	'local function requestJoin\(room,\s*password\)[\s\S]*?local function submitPassword'
).Value
Assert-Contains $joinFunction 'result\.Success\s*==\s*true[\s\S]*playNamedSound\("JoinRoom"\)[\s\S]*showRoomPanel\(joinedRoom,\s*password\)' `
	"A player must hear JoinRoom only after their room join succeeds"

$roomPanelFunction = [regex]::Match(
	$client,
	'local function showRoomPanel\(room,\s*password\)[\s\S]*?local function requestJoin'
).Value
Assert-Contains $roomPanelFunction 'members\.ChildAdded:Connect\(function\(member\)[\s\S]*member:GetAttribute\("UserId"\)\s*~=\s*player\.UserId[\s\S]*playNamedSound\("JoinRoom"\)' `
	"Players already in a room must hear JoinRoom when another player enters"

$purchaseHandler = [regex]::Match(
	$client,
	'actionButton\.Activated:Connect\(function\(\)[\s\S]*?\n\tend\)\nend'
).Value
Assert-Contains $purchaseHandler 'result\.Status\s*==\s*"Purchased"[\s\S]*playNamedSound\("Purchase"\)' `
	"Cosmetic purchases must play Purchase only after server-confirmed success"
Assert-Contains $client 'purchaseAlert\.OnClientEvent:Connect\(function\(message\)[\s\S]*playNamedSound\("Purchase"\)' `
	"Developer product fulfillment must play Purchase"

Assert-Contains $client 'if room then[\s\S]*playNamedSound\("GameStartAndCreateRoom"\)[\s\S]*showRoomPanel\(\s*room,' `
	"Successful room creation must play GameStartAndCreateRoom"
Assert-Contains $client 'roomStart\.Activated:Connect\(function\(\)[\s\S]*playNamedSound\("GameStartAndCreateRoom"\)[\s\S]*startRoomEvent:FireServer' `
	"Starting a ready room must play GameStartAndCreateRoom"
Assert-Contains $client 'game:GetService\("LocalizationService"\)' `
	"Main menu hover labels must use the Roblox locale"
Assert-Contains $client 'local isKoreanLocale\s*=\s*string\.match\(string\.lower\(game:GetService\("LocalizationService"\)\.RobloxLocaleId\),\s*"\^ko"\)' `
	"Korean locale detection must accept Roblox locale variants such as ko-kr"
Assert-Contains $client 'addButtonEffects\(playButton,\s*if isKoreanLocale then "> 플레이" else "> Play",\s*"Play"' `
	"Play hover text must be localized for Korean players"
Assert-Contains $client 'addButtonEffects\(shopButton,\s*if isKoreanLocale then "> 상점" else "> Shop",\s*"Shop"' `
	"Shop hover text must be localized for Korean players"

$fadeSoundCount = [regex]::Matches($client, 'playNamedSound\("FadeTransitionOnce"\)').Count
if ($fadeSoundCount -lt 8) {
	throw "Major menu, room, category, and money-shop transitions must play FadeTransitionOnce"
}

Write-Output "UI sound regression checks passed"
