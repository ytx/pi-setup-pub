# udev-symlink

[日本語](README.ja.md)

Gives USB serial devices fixed names. A GPS receiver and a USB-serial adapter
can come up as `/dev/ttyACM0` or `/dev/ttyUSB0` in either order; with this,
your program opens `/dev/ttyGPS` instead.

## Variables

| Variable | Default | |
|---|---|---|
| `udev_devices` | `[]` | the devices and their names (below) |

```yaml
# host_vars/raspi-01.yml
udev_devices:
  - vendor_id: "1546"    # USB vendor ID
    product_id: "01a7"   # USB product ID
    symlink: "ttyGPS"    # -> /dev/ttyGPS
  - vendor_id: "0403"
    product_id: "6001"
    symlink: "ttySerial"
```

Find the IDs with `lsusb`:

```
Bus 001 Device 004: ID 1546:01a7 U-Blox AG [u-blox 7]
                       ^^^^ ^^^^
                     vendor product
```

## What it does

Writes `/etc/udev/rules.d/99-usb-symlinks.rules` (one rule per device, for
the `tty` subsystem) and reloads the udev rules. Nothing happens with an
empty list.

- The link appears when the device is plugged in and goes when it is
  unplugged.
- The original name (`/dev/ttyACM0`, ...) still works.
- With two devices of the same vendor and product ID, which one gets the
  link is not defined.
- A device already plugged in gets its link at the next plug-in or reboot.

## Tested on

Raspberry Pi OS based on Debian 13 (trixie).
