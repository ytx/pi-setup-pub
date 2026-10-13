# clear-wifi

[English](README.md)

Pi が覚えている Wi-Fi の接続をすべて消す。機器を人に渡す前や、別の Pi から複製した
SD カードに使う。

すること:

1. NetworkManager の Wi-Fi 接続プロファイルをすべて削除する（`nmcli`）
2. `/etc/wpa_supplicant/wpa_supplicant.conf` があれば、ネットワークの記述を空にする
   （古いリリース）
3. `/boot/firmware/network-config`（Raspberry Pi Imager の設定を cloud-init が読むファイル）を削除する

**有線 LAN（またはコンソール）で流すこと。** Wi-Fi 経由だと、ansible が使っている
接続そのものが切れる。

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `clear_wifi_country` | `""` | 空にした `wpa_supplicant.conf` に書く Wi-Fi の国コード（`GB`、`US`、`JP` など）。空なら書かない |

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS。
