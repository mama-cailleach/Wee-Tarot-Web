$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$contentDir = Join-Path $root "content\data"
$deckDir = Join-Path $root "reference\playdate\scripts\decks"
$outDir = Join-Path $root "src\game\data"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Parse-StringArrayFromBlock {
    param([string]$Block, [string]$FieldName)
    $pattern = [regex]::Escape($FieldName) + '\s*=\s*\{([^}]*)\}'
    $match = [regex]::Match($Block, $pattern)
    if (-not $match.Success) { return @() }
    return [regex]::Matches($match.Groups[1].Value, '"([^"]*)"') | ForEach-Object { $_.Groups[1].Value }
}

function Parse-DeckArray {
    param([string]$Path, [string]$GlobalName)
    $content = Get-Content $Path -Raw
    $pattern = [regex]::Escape($GlobalName) + '\s*=\s*\{([^}]*)\}'
    $match = [regex]::Match($content, $pattern)
    if (-not $match.Success) { throw "Could not parse deck array in $Path" }
    return [regex]::Matches($match.Groups[1].Value, '"([^"]*)"') | ForEach-Object { $_.Groups[1].Value.Trim() }
}

function Parse-CardDataFile {
    param([string]$Path)
    $content = Get-Content $Path -Raw
    $cards = [ordered]@{}
    $pattern = '\["([^"]+)"\]\s*=\s*\{'
    $matches = [regex]::Matches($content, $pattern)
    for ($i = 0; $i -lt $matches.Count; $i++) {
        $name = $matches[$i].Groups[1].Value
        $start = $matches[$i].Index + $matches[$i].Length
        $end = if ($i + 1 -lt $matches.Count) { $matches[$i + 1].Index } else { $content.LastIndexOf('}') }
        $block = $content.Substring($start, $end - $start)
        $card = [ordered]@{
            upright_keywords = @(Parse-StringArrayFromBlock $block 'upright_keywords')
            reversed_keywords = @(Parse-StringArrayFromBlock $block 'reversed_keywords')
            upright_fortune = @(Parse-StringArrayFromBlock $block 'upright_fortune')
            reversed_fortune = @(Parse-StringArrayFromBlock $block 'reversed_fortune')
        }
        $correspondence = @(Parse-StringArrayFromBlock $block 'correspondence')
        if ($correspondence.Count -gt 0) {
            $card['correspondence'] = $correspondence
        }
        $cards[$name] = $card
    }
    return $cards
}

function ConvertTo-Js {
    param($Value, [int]$Indent = 0)
    $pad = '  ' * $Indent
    $padInner = '  ' * ($Indent + 1)
    if ($null -eq $Value) { return 'null' }
    if ($Value -is [string]) { return '"' + ($Value -replace '\\', '\\\\' -replace '"', '\"') + '"' }
    if ($Value -is [bool]) { return $Value.ToString().ToLower() }
    if ($Value -is [int] -or $Value -is [double]) { return $Value.ToString() }
    if ($Value -is [array]) {
        if ($Value.Count -eq 0) { return '[]' }
        $items = $Value | ForEach-Object { "$padInner$(ConvertTo-Js $_ ($Indent + 1))" }
        return "[`n$($items -join ",`n")`n$pad]"
    }
    if ($Value -is [System.Collections.IDictionary]) {
        $entries = @()
        foreach ($key in $Value.Keys) {
            $entries += "$padInner$(ConvertTo-Js $key 0): $(ConvertTo-Js $Value[$key] ($Indent + 1))"
        }
        if ($entries.Count -eq 0) { return '{}' }
        return "{`n$($entries -join ",`n")`n$pad}"
    }
    return '"' + $Value + '"'
}

$allCards = [ordered]@{}
$files = @(
    'cardDescriptionsMajor.lua',
    'cardDescriptionsWands.lua',
    'cardDescriptionsCups.lua',
    'cardDescriptionsSwords.lua',
    'cardDescriptionsPentacles.lua'
)
foreach ($file in $files) {
    $parsed = Parse-CardDataFile (Join-Path $contentDir $file)
    foreach ($key in $parsed.Keys) {
        $allCards[$key] = $parsed[$key]
    }
}

$deckNames = [ordered]@{
    majorArcana = @(Parse-DeckArray (Join-Path $deckDir 'majorArcana.lua') 'majorArcanaDeck')
    cups = @(Parse-DeckArray (Join-Path $deckDir 'cups.lua') 'cupsDeck')
    wands = @(Parse-DeckArray (Join-Path $deckDir 'wands.lua') 'wandsDeck')
    swords = @(Parse-DeckArray (Join-Path $deckDir 'swords.lua') 'swordsDeck')
    pentacles = @(Parse-DeckArray (Join-Path $deckDir 'pentacles.lua') 'pentaclesDeck')
}

$typesTs = @'
// AUTO-GENERATED — run scripts/export-content.ps1 or npm run export:data

export interface CardInfo {
  correspondence?: string[];
  upright_keywords: string[];
  reversed_keywords: string[];
  upright_fortune: string[];
  reversed_fortune: string[];
}

export type CardDataMap = Record<string, CardInfo>;

export interface ReadingResult {
  cardName: string;
  cardNumber: number;
  cardSuit: number;
  inverted: boolean;
}
'@

$cardDataTs = @"
// AUTO-GENERATED — run scripts/export-content.ps1 or npm run export:data

import type { CardDataMap } from "./types";

export const CARD_DATA: CardDataMap = $(ConvertTo-Js $allCards 0) as CardDataMap;
"@

$deckNamesTs = @"
// AUTO-GENERATED — run scripts/export-content.ps1 or npm run export:data

export const SUIT_FOLDERS = ["cups", "wands", "swords", "pentacles", "majorArcana"] as const;

export const DECK_NAMES = $(ConvertTo-Js $deckNames 0) as const;
"@

Set-Content -Path (Join-Path $outDir 'types.ts') -Value $typesTs -Encoding utf8
Set-Content -Path (Join-Path $outDir 'cardData.ts') -Value $cardDataTs -Encoding utf8
Set-Content -Path (Join-Path $outDir 'deckNames.ts') -Value $deckNamesTs -Encoding utf8

Write-Host "Exported $($allCards.Count) cards to $outDir"
