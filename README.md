# map-drive

"Map network drive" for Linux, without the extras. One small bash script that connects a Windows or
NAS share by its UNC path (`\\server\share`), reconnects it after every restart, and puts it in your
file manager's sidebar as a drive letter, the way Windows does.

```
$ map-drive Z '\\nas\MyFiles'
Mapping Z: -> \\nas\MyFiles
Username on the server: alice
Password (hidden):
Drive Z: connected: \\nas\MyFiles is at /mnt/z
It is in your file manager's sidebar as "Z (MyFiles)" (reopen the file manager if it was open).
It reconnects by itself after every restart.
```

Made for a bare-bones Gentoo + systemd + KDE Plasma desktop, where the usual answers (Smb4K, a
Samba-enabled Dolphin, GVFS) pull in the whole Samba suite. map-drive needs only the kernel's CIFS
client and `mount.cifs`.

## How it works

- The share is mounted at `/mnt/<letter>` by a systemd `.mount` unit plus an `.automount` unit.
  It connects the first time something opens `/mnt/<letter>`, so booting never waits for the network
  and a NAS that is off does not hang the desktop.
- Your server username and password go in `/etc/cifs-credentials/<letter>`, mode 600, owned by root.
  They are never put on a command line or in the unit files.
- Files on the share belong to you (`uid`/`gid` of the user who ran map-drive).
- A sidebar entry `<LETTER> (<share>)` is added for KDE (Dolphin and every KDE file dialog,
  `~/.local/share/user-places.xbel`) and for GTK file managers and dialogs
  (`~/.config/gtk-3.0/bookmarks`).
- If the first connection fails, map-drive prints the reason and removes everything it created.

## Requirements

- systemd, bash, sudo, python3
- `mount.cifs` from cifs-utils, and a kernel with CIFS support (`CONFIG_CIFS`, in every distribution
  kernel)

Gentoo: the lean build of cifs-utils does not need Samba:

```
echo 'net-fs/cifs-utils -acl -ads -python' > /etc/portage/package.use/cifs-utils
emerge net-fs/cifs-utils
```

Debian/Ubuntu: `apt install cifs-utils`. Fedora: `dnf install cifs-utils`. Arch: `pacman -S cifs-utils`.

## Install

```
sudo install -m 755 map-drive /usr/local/bin/map-drive
# optional default share and options:
sudo install -m 644 map-drive.conf.example /etc/map-drive.conf   # then edit it
```

## Use

Run it as your normal user. It asks for sudo when it needs it.

| Command | What it does |
|---|---|
| `map-drive` | Map drive Z (or `DEFAULT_LETTER`). Asks for the share, or offers `DEFAULT_SHARE`. |
| `map-drive Y '\\server\share'` | Map drive Y to that share. `//server/share` works too, and so does a subfolder: `\\server\share\folder`. |
| `map-drive --list` | Show mapped drives and whether each is connected right now. |
| `map-drive --remove Y` | Disconnect drive Y and remove its units, saved password and sidebar entry. |
| `map-drive --version` | Print the version. |

Quote UNC paths in the shell (`'\\server\share'`), or use forward slashes.

## Settings

Optional file `/etc/map-drive.conf` (start from `map-drive.conf.example`):

| Setting | Default | Meaning |
|---|---|---|
| `DEFAULT_LETTER` | `Z` | Letter used when you give none. |
| `DEFAULT_SHARE` | empty | Share offered when you give none. Empty = always ask. |
| `MOUNT_OPTIONS` | `iocharset=utf8,soft` | Extra mount.cifs options for new mappings, e.g. add `vers=3.0` for an old NAS. |

To change the password of a mapped drive, remove it and map it again.

## Troubleshooting

- **"Could not connect ... Permission denied"**: wrong username or password, or the account has no
  access to that share. Nothing is kept; run map-drive again.
- **"No such file or directory"**: the share name is wrong. List the shares from Windows, or from
  the NAS's web page.
- **An old NAS that only speaks SMB1**: map-drive does not enable SMB1. Add `vers=1.0` to
  `MOUNT_OPTIONS` only if you accept the security risk.
- **See what happened at boot or on first open**: `journalctl -u mnt-z.mount -u mnt-z.automount`
  (use your letter).
- **The sidebar entry did not appear**: close and reopen the file manager. A backup of the KDE places
  file is kept as `user-places.xbel.bak-map-drive`.

## Releases and contributing

Changes are listed in [CHANGELOG.md](CHANGELOG.md). Releases are tagged `vX.Y.Z` on GitHub; the
version is `VERSION` in the script. Issues and pull requests are welcome; see the organization's
contributing guide.

## License

MIT, see [LICENSE](LICENSE).
