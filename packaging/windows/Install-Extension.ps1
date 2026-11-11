# Interactive extension setup helper. An installer checkbox grants permission to
# launch this guide, not permission to bypass the browser's installation UI.
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Chrome', 'Edge')]
    [string]$Browser,
    [Parameter(Mandatory = $true)]
    [string]$ExtensionPath
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

if (-not (Test-Path -LiteralPath (Join-Path $ExtensionPath 'manifest.json'))) {
    [System.Windows.Forms.MessageBox]::Show(
        'BoltDM Companion files are missing. Reinstall BoltDM before setting up the extension.',
        'BoltDM Companion', 'OK', 'Error') | Out-Null
    exit 1
}

if ($Browser -eq 'Chrome') {
    $relative = 'Google\Chrome\Application\chrome.exe'
    $page = 'chrome://extensions/'
} else {
    $relative = 'Microsoft\Edge\Application\msedge.exe'
    $page = 'edge://extensions/'
}

$roots = @($env:ProgramFiles, [Environment]::GetEnvironmentVariable('ProgramFiles(x86)'), $env:LOCALAPPDATA)
$exe = $null
foreach ($root in $roots) {
    if (-not $root) { continue }
    $candidate = Join-Path $root $relative
    if (Test-Path -LiteralPath $candidate) {
        $exe = $candidate
        break
    }
}
if (-not $exe) {
    [System.Windows.Forms.MessageBox]::Show(
        "$Browser was not found. The extension remains available at:`n$ExtensionPath",
        'BoltDM Companion', 'OK', 'Information') | Out-Null
    exit 0
}

# The path can be pasted into the Load unpacked folder picker.
try { Set-Clipboard -Value $ExtensionPath -ErrorAction Stop }
catch { } # Clipboard may be unavailable in remote/headless sessions.
Start-Process -FilePath $exe -ArgumentList $page
Start-Process -FilePath explorer.exe -ArgumentList ('"' + $ExtensionPath + '"')

[System.Windows.Forms.MessageBox]::Show(
    "$Browser is open to Extensions.`n`n" +
    "1. Enable Developer mode.`n" +
    "2. Click Load unpacked.`n" +
    "3. Select the BoltDM-Companion folder shown in Explorer.`n" +
    "   Folder path (also copied to clipboard):`n$ExtensionPath`n`n" +
    "4. Approve the browser's extension permissions.`n" +
    "5. To catch downloads automatically, open the BoltDM extension popup and enable 'Catch browser downloads automatically'.`n`n" +
    'No browser settings or enterprise policies have been changed.',
    'Install BoltDM Companion', 'OK', 'Information') | Out-Null
