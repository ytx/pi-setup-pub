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

[base.yml](../base.yml) shows how they fit together in a playbook.
