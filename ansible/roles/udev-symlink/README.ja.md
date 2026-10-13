# udev-symlink

[English](README.md)

USB のシリアル機器に決まった名前を付ける。GPS 受信機と USB シリアル変換は、
`/dev/ttyACM0` や `/dev/ttyUSB0` のどれになるか起動ごとに変わりうる。これを使うと、
プログラムからは `/dev/ttyGPS` のような名前で開ける。

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `udev_devices` | `[]` | 機器と名前の一覧（下記） |

```yaml
# host_vars/raspi-01.yml
udev_devices:
  - vendor_id: "1546"    # USB のベンダー ID
    product_id: "01a7"   # USB のプロダクト ID
    symlink: "ttyGPS"    # -> /dev/ttyGPS
  - vendor_id: "0403"
    product_id: "6001"
    symlink: "ttySerial"
```

ID は `lsusb` で分かる:

```
Bus 001 Device 004: ID 1546:01a7 U-Blox AG [u-blox 7]
                       ^^^^ ^^^^
                     ベンダー プロダクト
```

## すること

`/etc/udev/rules.d/99-usb-symlinks.rules` を書き（機器ごとに 1 行、`tty` サブシステム向け）、
udev のルールを読み直させる。一覧が空なら何もしない。

- リンクは機器を挿すとでき、抜くと消える
- 元の名前（`/dev/ttyACM0` など）もそのまま使える
- 同じベンダー ID・プロダクト ID の機器を 2 つ挿すと、どちらにリンクが付くかは決まらない
- すでに挿してある機器には、次に挿し直すかリブートしたときにリンクが付く

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS。
