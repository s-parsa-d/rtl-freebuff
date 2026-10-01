<#
  Freebuff RTL — Windows shortcuts

    .\windows\install-shortcut.ps1               Desktop + Start Menu shortcut
    .\windows\install-shortcut.ps1 -NoDesktop    Start Menu only
    .\windows\install-shortcut.ps1 -Remove       delete both

  The shortcut starts windows\launch-windows.ps1 hidden, which re-applies the
  patch whenever a Freebuff update removed it. Its icon is the app's own icon,
  so it looks like a normal Freebuff shortcut.
#>
param(
  [switch]$NoDesktop,
  [switch]$Remove
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Launcher = Join-Path $PSScriptRoot 'launch-windows.ps1'
$Name = 'Freebuff (فارسی)'

$desktop = [Environment]::GetFolderPath('Desktop')
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$targets = @((Join-Path $startMenu "$Name.lnk"))
if (-not $NoDesktop) { $targets += (Join-Path $desktop "$Name.lnk") }

if ($Remove) {
  foreach ($t in $targets) { Remove-Item $t -Force -ErrorAction SilentlyContinue }
  Write-Host "حذف شد: $($targets -join ', ')"
  exit 0
}

# آیکن: از خود فایل اجرایی اپ
$icon = "$env:SystemRoot\System32\shell32.dll,0"
$install = $null
foreach ($c in @(
    (Join-Path $env:LOCALAPPDATA 'Programs\Freebuff'),
    (Join-Path $env:ProgramFiles 'Freebuff'),
    (Join-Path ${env:ProgramFiles(x86)} 'Freebuff')
  )) {
  if ($c -and (Test-Path (Join-Path $c 'resources\orchestrator\ui\index.html'))) { $install = $c; break }
}
if ($install) {
  $exe = Get-ChildItem $install -Filter '*.exe' -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match 'freebuff' } | Sort-Object Length -Descending | Select-Object -First 1
  if ($exe) { $icon = $exe.FullName + ',0' }
}

$powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$Launcher`" -Windowless"

$shell = New-Object -ComObject WScript.Shell
foreach ($t in $targets) {
  $dir = Split-Path -Parent $t
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $sc = $shell.CreateShortcut($t)
  $sc.TargetPath = $powershell
  $sc.Arguments = $arguments
  $sc.WorkingDirectory = $RepoRoot
  $sc.IconLocation = $icon
  $sc.Description = 'Freebuff با فونت فارسی و راست‌چین‌سازی چت'
  $sc.Save()
  Write-Host "ساخته شد: $t"
}
Write-Host 'از این به بعد اپ را از همین میانبر اجرا کن تا پچ بعد از آپدیت هم بماند.'
