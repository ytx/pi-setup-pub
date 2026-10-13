# clear-wifi

[日本語](README.ja.md)

Removes every Wi-Fi connection the Pi knows - for example before handing over
a device, or on an SD card cloned from another one.

What it does:

1. Deletes every Wi-Fi connection profile from NetworkManager (`nmcli`).
2. Empties the networks out of `/etc/wpa_supplicant/wpa_supplicant.conf`, if
   there is one (older releases).
3. Deletes `/boot/firmware/network-config`, cloud-init's network settings
   from Raspberry Pi Imager.

**Run it over Ethernet** (or on the console): over Wi-Fi, ansible loses the
connection it is using.

## Variables

| Variable | Default | |
|---|---|---|
| `clear_wifi_country` | `""` | Wi-Fi country code (`GB`, `US`, `JP`, ...) written to the emptied `wpa_supplicant.conf`; empty leaves the line out |

## Tested on

Raspberry Pi OS based on Debian 13 (trixie).
