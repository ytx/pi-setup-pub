# disable-cloud-init

[日本語](README.ja.md)

Turns cloud-init off for good by creating `/etc/cloud/cloud-init.disabled`.

Recent Raspberry Pi OS images use cloud-init to apply what Raspberry Pi
Imager set (user, Wi-Fi, host name) at first boot. Once ansible manages the
device, cloud-init running again at later boots can only get in the way -
for example by rewriting the network settings from
`/boot/firmware/network-config`.

The file is created once and its time stamps are kept, so later runs report
no change.

## Variables

None.

## Tested on

Raspberry Pi OS based on Debian 13 (trixie).
