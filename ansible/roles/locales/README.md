# locales

[日本語](README.ja.md)

Makes sure the locales that SSH clients ask for exist on the Pi.

## The problem

sshd takes the client's `LANG` and `LC_*` (`AcceptEnv`). When the client sends
one the Pi does not have, every login warns:

```
bash: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8): No such file or directory
```

It is more than a warning: the session falls back to the C locale (not
UTF-8), and file names in other scripts (Japanese, accented letters) no
longer display correctly.

Raspberry Pi OS images come with `en_GB.UTF-8` only, while macOS's Terminal
sends `LC_ALL=en_US.UTF-8` by default - so this happens to everyone who logs
in from a Mac.

## Variables

| Variable | Default | |
|---|---|---|
| `locales_install_all` | `true` | install `locales-all`: every locale, nothing to generate |
| `locales_generate` | `["en_US.UTF-8 UTF-8"]` | the locales generated when `locales_install_all` is `false`, as written in `/etc/locale.gen` |
| `locales_default` | `""` | `LANG` in `/etc/default/locale`; empty leaves it alone |

`locales-all` takes about **231 MB** on disk (an 11 MB download). It is
installed next to the `locales` package, not instead of it. On a small SD
card, set `locales_install_all: false` and list only what you need.

## Apply it with a playbook, not by hand

On an overlay device, `apt install locales-all` run by hand writes into the
overlay's upper layer - RAM:

```
$ df -h /
overlayroot     453M  6.5M  447M   2% /       <- tmpfs (RAM)
```

231 MB there is a quarter of a Pi 3B's memory, and it is gone at the next
reboot. A playbook runs [overlay-disable](../overlay-disable/README.md) first,
so the files land on the SD card. The same goes for running `locale-gen` by
hand.

## Examples

```yaml
roles:
  - overlay-disable
  - locales                    # locales-all
```

```yaml
# Saving disk space
- role: locales
  vars:
    locales_install_all: false
    locales_generate:
      - "en_US.UTF-8 UTF-8"
      - "ja_JP.UTF-8 UTF-8"
```

## Without this role: on the client

To leave the Pi alone, make the client send a locale the Pi has, in
`~/.ssh/config`:

```
Host *
  SetEnv LC_ALL=en_GB.UTF-8
```

On macOS, unticking "Set locale environment variables on startup" in
Terminal's settings does the same. `SendEnv -LC_*` does **not** work: ssh reads
`-o` and the user's config first, and `SendEnv LANG LC_*` from
`/etc/ssh/ssh_config` adds them back afterwards.

## Checking

```sh
ssh <host> 'locale -a | wc -l'                              # hundreds with locales-all
LC_ALL=en_US.UTF-8 ssh -o SendEnv=LC_ALL <host> 'locale'   # no warning: fine
```

## Tested on

Raspberry Pi OS based on Debian 13 (trixie).
