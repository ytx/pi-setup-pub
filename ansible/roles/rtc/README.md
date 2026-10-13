# rtc

[日本語](README.ja.md)

Keeps the time with a real-time clock module on I2C (DS3231 by default), so
that a Pi without a network still knows the time after a power cut.

- With a network, NTP (systemd-timesyncd) sets the time, and the kernel writes
  it back to the RTC.
- Without one, the time comes from the RTC.
- With no RTC connected nothing breaks: the kernel finds no `/dev/rtc0` and
  carries on.

What it does:

1. Turns I2C on (`raspi-config nonint do_i2c 0`).
2. Adds `dtoverlay=i2c-rtc,<chip>` to `/boot/firmware/config.txt`, unless it
   is there. Takes effect at the next boot.

The kernel does the rest - no `hwclock` service needed: it reads the RTC at
boot, writes the system time back to it from time to time once NTP has set
it, and at shutdown.

## Variables

| Variable | Default | |
|---|---|---|
| `rtc_chip` | `ds3231` | the chip, as the `i2c-rtc` overlay names it (`ds1307`, `pcf8523`, ...) |

## Checking

```sh
sudo i2cdetect -y 1                  # "UU" at 0x68: the driver has the chip
cat /sys/class/rtc/rtc0/date /sys/class/rtc/rtc0/time
timedatectl                          # NTP synchronised?
```

## Tested on

Raspberry Pi OS based on Debian 13 (trixie), with a DS3231 module.
