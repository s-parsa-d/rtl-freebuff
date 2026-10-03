param(
  [switch]$Status,
  [switch]$Restart,
  [switch]$Windowless
)

$ErrorActionPreference = 'Continue'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Apply = Join-Path $PSScriptRoot 'apply-windows.ps1'

function Get-Install {
  $candidates = New-Object System.Collections.Generic.List[string]
  $local = $env:LOCALAPPDATA
  foreach ($name in @('Freebuff', 'Freebuff Desktop', 'freebuff', '@codebufffreebuff-desktop')) {
    $candidates.Add((Join-Path $local "Programs\$name")) | Out-Null
    $candidates.Add((Join-Path $env:ProgramFiles $name)) | Out-Null
    $candidates.Add((Join-Path ${env:ProgramFiles(x86)} $name)) | Out-Null
  }
  $squirrel = Join-Path $local 'Freebuff'
  if (Test-Path $squirrel) {
    Get-ChildItem $squirrel -Directory -ErrorAction SilentlyContinue |
      Sort-Object Name -Descending |
      ForEach-Object { $candidates.Add($_.FullName) | Out-Null }
  }
  foreach ($c in $candidates) {
    if ($c -and (Test-Path (Join-Path $c 'resources\orchestrator\ui\index.html'))) { return $c }
  }
  return $null
}

function Get-Exe($dir) {
  if (-not $dir -or -not (Test-Path $dir)) { return $null }
  $exe = Get-ChildItem $dir -Filter '*.exe' -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match 'freebuff' } |
    Sort-Object Length -Descending | Select-Object -First 1
  if ($exe) { return $exe.FullName }
  return $null
}

$install = Get-Install
if (-not $install) {
  Write-Host 'Freebuff not found — if it is installed elsewhere, first run apply-windows.ps1 -Root <dir>.' -ForegroundColor Yellow
  exit 1
}
$exe = Get-Exe $install

if ($Status) {
  Write-Host "Install    : $install"
  if ($exe) { Write-Host "Executable : $exe" }
  & $Apply -Root $install -Check -Quiet | Out-Null
  if ($LASTEXITCODE -eq 0) { Write-Host 'RTL patch : applied ✅' } else { Write-Host 'RTL patch : not applied' }
  $proc = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path -like "$install*" }
  if ($proc) { Write-Host 'Running    : yes' } else { Write-Host 'Running    : no' }
  exit 0
}

if ($Restart) {
  $proc = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path -like "$install*" }
  if ($proc) {
    Write-Host 'Closing the running instance…'
    $proc | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
  }
}

& $Apply -Root $install -Check -Quiet | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host 'RTL patch missing — building it…'
  & $Apply -Root $install -Quiet
}

if (-not $exe) { Write-Host 'App executable not found.' -ForegroundColor Yellow; exit 1 }
Start-Process -FilePath $exe
