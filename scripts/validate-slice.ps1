$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$failures = @()

function Assert-File($path) {
    if (-not (Test-Path $path)) {
        $script:failures += "Missing file: $path"
    }
}

$assets = @(
    "assets\system\launchImage.png",
    "assets\images\bg\titleBGAnim-table-400-391.png",
    "assets\images\bg\tarot_playspace.png",
    "assets\images\bg\darkcloth.png",
    "assets\images\bg\dinahBG-table-400-266.png",
    "assets\images\decknback\placementzone_diamond.png",
    "assets\images\textscroll\scroll1c.png",
    "assets\images\shuffleAnimation\1_card_shuffle-table-400-240.png",
    "assets\images\shuffleAnimation\card_spin_slide-table-400-240.png",
    "assets\images\shuffleAnimation\deck_laying_full_lower-table-400-240.png",
    "assets\images\shuffleAnimation\explode_finale-table-400-240.png",
    "assets\images\shuffleAnimation\reveal-table-236-342.png",
    "assets\fonts\tarotheque-v2-20-atlas.png",
    "assets\fonts\tarotheque-v2-20.xml",
    "assets\sound\cards2_slow.wav",
    "assets\sound\a_but1.wav"
)

foreach ($asset in $assets) {
    Assert-File (Join-Path $root $asset)
}

$cardData = Get-Content (Join-Path $root "src\game\data\cardData.ts") -Raw
if ($cardData -notmatch '"The Fool"') {
    $failures += "cardData.ts missing The Fool"
}

$cardMatches = [regex]::Matches($cardData, '^\s+"[^"]+": \{$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
if ($cardMatches.Count -ne 78) {
    $failures += "Expected 78 cards in cardData.ts, found $($cardMatches.Count)"
}

$srcFiles = @(
    "src\main.ts",
    "src\game\Game.ts",
    "src\game\scenes\BootScene.ts",
    "src\game\scenes\TitleScene.ts",
    "src\game\scenes\OneCardGameScene.ts",
    "src\game\scenes\OneCardPostScene.ts"
)
foreach ($file in $srcFiles) {
    Assert-File (Join-Path $root $file)
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "FAIL: $_" }
    exit 1
}

Write-Host "Validation passed: assets, card data, and source files look good."
Write-Host "Run 'npm install && npm run dev' for interactive browser testing."
