# boot-mode

[English](README.md)

Pi をデスクトップで起動するかコンソールで起動するか、自動ログインするかを設定する。
kiosk のような機器はコンソールで自動ログインし、`.bash_profile` からアプリを起動する。
ヘッドレスのサーバは「コンソール、ログインなし」と明示する。

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `boot_mode` | `cui` | `cui`（`multi-user.target`）か `gui`（`graphical.target`） |
| `boot_autologin` | `false` | 自動ログインする |
| `boot_autologin_user` | `pi` | 自動ログインするユーザ |
| `boot_getty_enabled` | `true` | tty1 にコンソールログインを残す |
| `boot_display_manager` | `lightdm` | `gui` モードで扱うディスプレイマネージャ |

## すること

| `boot_mode` | 起動ターゲット | ディスプレイマネージャ |
|---|---|---|
| `cui` | `multi-user.target` | **停止・無効化** |
| `gui` | `graphical.target` | 有効化 |

**`cui` モードではディスプレイマネージャを必ず無効にする。** ターゲットを変えるだけでは、
デスクトップ入りのイメージがアップグレードで再び有効にし、アプリの裏で X が立ち上がることがある。

自動ログインのやり方はモードで違う:

| モード | 方法 |
|---|---|
| `cui` | `/etc/systemd/system/getty@tty1.service.d/autologin.conf` で `agetty --autologin` |
| `gui` | `/etc/lightdm/lightdm.conf.d/10-autologin.conf` |

`boot_autologin: false` のときは、そのファイルを**削除する**（一度有効にしたホストを戻せるように）。

`autologin` グループへの追加はしない。それを求めるのは Arch Linux の流儀で、
Debian / Raspberry Pi OS の `/etc/pam.d/lightdm-autologin` に
`user ingroup autologin` の条件は無い。

## `boot_getty_enabled`

tty1 のコンソールログインを残すかどうか。**既定は残す**（画面とキーボードを繋げば入れる）。

`false` にするのは、別のプログラムが tty1 の画面を占有するときだけ（画面に直接描く
動画プレイヤー: DRM の mpv、GStreamer の `kmssink` など）。無効にすると、
その場から機器に入る手段が無くなる。

コンソールの自動ログインは agetty がするので、`boot_autologin: true` と
`boot_getty_enabled: false` の組み合わせは `assert` で止める。

## 例

```yaml
# kiosk: コンソールで自動ログインし、.bash_profile から startx
- role: boot-mode
  vars:
    boot_mode: cui
    boot_autologin: true
    boot_autologin_user: pi

# ヘッドレスのサーバ: コンソール、自動ログインなし
- role: boot-mode
  vars:
    boot_mode: cui
    boot_autologin: false

# 画面を占有するアプリ: コンソールも消す
- role: boot-mode
  vars:
    boot_mode: cui
    boot_getty_enabled: false
```

## 反映のタイミング

`systemctl set-default` は次の起動から、getty の自動ログインは
`systemctl restart getty@tty1` かリブートから効く。最後の
[overlay-enable](../overlay-enable/README.ja.md) のリブートで両方反映される。

## 確認

```sh
systemctl get-default                        # multi-user.target / graphical.target
systemctl is-enabled lightdm                 # cui なら disabled（入っていなければ not-found）
systemctl is-enabled getty@tty1
ls /etc/systemd/system/getty@tty1.service.d/  # autologin.conf があるか
pgrep -a Xorg                                # cui なら何も出ない（アプリが起動していなければ）
```

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS。
