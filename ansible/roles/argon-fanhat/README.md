# argon-fanhat

[日本語](README.ja.md)

Drives the fan of an Argon40 Fan HAT (on I2C) by the CPU temperature, with
Argon40's own service.

What it does:

1. Installs `python3-libgpiod`, `python3-smbus` and `i2c-tools`, and turns
   I2C on.
2. Downloads Argon40's scripts into `/etc/argon` and their fan settings tool
   as `/usr/local/bin/argon-config`.
3. Writes the temperature steps to `/etc/argononed.conf`.
4. Installs and starts `argononed.service`; restarts it when the steps
   change.

## Variables

| Variable | Default | |
|---|---|---|
| `argon_fan_thresholds` | below | temperature (°C) and fan speed (%) pairs |
| `argon_download_url` | `https://download.argon40.com/scripts` | where the scripts come from |
| `argon_install_dir` | `/etc/argon` | where they go |

```yaml
# the default
argon_fan_thresholds:
  - { temp: 55, speed: 30 }    # from 55 °C: 30 %
  - { temp: 60, speed: 55 }
  - { temp: 65, speed: 100 }
```

```yaml
# host_vars/raspi-01.yml: earlier and in more steps
argon_fan_thresholds:
  - { temp: 50, speed: 25 }
  - { temp: 55, speed: 50 }
  - { temp: 60, speed: 75 }
  - { temp: 65, speed: 100 }
```

## Managing it

```sh
sudo systemctl status argononed
argon-config                     # Argon40's interactive settings (optional)
```

The scripts are downloaded from Argon40 as they publish them (once: a file
already there is not fetched again); this repository does not contain them.
Delete them on the Pi to get a newer version.

## Tested on

Raspberry Pi OS based on Debian 13 (trixie), with an Argon Fan HAT.
