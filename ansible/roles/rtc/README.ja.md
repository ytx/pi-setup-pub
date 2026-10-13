# rtc

[English](README.md)

I2C のリアルタイムクロック（既定は DS3231）で時刻を保ち、ネットワークの無い Pi でも
停電のあとに時刻が分かるようにする。

- ネットワークがあれば NTP（systemd-timesyncd）が時刻を合わせ、カーネルがそれを RTC に書き戻す
- 無ければ RTC の時刻を使う
- RTC が繋がっていなくても壊れない（カーネルは `/dev/rtc0` が無いのでそのまま進む）

すること:

1. I2C を有効にする（`raspi-config nonint do_i2c 0`）
2. `/boot/firmware/config.txt` に `dtoverlay=i2c-rtc,<チップ>` を足す（無ければ）。
   次の起動から効く

残りはカーネルがする（`hwclock` のサービスは要らない）。起動時に RTC から読み、
NTP で合ったあとはときどき、またシャットダウン時に RTC へ書き戻す。

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `rtc_chip` | `ds3231` | チップ名。`i2c-rtc` オーバーレイでの名前（`ds1307`、`pcf8523` など） |

## 確認

```sh
sudo i2cdetect -y 1                  # 0x68 に "UU" ならドライバが使っている
cat /sys/class/rtc/rtc0/date /sys/class/rtc/rtc0/time
timedatectl                          # NTP で同期しているか
```

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS、DS3231 モジュール。
