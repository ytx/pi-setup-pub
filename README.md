# pi-setup-pub

[日本語](README.ja.md)

Ansible roles and playbooks that turn a freshly written Raspberry Pi OS SD card
into a finished device - a kiosk screen, a camera, a small server - with one
command, again and again.

Written for teaching: lectures and seminars on running Raspberry Pis as
appliances. The roles come from the author's own working setup and are moved
here a few at a time, with the site-specific parts taken out.

## Ideas this repository shows

- **Roles and playbooks.** A role is one reusable piece (a read-only root
  filesystem, a watchdog, a kiosk browser). A playbook says which roles make
  one kind of device.
- **An inventory you can find your way around in.** Groups and hosts are
  listed in `inventory/hosts/`; each host's settings are in
  `inventory/host_vars/<host>.yml`, each group's in
  `inventory/group_vars/<group>.yml`.
- **Secrets outside the repository.** Passwords and tokens live in a
  directory of the same shape that is never committed (see [Secrets](#secrets)).
- **A public toolbox, a private site.** Your own hosts and secrets stay in a
  private repository that uses these roles (see
  [Using it from your own repository](#using-it-from-your-own-repository)).

## Requirements

- Raspberry Pis running Raspberry Pi OS, reachable over SSH with a user that
  can `sudo` (the examples use `pi`) - set it up in Raspberry Pi Imager.
  The roles are developed on the Debian 13 (trixie) based release.
- A controller - a Linux or macOS machine, or another Pi - with Python 3.10
  or later.

## Quick start

```sh
git clone https://github.com/ytx/pi-setup-pub.git
cd pi-setup-pub
python3 -m venv venv
venv/bin/pip install -r requirements.txt
. venv/bin/activate

cd ansible
# Point the example inventory at your Pis
$EDITOR inventory/host_vars/raspi-01.yml
ansible-playbook ping.yml
```

`ping.yml` only logs in, runs Python and prints the board model: if it shows
every Pi, ansible can set them up.

Next, `base.yml` is the frame a device playbook follows - overlay
filesystem off, packages upgraded, watchdog and config-persistence set up,
overlay on. It reboots the Pi, so try it on a spare one:

```sh
ansible-playbook base.yml --limit raspi-01
```

The roles are listed in [ansible/roles/](ansible/roles/README.md).

## Layout

```
ansible/
├── ansible.cfg          # inventory and roles location
├── inventory/
│   ├── hosts/           # groups and the hosts in them only, one file per kind of device
│   ├── group_vars/      # <group>.yml: settings for a group (all.yml: every host)
│   └── host_vars/       # <host>.yml: settings for one host
├── roles/               # one directory per role, each with README.md / README.ja.md
└── *.yml                # playbooks, one per kind of device
scripts/check-leaks.sh   # stops secrets and private details being committed
```

Run playbooks from `ansible/` so that `ansible.cfg` is used:

```sh
ansible-playbook <playbook>.yml --limit <host>
```

## Secrets

Keep passwords, keys and tokens out of the repository, in a directory laid
out like `inventory/` that only has variables:

```
~/.config/pi-setup/secrets/      # chmod 700, files chmod 600
├── hosts.yml                    # just: all: {}
├── group_vars/<group>.yml
└── host_vars/<host>.yml
```

and add it to `ansible.cfg`:

```ini
inventory = inventory, ~/.config/pi-setup/secrets
```

`hosts.yml` lists no groups on purpose: a group written there would put hosts
in it. Where both define a variable, the secrets directory wins. In the
repository, leave a comment where a secret is used, for example
`# web_password: in the secrets directory`.

## Using it from your own repository

For your real devices, keep a private repository with your inventory and
anything that is yours alone, next to this one:

```
~/git/pi-setup-pub/    this repository
~/git/my-site/ansible/
├── ansible.cfg
├── inventory/
├── roles/             # roles of your own
└── *.yml              # your playbooks
```

with

```ini
# ~/git/my-site/ansible/ansible.cfg
[defaults]
inventory = inventory, ~/.config/pi-setup/secrets
roles_path = roles:../../pi-setup-pub/ansible/roles
```

Your playbooks then use these roles by name, and a `git pull` here brings in
fixes. The playbooks of this repository can be run from there as well:
`ansible-playbook ../../pi-setup-pub/ansible/ping.yml`.

## Contributing and the leak check

```sh
venv/bin/pip install -r requirements-dev.txt
git config core.hooksPath .githooks      # once per clone
```

The pre-commit hook runs `scripts/check-leaks.sh`, which refuses a commit that
contains vault data, private keys, AWS key ids, passwords in URLs, literal
passwords or tokens, or private IPv4 addresses outside the example range
`192.168.1.0/24`. Use `example.com` and `192.168.1.x` in examples.

It also reads a list of your own patterns (your domains, SSIDs, networks) from
a file that is not in this repository - by default
`../pi-setup/pub-leak-patterns.txt`, or `$PI_SETUP_LEAK_PATTERNS` - one
extended regular expression per line, and checks the commit's author name and
e-mail against it. GitHub Actions runs the generic checks, yamllint and
ansible-lint on every push.

## License

[MIT](LICENSE)
