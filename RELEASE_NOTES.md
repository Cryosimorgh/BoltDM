# BoltDM v1.4.0

BoltDM v1.4.0 adds media-page downloads and bundles the media dependency directly in release packages.

## What's new

- Added a yt-dlp powered media transfer engine for supported media pages.
- Added extension handoff so the current page can be sent directly to the media engine.
- Added media-engine configuration and dependency status reporting.
- Bundled yt-dlp in Windows and Linux release packages.
- Updated Windows and Linux installers to install the bundled yt-dlp binary.
- Added tests for media routing and progress parsing.

## Release packaging

- Windows amd64 ZIP package with SHA-256 checksum.
- Linux amd64 and arm64 tar.gz packages with SHA-256 checksums.
- Improved release-package and checksum verification.

## Windows note

The Windows executable is not signed with a trusted code-signing certificate. Windows SmartScreen can show an Unknown publisher warning.
