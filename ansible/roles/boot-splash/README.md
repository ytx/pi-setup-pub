# boot-splash

[日本語](README.ja.md)

Changes what the screen shows while the Pi boots: no rainbow square, an
optional picture or Plymouth theme instead of the Raspberry Pi logo and the
scrolling boot messages. For devices whose screen people see from power-on.

## Variables

| Variable | Default | |
|---|---|---|
| `splash_hide_logo` | `false` | hide the Raspberry Pi logos at the top left |
| `splash_hide_text` | `false` | hide the boot messages (`quiet`, `loglevel=0`) |
| `splash_hide_cursor` | `false` | hide the blinking cursor |
| `plymouth_use_fkms` | `false` | use FKMS instead of KMS (below) |
| `plymouth_hdmi_force_hotplug` | `true` | always output to HDMI, even when no screen is detected at boot |
| `splash_image` | (none) | a PNG on the controller that replaces the default theme's picture |
| `plymouth_theme` | (none) | an installed Plymouth theme to use |
| `plymouth_theme_url` | (none) | a theme archive (`.tar.gz`) to download and install |
| `plymouth_theme_name` | (none) | the name of the theme in that archive |

Installed themes: `pix` (Raspberry Pi OS's), `spinner`, `fade-in`, `solar`,
`spinfinity`, `glow`, `tribar`, `text`, `details`. More:
[adi1090x/plymouth-themes](https://github.com/adi1090x/plymouth-themes) (over
80) and [gnome-look.org](https://www.gnome-look.org/browse?cat=108&ord=latest).

## Examples

```yaml
# host_vars/raspi-01.yml: a quiet boot
splash_hide_logo: true
splash_hide_text: true
splash_hide_cursor: true

# host_vars/raspi-02.yml: your own picture (1920x1080 PNG), kept next to the playbooks
splash_image: "{{ playbook_dir }}/splash/my-logo.png"
splash_hide_logo: true
splash_hide_text: true

# A standard theme
plymouth_theme: spinner

# A theme from adi1090x's collection
plymouth_theme_url: "https://github.com/adi1090x/plymouth-themes/releases/download/v1.0/spin.tar.gz"
plymouth_theme_name: spin
```

A relative `splash_image` is looked up in the role's directories first, so
give a full path (`{{ playbook_dir }}/...`) for a picture of your own.

## What it changes

- `/boot/firmware/config.txt`: `disable_splash=1` (no rainbow square),
  `hdmi_force_hotplug=1`, FKMS if asked.
- `vc4` in the initramfs and `simplefb` / `simpledrm` blacklisted, so that
  Plymouth has the screen early.
- `/etc/plymouth/plymouthd.conf`: `ShowDelay=0`, `DeviceTimeout=8`, the theme.
- `/boot/firmware/cmdline.txt`: `splash`, and `quiet`, `loglevel=0`,
  `logo.nologo`, `vt.global_cursor_default=0` as asked.
- The initramfs is rebuilt when something in it changed. All of it shows
  from the next boot.

## FKMS

`plymouth_use_fkms: true` changes `dtoverlay=vc4-kms-v3d` to
`vc4-fkms-v3d`. With FKMS the firmware drives the display, which avoids "no
signal" moments during boot and keeps a Plymouth animation steady. 3D
applications may be slower with it.

## Checking

```sh
plymouth-set-default-theme --list     # installed themes
plymouth-set-default-theme            # the current one
# Preview, from a desktop session
sudo plymouthd --mode=boot; sudo plymouth --show-splash
sudo plymouth quit
```

## Tested on

Raspberry Pi OS based on Debian 13 (trixie).
