# Interactive setup only. The browser itself must approve installation.
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Chrome', 'Edge', 'Brave', 'Opera', 'Firefox')]
    [string]$Browser,
    [Parameter(Mandatory = $true)]
    [string]$ExtensionPath,
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'

# Explicit installation locations avoid scanning PATH, which may include
# inaccessible Windows reparse points.
$pf86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
$roots = @($env:LOCALAPPDATA, $env:ProgramFiles, $pf86) |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

$spec = switch ($Browser) {
    'Chrome' {
        @{ Names = @('Google\Chrome\Application\chrome.exe'); Page = 'chrome://extensions/'; Kind = 'chromium' }
        break
    }
    'Edge' {
        @{ Names = @('Microsoft\Edge\Application\msedge.exe'); Page = 'edge://extensions/'; Kind = 'chromium' }
        break
    }
    'Brave' {
        @{ Names = @('BraveSoftware\Brave-Browser\Application\brave.exe'); Page = 'brave://extensions/'; Kind = 'chromium' }
        break
    }
    'Opera' {
        @{ Names = @('Programs\Opera\launcher.exe', 'Programs\Opera GX\launcher.exe',
                     'Opera\launcher.exe', 'Opera GX\launcher.exe'); Page = 'opera://extensions/'; Kind = 'chromium' }
        break
    }
    'Firefox' {
        @{ Names = @('Mozilla Firefox\firefox.exe'); Page = 'about:debugging#/runtime/this-firefox'; Kind = 'firefox' }
        break
    }
}

$exe = $null
foreach ($root in $roots) {
    foreach ($relative in $spec.Names) {
        $candidate = Join-Path $root $relative
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $exe = $candidate
            break
        }
    }
    if ($exe) { break }
}

if ($CheckOnly) {
    [PSCustomObject]@{ browser = $Browser; installed = [bool]$exe; executable = $exe } |
        ConvertTo-Json -Compress
    exit 0
}

Add-Type -AssemblyName System.Windows.Forms
if (-not (Test-Path -LiteralPath (Join-Path $ExtensionPath 'manifest.json') -PathType Leaf)) {
    [System.Windows.Forms.MessageBox]::Show(
        'BoltDM Companion is missing. Reinstall BoltDM before setting up the extension.',
        'BoltDM Companion', 'OK', 'Error') | Out-Null
    exit 1
}
if (-not $exe) {
    $notice = @"
$Browser was not detected in the usual installation locations.
The extension is saved at:
$ExtensionPath
"@
    [System.Windows.Forms.MessageBox]::Show(
        $notice, 'BoltDM Companion', 'OK', 'Information') | Out-Null
    exit 0
}

try { Set-Clipboard -Value $ExtensionPath -ErrorAction Stop } catch {}
Start-Process -FilePath $exe -ArgumentList $spec.Page
Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $ExtensionPath + '"')

if ($spec.Kind -eq 'firefox') {
    $instructions = @"
Firefox is open to about:debugging.

1. Select 'This Firefox'.
2. Select 'Load Temporary Add-on'.
3. Open the BoltDM-Companion folder and choose manifest.json.
4. Open the extension popup and enable 'Catch browser downloads automatically' if desired.

Folder: $ExtensionPath

IMPORTANT: Firefox removes temporary unsigned extensions when it restarts.
Permanent installation requires Mozilla signing.
"@
} else {
    $instructions = @"
$Browser is open to its Extensions settings.

1. Turn on Developer mode.
2. Choose 'Load unpacked'.
3. Select the BoltDM-Companion folder displayed in Explorer.
4. Confirm the extension's requested permissions.
5. Open the extension popup and enable 'Catch browser downloads automatically' if desired.

Folder: $ExtensionPath
"@
}

[System.Windows.Forms.MessageBox]::Show(
    $instructions + [Environment]::NewLine + 'No enterprise policies or browser security settings were changed by BoltDM.',
    'Install BoltDM Companion', 'OK', 'Information') | Out-Null
