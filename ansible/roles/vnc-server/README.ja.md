# vnc-server

[English](README.md)

VNC のリモートデスクトップを有効（または無効）にする。Pi の画面を別のコンピュータから
見て操作できるようになる。

デスクトップ入りの Raspberry Pi OS 向け。Raspberry Pi OS には VNC サーバが 2 つあり、
Wayland のデスクトップには **wayvnc**、X11 には **RealVNC** を使う。

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `vnc_enabled` | `true` | `false` で VNC を止める |
| `vnc_server_type` | `auto` | どちらのサーバか（下記） |

| `vnc_server_type` | |
|---|---|
| `auto` | `raspi-config` に任せる（Wayland なら wayvnc、X11 なら RealVNC） |
| `realvnc` | RealVNC。別の方法で起動した X11（`startx` で動く kiosk など）で、raspi-config の判断が外れるとき。wayvnc を止め、RealVNC のトレイアイコンを消す |
| `wayvnc` | wayvnc。Wayland 向け。RealVNC を止める |

```yaml
# host_vars/raspi-01.yml: X11 の kiosk
vnc_server_type: realvnc
```

## 接続

VNC ビューアで Pi のホスト名かアドレスに接続し、Pi のユーザ名とパスワードでログインする。

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS。
