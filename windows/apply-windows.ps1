param(
  [string]$Root,
  [string]$Install,
  [switch]$Check,
  [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$PatchDir = Join-Path $RepoRoot 'patch'
$CssHref = './freebuff-rtl.css'
$JsSrc = './freebuff-rtl.js'

function Say($msg) { if (-not $Quiet) { Write-Host $msg } }

function Test-UiDir($dir) {
  if (-not $dir) { return $false }
  return (Test-Path (Join-Path $dir 'orchestrator\ui\index.html'))
}

function Get-Candidates {
  $list = New-Object System.Collections.Generic.List[string]
  if ($Root) { $list.Add($Root) | Out-Null; $list.Add((Join-Path $Root 'resources')) | Out-Null }
  $local = $env:LOCALAPPDATA
  foreach ($name in @('Freebuff', 'Freebuff Desktop', 'freebuff', '@codebufffreebuff-desktop')) {
    $list.Add((Join-Path $local "Programs\$name\resources")) | Out-Null
    $list.Add((Join-Path $local "Programs\$name")) | Out-Null
    $list.Add((Join-Path $env:ProgramFiles "$name\resources")) | Out-Null
    $list.Add((Join-Path ${env:ProgramFiles(x86)} "$name\resources")) | Out-Null
  }
  $squirrel = Join-Path $local 'Freebuff'
  if (Test-Path $squirrel) {
    Get-ChildItem $squirrel -Directory -ErrorAction SilentlyContinue | ForEach-Object {
      $list.Add((Join-Path $_.FullName 'resources')) | Out-Null
    }
  }
  $programs = Join-Path $local 'Programs'
  if (Test-Path $programs) {
    Get-ChildItem $programs -Directory -ErrorAction SilentlyContinue | Where-Object {
      $_.Name -match 'freebuff'
    } | ForEach-Object {
      $list.Add($_.FullName) | Out-Null
      $list.Add((Join-Path $_.FullName 'resources')) | Out-Null
    }
  }
  return $list
}

function Resolve-UiDir {
  foreach ($c in Get-Candidates) {
    if (Test-UiDir $c) { return $c }
  }
  return $null
}

if ($Install) {
  if (-not (Test-Path $Install)) { throw "not found: $Install" }
  $sevenZip = @(
    "$env:ProgramFiles\7-Zip\7z.exe",
    "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
    (Get-Command 7z -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
  ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
  if (-not $sevenZip) { throw '7-Zip not found — install 7-Zip, or install Freebuff normally and run this script without -Install.' }
  $work = Join-Path $env:TEMP ("fbrtl-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
  New-Item -ItemType Directory -Path $work | Out-Null
  Say "unpacking $Install …"
  & $sevenZip x -y -o"$work" $Install | Out-Null
  $inner = Get-ChildItem $work -Recurse -Filter 'app-*.7z' -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($inner) { & $sevenZip x -y -o"$work\app" $inner.FullName | Out-Null }
  $Root = if ($inner) { "$work\app\resources" } else { $work }
  Say "unpacked to $Root — patch it, then install normally (the launcher keeps it patched)."
}

$uiRoot = Resolve-UiDir
if (-not $uiRoot) {
  Write-Error 'Freebuff not found. Pass -Root <install dir>, e.g. "$env:LOCALAPPDATA\Programs\Freebuff".'
  exit 1
}
$ui = Join-Path $uiRoot 'orchestrator\ui'
$idx = Join-Path $ui 'index.html'

function Test-Patched {
  if (-not (Test-Path (Join-Path $ui 'freebuff-rtl.css'))) { return $false }
  if (-not (Test-Path (Join-Path $ui 'freebuff-rtl.js'))) { return $false }
  if (-not (Test-Path (Join-Path $ui 'fonts\freebuff-rtl\Vazirmatn-Regular.woff2'))) { return $false }
  $html = Get-Content -Raw -LiteralPath $idx
  return ($html -match 'freebuff-rtl\.css' -and $html -match 'freebuff-rtl\.js')
}

if ($Check) {
  if (Test-Patched) { Say "patched:     $uiRoot"; exit 0 } else { Say "not patched: $uiRoot"; exit 1 }
}

if (-not (Test-Patched)) {
  Say "patching $uiRoot"
  Copy-Item (Join-Path $PatchDir 'rtl.css') (Join-Path $ui 'freebuff-rtl.css') -Force
  Copy-Item (Join-Path $PatchDir 'rtl.js') (Join-Path $ui 'freebuff-rtl.js') -Force
  $fontDir = Join-Path $ui 'fonts\freebuff-rtl'
  New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
  Copy-Item (Join-Path $PatchDir 'fonts\*.woff2') $fontDir -Force

  $html = Get-Content -Raw -LiteralPath $idx
  $html = [regex]::Replace($html, '\s*<link[^>]*freebuff-rtl\.css[^>]*/>', '')
  $html = [regex]::Replace($html, '\s*<script[^>]*freebuff-rtl\.js[^>]*></script>', '')
  $tags = "    <link rel=`"stylesheet`" href=`"$CssHref`" />`r`n    <script defer src=`"$JsSrc`"></script>`r`n  "
  $html = ([regex]'(?i)</head>').Replace($html, ($tags + '</head>'), 1)
  [System.IO.File]::WriteAllText($idx, $html, (New-Object System.Text.UTF8Encoding($false)))
}

if (-not (Test-Patched)) { Write-Error 'patch verification failed'; exit 1 }
Say "done: $uiRoot"
Say 'If Freebuff is open, close it and launch via the "Freebuff RTL" shortcut.'
