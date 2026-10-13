# watchdog

[日本語](README.ja.md)

Restarts the Pi by itself when the system hangs, with the SoC's hardware
watchdog:

- `dtparam=watchdog=on` in `/boot/firmware/config.txt`
- systemd feeds it (`RuntimeWatchdogSec` in `/etc/systemd/system.conf`): if
  systemd stops responding for that long, the hardware resets the board
- the separate `watchdog` daemon is stopped and disabled, if installed, so the
  two do not both drive the device

Both take effect at the next boot ([overlay-enable](../overlay-enable/README.md)
reboots at the end).

## Variables

| Variable | Default | |
|---|---|---|
| `watchdog_timeout` | `10` | seconds without systemd responding before the reset |

## Tested on

Raspberry Pi OS based on Debian 13 (trixie); Pi Zero W, 3B, 4B and 5.
