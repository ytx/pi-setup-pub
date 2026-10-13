# wifi-fallback

[日本語](README.ja.md)

Adds Wi-Fi networks for when the usual one is out of reach - a phone's
hotspot or a mobile router for a demo away from home, say.

The usual network (set in Raspberry Pi Imager) is left as it is. The
fallbacks get a **negative `connection.autoconnect-priority`**, so
NetworkManager uses the usual network wherever it can be seen and a fallback
only where it cannot:

- the usual network: priority `0` (NetworkManager's default, untouched)
- a fallback: priority `-10` unless you give another
- leave: it switches to a fallback; come back: it returns to the usual one

## Variables

| Variable | Default | |
|---|---|---|
| `wifi_fallbacks` | `[]` | the fallback networks (below) |
| `wifi_interface` | `wlan0` | the interface |

Each entry of `wifi_fallbacks`:

| Key | Required | |
|---|---|---|
| `ssid` | yes | the network's name |
| `psk` | yes | its WPA password |
| `priority` | no | default `-10`; set it to order several fallbacks |

The passwords are secrets: put the list in the secrets directory, not in the
repository (see "Secrets" in the top-level README):

```yaml
# ~/.config/pi-setup/secrets/group_vars/all.yml
wifi_fallbacks:
  - ssid: "MyPhoneHotspot"
    psk: "..."  # leak-ok: a placeholder
  - ssid: "MobileRouter"
    psk: "..."  # leak-ok: a placeholder
    priority: -20    # after the hotspot (-10)
```

## What it does

1. Checks that NetworkManager is running (and stops if not).
2. Adds each network with `nmcli connection add` unless
   `/etc/NetworkManager/system-connections/<ssid>.nmconnection` exists.
3. Sets the password and priority of each again with
   `nmcli connection modify`, so a changed password is picked up.

The tasks that see the password have `no_log: true`, so it is not printed.

## Tested on

Raspberry Pi OS based on Debian 13 (trixie), with NetworkManager.
