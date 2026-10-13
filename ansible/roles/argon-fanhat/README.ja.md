# argon-fanhat

[English](README.md)

Argon40 の Fan HAT（I2C 接続）のファンを、CPU の温度に合わせて Argon40 のサービスで回す。

すること:

1. `python3-libgpiod`、`python3-smbus`、`i2c-tools` を入れ、I2C を有効にする
2. Argon40 のスクリプトを `/etc/argon` に、ファン設定の道具を `/usr/local/bin/argon-config` に
   ダウンロードする
3. 温度の段階を `/etc/argononed.conf` に書く
4. `argononed.service` を入れて起動する。段階を変えたら再起動する

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `argon_fan_thresholds` | 下記 | 温度（℃）とファンの速さ（%）の組 |
| `argon_download_url` | `https://download.argon40.com/scripts` | スクリプトのダウンロード元 |
| `argon_install_dir` | `/etc/argon` | 置き場所 |

```yaml
# 初期値
argon_fan_thresholds:
  - { temp: 55, speed: 30 }    # 55℃ から 30%
  - { temp: 60, speed: 55 }
  - { temp: 65, speed: 100 }
```

```yaml
# host_vars/raspi-01.yml: 早めに、細かく
argon_fan_thresholds:
  - { temp: 50, speed: 25 }
  - { temp: 55, speed: 50 }
  - { temp: 60, speed: 75 }
  - { temp: 65, speed: 100 }
```

## 管理

```sh
sudo systemctl status argononed
argon-config                     # Argon40 の対話式の設定（任意）
```

スクリプトは Argon40 が公開しているものをダウンロードする（1 度だけ。すでにあれば取り直さない）。
このリポジトリには入っていない。新しい版にするときは Pi の上のファイルを消す。

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS と Argon Fan HAT。
