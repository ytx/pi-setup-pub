# usb-patch

[日本語](README.ja.md)

At boot, looks for a patch file on a USB memory stick and unpacks it over
`/`. Meant for devices with the overlay filesystem: you can fix or try
something on a device in the field without a network or ansible - plug in
the stick, power on - and taking the stick out and rebooting undoes it.

> **Anyone who can plug in a USB stick can change any file on the device, as
> root.** Use it only where the USB ports are not reachable by people you do
> not trust.

## How it runs

```
boot -> usb-patch.service (oneshot, after dbus and NetworkManager, before getty@tty1)
  -> waits for a USB disk (/dev/sd[a-z][0-9]) up to usb_patch_timeout seconds
  -> mounts it read-only
  -> picks the newest file matching usb_patch_file_pattern
  -> unpacks it over /
  -> logs, unmounts
-> getty logs in -> the application starts, with the patch in place
```

The service runs at the lowest CPU and disk priority, after dbus and
NetworkManager: unpacking a large file earlier in the boot can starve dbus,
and NetworkManager then fails with it.

No stick, or no patch on it: logged and skipped, never an error.

## Variables

| Variable | Default | |
|---|---|---|
| `usb_patch_file_pattern` | `update-*.tar*` | file names looked for at the top of the stick |
| `usb_patch_mount_point` | `/mnt/usb-patch` | where the stick is mounted for a moment |
| `usb_patch_timeout` | `10` | seconds to wait for a USB disk |

## The patch file

Name it `update-YYYYMMDD-N.tar.gz` (`.tar` works too). The newest is the
last in alphabetical order:

```
update-20260215-1.tar.gz
update-20260215-2.tar.gz
update-20260301-1.tar.gz   <- this one is applied
```

The paths in the archive are where the files go:

```sh
# Replace /opt/myapp/app.py
mkdir -p patch/opt/myapp
cp app.py patch/opt/myapp/
tar czf update-20260215-1.tar.gz -C patch opt
# put update-20260215-1.tar.gz at the top of the stick
```

Directories that already exist (`/`, `/opt`, ...) keep their owner and
permissions (`--no-overwrite-dir`): an archive made with `tar ... .` from a
folder of your own would otherwise give `/` that folder's owner and mode at
boot, and lock every non-root service out. Archiving the top-level folders
by name, as above, avoids the stray `./` entry altogether.

## Log

`/tmp/usb-patch.log`:

```
2026-02-15 10:30:01 --- usb-patch start ---
2026-02-15 10:30:01 Found USB device: /dev/sda1
2026-02-15 10:30:01 Latest patch: update-20260215-2.tar.gz
2026-02-15 10:30:02 Extracted to /
2026-02-15 10:30:02 Done
```

## Notes

- Only useful with the overlay on; without it the changes stay after a
  reboot, like any other change.
- Put it before [overlay-enable](../overlay-enable/README.md) in the
  playbook, like every role.

## Tested on

Raspberry Pi OS based on Debian 13 (trixie), with the overlay filesystem.
