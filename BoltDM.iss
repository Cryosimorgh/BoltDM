; BoltDM per-user Windows installer. Compile from repository root with Inno Setup 6.
; The companion extension is bundled, but browser installation always requires
; an explicit opt-in and browser-side confirmation (no enterprise policy).
#ifndef AppVersion
  #define AppVersion "1.2.0"
#endif

[Setup]
AppId={{D68333F0-7A9B-461A-9BEE-68A0FF10A567}
AppName=BoltDM
AppVersion={#AppVersion}
AppPublisher=Cryosimorgh
AppPublisherURL=https://github.com/Cryosimorgh/BoltDM
AppSupportURL=https://github.com/Cryosimorgh/BoltDM/issues
DefaultDirName={localappdata}\Programs\BoltDM
DefaultGroupName=BoltDM
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
WizardStyle=modern
Compression=lzma2
SolidCompression=yes
SetupIconFile=BoltDM.ico
UninstallDisplayIcon={app}\BoltDM.ico
OutputDir=dist
OutputBaseFilename=BoltDM-Setup-windows-amd64
CloseApplications=yes
RestartApplications=no
MinVersion=10.0
UsePreviousTasks=yes

[Tasks]
Name: "startup"; Description: "Start BoltDM in the system tray when I sign in to Windows"; GroupDescription: "Startup:"
Name: "desktopicon"; Description: "Create desktop shortcut"; GroupDescription: "Shortcuts:"; Flags: unchecked
Name: "extensionchrome"; Description: "Set up the browser extension in Google Chrome (requires Chrome confirmation)"; GroupDescription: "Optional browser integration (not installed silently):"; Flags: unchecked
Name: "extensionedge"; Description: "Set up the browser extension in Microsoft Edge (requires Edge confirmation)"; GroupDescription: "Optional browser integration (not installed silently):"; Flags: unchecked

[Files]
Source: "dist\BoltDM-windows-amd64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "packaging\windows\Install-Extension.ps1"; DestDir: "{app}\tools"; Flags: ignoreversion

[InstallDelete]
; Replace the legacy .cmd installer's untracked startup link; unchecking the
; startup task must genuinely disable it on updates.
Type: files; Name: "{userstartup}\BoltDM.lnk"

[Icons]
Name: "{group}\BoltDM"; Filename: "{app}\BoltDM-Launcher.exe"; WorkingDir: "{app}"; IconFilename: "{app}\BoltDM.ico"
Name: "{userdesktop}\BoltDM"; Filename: "{app}\BoltDM-Launcher.exe"; WorkingDir: "{app}"; IconFilename: "{app}\BoltDM.ico"; Tasks: desktopicon
Name: "{userstartup}\BoltDM"; Filename: "{app}\BoltDM-Launcher.exe"; Parameters: "--background"; WorkingDir: "{app}"; IconFilename: "{app}\BoltDM.ico"; Tasks: startup

[Run]
Filename: "{app}\BoltDM-Launcher.exe"; Description: "Launch BoltDM"; Flags: postinstall nowait skipifsilent
; Opt-in setup opens the extensions page and copies the bundled folder path to
; clipboard. Neither Chrome nor Edge permits a consumer EXE to enable an
; unpacked extension without explicit interaction in the browser.
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\tools\Install-Extension.ps1"" -Browser Chrome -ExtensionPath ""{app}\BoltDM-Companion"""; Tasks: extensionchrome; Flags: nowait skipifsilent runhidden
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\tools\Install-Extension.ps1"" -Browser Edge -ExtensionPath ""{app}\BoltDM-Companion"""; Tasks: extensionedge; Flags: nowait skipifsilent runhidden
