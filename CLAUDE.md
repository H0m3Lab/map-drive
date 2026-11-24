# CLAUDE.md: map-drive

Guide for AI coding agents (and humans) working on this repository. Organization rules:
https://github.com/H0m3Lab/.github/blob/main/STANDARDS.md

## Purpose

A bare-bones "Map network drive" for Linux desktops: one bash script that mounts an SMB/CIFS share
given as a UNC path at `/mnt/<letter>`, keeps it reconnecting across reboots with systemd, and adds a
file manager sidebar entry. Built for a minimal Gentoo + systemd + KDE Plasma setup where the common
GUI tools pull in all of Samba.

## Architecture

Everything is in `map-drive`:

- `main` parses the command (`--list`, `--remove`, `--version`, `--help`, or map).
- `do_map` asks for the share and credentials, writes `/etc/cifs-credentials/<letter>` (root, 600),
  `/etc/systemd/system/mnt-<letter>.mount` and `.automount`, starts the mount once to prove the
  credentials work, rolls everything back if it fails, then enables the automount and calls
  `places_add`.
- `do_remove` only touches units whose first line is `# Created by map-drive`.
- `places_add` / `places_remove` edit the KDE places file (`user-places.xbel`, through python3's
  standard library so the XML stays valid) and the GTK bookmarks file.
- `norm_letter`, `norm_share`, `unc` are pure helpers covered by `tests/test.sh`.
- Settings come from `/etc/map-drive.conf` (bash `KEY="value"`), path overridable with
  `MAP_DRIVE_CONF`. Tests also override `MAP_DRIVE_PLACES` and `MAP_DRIVE_GTK`.

## Stack

- Language / runtime: bash, with small inline python3 (stdlib only) for XML
- System: systemd mount/automount units, `mount.cifs` (cifs-utils), sudo
- Storage: none besides the files above

## Repository layout

```
map-drive                  the tool (VERSION at the top)
map-drive.conf.example     optional settings, placeholder values
tests/test.sh              unit tests for helpers and sidebar editing (no sudo, no mounting)
.github/workflows/ci.yml   shellcheck, tests, gitleaks
```

## Commands

| Task | Command |
|---|---|
| Test | `bash tests/test.sh` |
| Lint | `shellcheck -S warning map-drive tests/test.sh` |
| Run locally | `./map-drive --help` (mapping needs sudo and a real share) |

CI (`.github/workflows/ci.yml`) runs shellcheck, the tests, and gitleaks over the full history. Keep
it green.

## Configuration

Settings are documented in the README settings table and `map-drive.conf.example`. When you add or
change one: update both, give it a safe default, and add a CHANGELOG line.

## Conventions

- Stay one file, no dependencies beyond bash, systemd, sudo, python3 stdlib and cifs-utils.
- User-facing text is plain English and shows shares in Windows form (`\\server\share`); internally
  shares are kept as `//server/share`.
- Every failure path prints what went wrong and what to do next.

## Data safety (do not break)

- Never remove or edit mount units, credential files or mount points that map-drive did not create
  (check the `# Created by map-drive` marker).
- Never write the password anywhere except `/etc/cifs-credentials/<letter>` (root, 600): not on a
  command line, not in units, not in logs.
- Editing the KDE places file must keep it valid XML and keep every other entry; a backup is taken
  before the first change.

## Security

- Never hardcode credentials or private values (real IPs, host names, domains, keys, names). Use
  placeholders like `192.0.2.10` / `nas` in code, tests and docs.
- SMB1 is never enabled by default.
- The script refuses to run as root so files and sidebar entries belong to the real user.

## Releases

Semantic versioning. Version lives in `VERSION` at the top of `map-drive`. Steps: CHANGELOG
`[Unreleased]` → new version section, bump `VERSION`, commit, tag `vX.Y.Z`, GitHub release with the
changelog section as notes.
