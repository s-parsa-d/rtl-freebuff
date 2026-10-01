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
  Write-Host 'Freebuff پیدا نشد — اگر جای دیگری نصب است، اول apply-windows.ps1 -Root <dir> را اجرا کن.' -ForegroundColor Yellow
  exit 1
}
$exe = Get-Exe $install

if ($Status) {
  Write-Host "نصب      : $install"
  if ($exe) { Write-Host "فایل اجرا: $exe" }
  & $Apply -Root $install -Check -Quiet | Out-Null
  if ($LASTEXITCODE -eq 0) { Write-Host 'پچ فارسی: اعمال‌شده ✅' } else { Write-Host 'پچ فارسی: اعمال‌نشده' }
  $proc = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path -like "$install*" }
  if ($proc) { Write-Host 'در حال اجرا: بله' } else { Write-Host 'در حال اجرا: نه' }
  exit 0
}

if ($Restart) {
  $proc = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path -like "$install*" }
  if ($proc) {
    Write-Host 'بستن نسخهٔ باز…'
    $proc | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
  }
}

& $Apply -Root $install -Check -Quiet | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host 'پچ فارسی ساخته نشده — ساخته می‌شود…'
  & $Apply -Root $install -Quiet
}

if (-not $exe) { Write-Host 'فایل اجرایی اپ پیدا نشد.' -ForegroundColor Yellow; exit 1 }
Start-Process -FilePath $exe
