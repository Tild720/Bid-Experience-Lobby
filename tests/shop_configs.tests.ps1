$ErrorActionPreference = "Stop"

function Get-ConfigEntries($path) {
	$content = Get-Content -Raw $path
	$pattern = '\{\s*Name\s*=\s*"([^"]+)"\s*,\s*ModelName\s*=\s*"([^"]+)"\s*,\s*Price\s*=\s*(\d+)\s*,?\s*\}'
	$unmatchedContent = [regex]::Replace($content, $pattern, "")

	if ($unmatchedContent -notmatch '^\s*return\s*\{\s*(?:,\s*)*\}\s*$') {
		throw "$path must only return entries containing Name, ModelName, and Price"
	}

	return [regex]::Matches($content, $pattern) | ForEach-Object {
		[pscustomobject]@{
			Name = $_.Groups[1].Value
			ModelName = $_.Groups[2].Value
			Price = [int]$_.Groups[3].Value
		}
	}
}

function Assert-Config($path, $expectedEntries) {
	if (-not (Test-Path -LiteralPath $path)) {
		throw "Missing shop config: $path"
	}

	$actualEntries = @(Get-ConfigEntries $path)
	if ($actualEntries.Count -ne $expectedEntries.Count) {
		throw "$path has $($actualEntries.Count) entries; expected $($expectedEntries.Count)"
	}

	for ($index = 0; $index -lt $expectedEntries.Count; $index++) {
		$actual = $actualEntries[$index]
		$expected = $expectedEntries[$index]

		foreach ($property in @("Name", "ModelName", "Price")) {
			if ($actual.$property -ne $expected.$property) {
				throw "$path entry $index has $property '$($actual.$property)'; expected '$($expected.$property)'"
			}
		}
	}
}

$trailEntries = @(
	@{ Name = "Default Blue"; ModelName = "DefaultBlue"; Price = 1500 }
	@{ Name = "Default Green"; ModelName = "DefaultGreen"; Price = 1750 }
	@{ Name = "Default Red"; ModelName = "DefaultRed"; Price = 2000 }
	@{ Name = "Default White"; ModelName = "DefaultWhite"; Price = 2250 }
	@{ Name = "Default Yellow"; ModelName = "DefaultYellow"; Price = 2500 }
	@{ Name = "Blue Slash"; ModelName = "BlueSlash"; Price = 6000 }
	@{ Name = "Red Slash"; ModelName = "RedSlash"; Price = 7500 }
	@{ Name = "White Slash"; ModelName = "WhiteSlash"; Price = 9000 }
	@{ Name = "Blue Blink"; ModelName = "BlinkBlue"; Price = 18000 }
	@{ Name = "Red Blink"; ModelName = "BlinkRed"; Price = 20000 }
	@{ Name = "Void"; ModelName = "Void"; Price = 22000 }
	@{ Name = "Shaking Void"; ModelName = "ShakingVoid"; Price = 25000 }
)

$signSkinEntries = @(
	@{ Name = "For Sale"; ModelName = "ForSaleSign"; Price = 1500 }
	@{ Name = "Danger"; ModelName = "DangerSign"; Price = 2500 }
	@{ Name = "Gold"; ModelName = "GoldSign"; Price = 6000 }
	@{ Name = "Future"; ModelName = "FutureSign"; Price = 9000 }
	@{ Name = "TV"; ModelName = "TVSign"; Price = 20000 }
)

Assert-Config "src/ReplicatedStorage/Modules/TrailConfig.lua" $trailEntries
Assert-Config "src/ReplicatedStorage/Modules/SignSkinConfig.lua" $signSkinEntries

Write-Output "shop config regression checks passed"
