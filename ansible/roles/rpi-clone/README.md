# rpi-clone

[日本語](README.ja.md)

Tools to copy the running Pi's SD card to another card (in a USB card
reader), and to give the copy its own host name - for making several devices
from one that is set up.

## Commands it installs

| Command | |
|---|---|
| `clone-dd` | copies the boot card with `dd`; works with the overlay filesystem on |
| `clone-rename` | changes the host name on the copy |
| `rpi-clone` | [billw2/rpi-clone](https://github.com/billw2/rpi-clone): copies file by file and resizes partitions; only with the overlay off |
| `rpi-clone-setup` | its setup helper |

## Variables

| Variable | Default | |
|---|---|---|
| `rpi_clone_base_url` | `https://raw.githubusercontent.com/billw2/rpi-clone/master` | where rpi-clone is downloaded from |
| `rpi_clone_install_dir` | `/usr/local/sbin` | where the commands go |

## clone-dd (recommended)

Works with the overlay on. Copies the boot card (`/dev/mmcblk0`) up to the
end of its last partition - not the whole card - and asks before writing:

```sh
sudo clone-dd sdb                 # copy to /dev/sdb
sudo clone-dd sdb raspi-02        # copy, then rename the copy to raspi-02
```

It stops if the target is too small. Cards of the same nominal size differ
slightly, so if the root partition was grown to fill the card, a copy to
another card "of the same size" can fail. Shrinking the root partition first
avoids that (from another machine, with the card in a reader):

```sh
sudo e2fsck -f /dev/sdb2
sudo resize2fs /dev/sdb2 6G
sudo parted /dev/sdb resizepart 2 6.5GB
```

## clone-rename

```sh
sudo clone-rename sdb raspi-02
```

Mounts the copy's root (partition 2) and boot (partition 1) partitions,
writes the new name to `/etc/hostname`, replaces the old one in `/etc/hosts`
and in `/boot/firmware/user-data` (cloud-init) if there is one, and unmounts
them.

## rpi-clone

```sh
sudo rpi-clone sdb
```

With the overlay off only. See its own documentation.

## Tested on

Raspberry Pi OS based on Debian 13 (trixie).
