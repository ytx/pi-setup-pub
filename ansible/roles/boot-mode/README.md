# boot-mode

[日本語](README.ja.md)

Sets whether the Pi boots to the desktop or the console, and whether a user is
logged in automatically. Kiosk-style devices log a user in on the console and
start their application from `.bash_profile`; headless servers just state
"console, no login".

## Variables

| Variable | Default | |
|---|---|---|
| `boot_mode` | `cui` | `cui` (`multi-user.target`) or `gui` (`graphical.target`) |
| `boot_autologin` | `false` | log a user in automatically |
| `boot_autologin_user` | `pi` | who is logged in |
| `boot_getty_enabled` | `true` | keep a console login on tty1 |
| `boot_display_manager` | `lightdm` | the display manager driven in `gui` mode |

## What it does

| `boot_mode` | Boot target | Display manager |
|---|---|---|
| `cui` | `multi-user.target` | **stopped and disabled** |
| `gui` | `graphical.target` | enabled |

In `cui` mode the display manager is always disabled: changing the target
alone is not enough, since an upgrade of a desktop image can enable it again
and bring X up behind your application.

Automatic login is done differently in each mode:

| Mode | How |
|---|---|
| `cui` | `agetty --autologin` in `/etc/systemd/system/getty@tty1.service.d/autologin.conf` |
| `gui` | `/etc/lightdm/lightdm.conf.d/10-autologin.conf` |

With `boot_autologin: false` the file is **removed**, so a host can be turned
back.

The user is not added to an `autologin` group: that is an Arch Linux
convention. Debian's and Raspberry Pi OS's `/etc/pam.d/lightdm-autologin` has
no `user ingroup autologin` condition.

## `boot_getty_enabled`

Whether tty1 keeps its console login. **Kept by default**, so plugging in a
screen and a keyboard always gets you in.

Set it to `false` only when another program takes over the tty1 console -
a video player drawing straight to the screen (mpv on DRM, GStreamer's
`kmssink`). Without it there is no local way back into the machine.

Console autologin is done by agetty, so `boot_autologin: true` together with
`boot_getty_enabled: false` is refused by an `assert`.

## Examples

```yaml
# Kiosk: console, logged in automatically, .bash_profile runs startx
- role: boot-mode
  vars:
    boot_mode: cui
    boot_autologin: true
    boot_autologin_user: pi

# Headless server: console, no automatic login
- role: boot-mode
  vars:
    boot_mode: cui
    boot_autologin: false

# An application that owns the screen: no console either
- role: boot-mode
  vars:
    boot_mode: cui
    boot_getty_enabled: false
```

## When it takes effect

`systemctl set-default` from the next boot; the getty autologin after
`systemctl restart getty@tty1` or a reboot. The reboot at the end of
[overlay-enable](../overlay-enable/README.md) covers both.

## Checking

```sh
systemctl get-default                        # multi-user.target / graphical.target
systemctl is-enabled lightdm                 # disabled in cui (not-found if not installed)
systemctl is-enabled getty@tty1
ls /etc/systemd/system/getty@tty1.service.d/  # autologin.conf or not
pgrep -a Xorg                                # nothing in cui, unless your app started it
```

## Tested on

Raspberry Pi OS based on Debian 13 (trixie).
