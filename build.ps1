$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
New-Item -ItemType Directory -Force -Path dist | Out-Null
go test ./...
go vet ./...
go run ./cmd/icon-gen
go build -trimpath -ldflags "-s -w -H=windowsgui" -o dist/BoltDM.exe ./cmd/boltdm
go build -trimpath -ldflags "-s -w -H=windowsgui" -o dist/BoltDM-Launcher.exe ./cmd/launcher
if (Test-Path "BoltDM.ico") {
    Copy-Item -Force "BoltDM.ico" "dist/BoltDM.ico"
}
(Get-FileHash -Algorithm SHA256 dist/BoltDM.exe).Hash.ToLower() + "  BoltDM.exe" | Set-Content -Encoding ascii dist/BoltDM.exe.sha256
(Get-FileHash -Algorithm SHA256 dist/BoltDM-Launcher.exe).Hash.ToLower() + "  BoltDM-Launcher.exe" | Set-Content -Encoding ascii dist/BoltDM-Launcher.exe.sha256
Write-Host "Built dist/BoltDM.exe and dist/BoltDM-Launcher.exe"
