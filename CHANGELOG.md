# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-11-24

### Added
- First public release: map an SMB/CIFS share by UNC path to a drive letter at `/mnt/<letter>`,
  reconnecting with a systemd automount, credentials in a root-only file.
- Sidebar entries for KDE (Dolphin and file dialogs) and GTK file managers.
- `--list`, `--remove`, `--version`; optional `/etc/map-drive.conf` with `DEFAULT_LETTER`,
  `DEFAULT_SHARE` and `MOUNT_OPTIONS`.
- Automatic rollback when the first connection fails.

[Unreleased]: https://github.com/H0m3Lab/map-drive/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/H0m3Lab/map-drive/releases/tag/v0.1.0
