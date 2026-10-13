# config-persistence

[日本語](README.ja.md)

Keeps chosen files and directories across reboots on a device with the
overlay filesystem. They are saved to `/boot/firmware/config/` - the boot
partition, which [overlay-enable](../overlay-enable/README.md) leaves
writable - and copied back at every boot.

Useful for things that change on the device itself after setup: a login
token, a browser's local storage, settings made in a web page.

What it installs:

- `/boot/firmware/config/save.sh` and `load.sh`, and `files.json`, the list of
  what is kept (created empty, never overwritten)
- `config-persistence.service`, which runs `load.sh --all` at boot, before the
  network starts
- `jq`, which both scripts use

## Saving

```sh
# A file or a directory (by its path; relative paths work)
sudo /boot/firmware/config/save.sh ~/.config/rclone/rclone.conf
sudo /boot/firmware/config/save.sh "$HOME/.config/chromium/Default/Local Storage"

# Everything listed again, after it changed
sudo /boot/firmware/config/save.sh --all

# What happened at the last boot
cat /tmp/load.sh-log
```

A role can register its own files the same way, with a task that runs
`save.sh <path>` once the file exists.

`files.json`:

```json
{
  "files": [
    { "name": "rclone.conf", "path": "/home/pi/.config/rclone/rclone.conf",
      "type": "file", "owner": "pi", "group": "pi", "mode": "600" },
    { "name": "Local Storage.tar", "path": "/home/pi/.config/chromium/Default/Local Storage",
      "type": "directory", "owner": "pi", "group": "pi" }
  ]
}
```

- A directory is saved as a tar archive (modes kept) and restored with the
  owner it had. All files in it must have the same owner.
- Restoring onto `/` or a top-level system directory (`/etc`, `/home`, ...) is
  refused, both when saving and when loading.
- **The boot partition is FAT32: no permissions.** Anything saved there,
  passwords and tokens included, can be read by anyone who has the SD card.

## Variables

None.

## Troubleshooting

`Read-only file system` when saving: the boot partition is mounted
read-only. overlay-enable sets it to read-write in `/etc/fstab`; to fix it by
hand:

```sh
mount | grep /boot/firmware
sudo mount -o remount,rw /boot/firmware
```

## Tested on

Raspberry Pi OS based on Debian 13 (trixie); Pi Zero W, 3B, 4B and 5.
