param(
    [string]$Version = '1.2.0',
    [string]$Compiler
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $root

$payload = Join-Path $root 'dist\BoltDM-windows-amd64'
foreach ($required in @('BoltDM.exe', 'BoltDM-Launcher.exe', 'BoltDM.ico',
                         'BoltDM-Companion\manifest.json', 'BoltDM-Companion\icons\icon128.png')) {
    if (-not (Test-Path -LiteralPath (Join-Path $payload $required))) {
        throw "Missing installer payload: $required. Build and package Windows first."
    }
}

if (-not $Compiler) {
    $paths = @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
    )
    $Compiler = $paths | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if (-not $Compiler) {
    throw 'Inno Setup 6 is not installed. Install it or pass -Compiler <ISCC.exe>.'
}
& $Compiler "/DAppVersion=$Version" 'BoltDM.iss'
if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed: $LASTEXITCODE" }

$output = Join-Path $root 'dist\BoltDM-Setup-windows-amd64.exe'
if (-not (Test-Path -LiteralPath $output)) { throw 'Installer output missing.' }
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $output).Hash.ToLowerInvariant()
"$hash  BoltDM-Setup-windows-amd64.exe" | Set-Content -LiteralPath "$output.sha256" -Encoding Ascii
Write-Host "Built $output"
