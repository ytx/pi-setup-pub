# overlay-disable

[日本語](README.ja.md)

Turns the overlay filesystem off and reboots at once, so that what the rest
of the playbook writes lands on the SD card. Put it **first** in a playbook,
and [overlay-enable](../overlay-enable/README.md) last.

With the overlay on, the root filesystem is read-only underneath and every
change goes to RAM (tmpfs) - good for a device that is switched off without
shutting down, but it means a playbook's work would be lost at the next boot.

What it does:

1. Repairs a host that is stuck in the overlay (below), if this one is.
2. If the overlay is on (`raspi-config nonint get_overlay_now`), turns it off
   (`raspi-config nonint do_overlayfs 1`) and reboots straight away. A host
   with the overlay already off is not rebooted.
3. Makes sure `systemd-remount-fs.service` is not masked, and turns zram swap
   back on: overlay-enable switches swap off, and large installs can run out
   of memory without it.

## Variables

None.

## A host that cannot leave the overlay

`raspi-config` turns the overlay on and off through the kernel command line
(`/boot/firmware/cmdline.txt`). The `overlayroot` package, however, also reads
`/etc/overlayroot.conf`, and that file wins. On a host whose conf says
`overlayroot="tmpfs"`:

- `raspi-config nonint get_overlay_now` reads only the command line and
  answers "off",
- but the host boots into the overlay anyway, so everything written - even a
  task that would reset the conf - goes to tmpfs and is gone at the next
  reboot.

The host cannot free itself from inside the overlay. So when `/` is an overlay
mount (`findmnt`) **and** the conf on the layer underneath (from `lowerdir=`,
usually `/media/root-ro`) forces it, this role remounts that layer read-write,
sets `overlayroot=""` there, puts it back to read-only and reboots. On a
normal host (empty conf) these steps are skipped and nothing is remounted.

To check by hand:

```sh
mount | grep "^overlayroot on / "                               # running on the overlay?
sudo grep '^overlayroot=' /media/root-ro/etc/overlayroot.conf   # "tmpfs" means stuck
```

## Tested on

Raspberry Pi OS based on Debian 13 (trixie); Pi Zero W, 3B, 4B and 5.
