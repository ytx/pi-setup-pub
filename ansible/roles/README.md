# Roles

One directory per role, the usual Ansible layout (`tasks/`, `defaults/`,
`templates/`, `files/`, `handlers/`, `meta/`). Each role has a `README.md`
(English) and a `README.ja.md` (Japanese) that say what it does, which
variables it reads (with their defaults) and how it was tested.

Roles are being moved here from the author's own setup a few at a time.

| Role | |
|---|---|
| [overlay-disable](overlay-disable/README.md) | Overlay filesystem off and reboot, so that the playbook's changes stay - first in a playbook |
| [overlay-enable](overlay-enable/README.md) | Swap off, read-only root prepared, overlay on and reboot - last in a playbook |
| [apt-upgrade](apt-upgrade/README.md) | `apt update` and `apt dist-upgrade` |
| [watchdog](watchdog/README.md) | The hardware watchdog restarts a hung Pi |
| [config-persistence](config-persistence/README.md) | Keeps chosen files across reboots on an overlay device (`/boot/firmware/config`) |
| [boot-mode](boot-mode/README.md) | Desktop or console boot, and automatic login |
| [locales](locales/README.md) | The locales SSH clients send (no `setlocale` warnings, no fall-back to C) |
| [leds-config](leds-config/README.md) | What the ACT and PWR LEDs show, or both off |
| [disable-services](disable-services/README.md) | Stops and disables the services you list |
| [disable-cloud-init](disable-cloud-init/README.md) | cloud-init off after the first boot |
| [clear-wifi](clear-wifi/README.md) | Forgets every Wi-Fi network |
| [rtc](rtc/README.md) | Time from an I2C real-time clock (DS3231, ...) |
| [static-ip](static-ip/README.md) | A fixed IPv4 address (NetworkManager or dhcpcd) |
| [keep-wifi](keep-wifi/README.md) | Wi-Fi brought back by itself: reconnect, driver reload, reboot; power saving off |
| [wifi-fallback](wifi-fallback/README.md) | Extra Wi-Fi networks for when the usual one is out of reach |
| [eth-nat-share](eth-nat-share/README.md) | Shares the Wi-Fi with one device on the Ethernet port (DHCP + NAT) |
| [vnc-server](vnc-server/README.md) | VNC remote desktop (wayvnc or RealVNC) |
| [rpi-clone](rpi-clone/README.md) | Copy the SD card to another and rename the copy (`clone-dd`, `clone-rename`, rpi-clone) |
| [boot-splash](boot-splash/README.md) | The boot screen: no rainbow, logos or messages; your picture or a Plymouth theme |
| [argon-fanhat](argon-fanhat/README.md) | Argon40 Fan HAT fan by CPU temperature |

[base.yml](../base.yml) shows how they fit together in a playbook.
