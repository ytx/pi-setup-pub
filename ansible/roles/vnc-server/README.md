# vnc-server

[日本語](README.ja.md)

Turns the VNC remote desktop on (or off), so the Pi's screen can be seen and
used from another computer.

For Raspberry Pi OS with the desktop. Raspberry Pi OS ships two VNC servers:
**wayvnc** for the Wayland desktop and **RealVNC** for X11.

## Variables

| Variable | Default | |
|---|---|---|
| `vnc_enabled` | `true` | `false` turns VNC off |
| `vnc_server_type` | `auto` | which server (below) |

| `vnc_server_type` | |
|---|---|
| `auto` | `raspi-config` decides: wayvnc on Wayland, RealVNC on X11 |
| `realvnc` | RealVNC - for an X11 session started some other way (a kiosk running `startx`, say), where raspi-config would guess wrong. wayvnc is stopped, and RealVNC's tray icon is turned off |
| `wayvnc` | wayvnc - for Wayland. RealVNC is stopped |

```yaml
# host_vars/raspi-01.yml: an X11 kiosk
vnc_server_type: realvnc
```

## Connecting

Point a VNC viewer at the Pi's host name or address, and log in with the
Pi's user name and password.

## Tested on

Raspberry Pi OS based on Debian 13 (trixie).
