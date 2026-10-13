# apt-upgrade

[日本語](README.ja.md)

Updates the package lists (unless they are less than an hour old) and
upgrades every package (`apt dist-upgrade`). Put it right after
[overlay-disable](../overlay-disable/README.md), so that the upgrade is not
written to the overlay and lost.

## Variables

None.

## Tested on

Raspberry Pi OS based on Debian 13 (trixie); Pi Zero W, 3B, 4B and 5.
