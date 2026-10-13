# disable-services

[日本語](README.ja.md)

Stops and disables the systemd services you list - things a single-purpose
device does not need (Bluetooth, Avahi, a desktop's helpers, ...). A service
that is not installed is skipped without failing the play.

## Variables

| Variable | Default | |
|---|---|---|
| `services_to_disable` | `[]` | unit names to stop and disable |

## Example

```yaml
roles:
  - role: disable-services
    vars:
      services_to_disable:
        - bluetooth
        - avahi-daemon
```

## Tested on

Raspberry Pi OS based on Debian 13 (trixie).
