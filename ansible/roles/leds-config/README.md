# leds-config

[日本語](README.ja.md)

Sets what the Pi's two LEDs show - ACT (green) and PWR (red) - or turns them
off, for a device in a bedroom or a display case. Written to
`/boot/firmware/config.txt`; takes effect at the next boot.

## Variables

| Variable | Default | |
|---|---|---|
| `leds_enabled` | `true` | `false` turns both LEDs off (the `*_off_*` values below) |
| `act_led_trigger` | `mmc0` | ACT: `none`, `mmc0` (SD card activity), `heartbeat`, `timer`, `default-on` |
| `act_led_activelow` | `on` | ACT polarity: `on` / `off` |
| `pwr_led_trigger` | `default-on` | PWR: `none`, `default-on`, `heartbeat`, `timer` |
| `pwr_led_activelow` | `on` | PWR polarity: `on` / `off` |
| `act_led_off_trigger` / `act_led_off_activelow` | `none` / `off` | written to ACT when `leds_enabled: false` |
| `pwr_led_off_trigger` / `pwr_led_off_activelow` | `off` / `on` | written to PWR when `leds_enabled: false` |

Example, in the inventory:

```yaml
# host_vars/raspi-01.yml: both LEDs off
leds_enabled: false

# host_vars/raspi-02.yml: a heartbeat on the green LED
act_led_trigger: heartbeat
```

## Notes

- The PWR LED's polarity differs between models. On the **Pi 3B+** it is
  driven through a GPIO expander and is active-low: `trigger=none` with
  `activelow=off` leaves it lit, so the "off" defaults are `trigger=off`,
  `activelow=on`, which turn it off there. If it stays lit on another model,
  override `pwr_led_off_*` for that host.
- Each LED's lines sit between `# BEGIN/END ANSIBLE MANAGED` markers in
  `config.txt` and are replaced on the next run.

## Tested on

Raspberry Pi OS based on Debian 13 (trixie), including the Pi 3B+ (the PWR LED note above).
