# overlay-enable

[日本語](README.ja.md)

Prepares the device to run on a read-only root with the overlay filesystem,
turns the overlay on and reboots. Put it **last**, in `post_tasks`, after
[overlay-disable](../overlay-disable/README.md) at the start:

```yaml
  post_tasks:
    - name: Enable the overlay filesystem
      ansible.builtin.include_role:
        name: overlay-enable
```

What it does:

- Swap off for good: dphys-swapfile (older releases) and zram (current ones;
  the units are masked, because systemd-zram-generator creates them again at
  every boot). Swap on an overlay would only use up RAM.
- Loads the `overlay` module in the initramfs. On some Pi kernels the
  overlayroot hook cannot load it by itself and the device boots without the
  overlay.
- Keeps `/etc/overlayroot.conf` at `overlayroot=""`, so that the kernel
  command line alone - what `raspi-config` changes - decides (see
  [overlay-disable](../overlay-disable/README.md) for what happens otherwise).
- Rate-limits rsyslog, so that logs do not fill the RAM.
- Lets `systemd-remount-fs.service` run only when `/` is read-only. On the
  overlay the kernel refuses to remount `/`, the unit fails, and NetworkManager
  is not started (no network). Masking it instead would break boots without
  the overlay.
- Turns the overlay on (`raspi-config nonint do_overlayfs 0`) and keeps
  `/boot/firmware` writable, for [config-persistence](../config-persistence/README.md).
- Reboots.

## Variables

| Variable | Default | |
|---|---|---|
| `overlay_enabled` | `true` | `false` skips all of the above and only reboots: for a development board you keep changing |

## Tested on

Raspberry Pi OS based on Debian 13 (trixie); Pi Zero W, 3B, 4B and 5.
