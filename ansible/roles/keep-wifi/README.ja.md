# keep-wifi

[English](README.md)

Wi-Fi の接続を自動で戻す。1 分ごとにデフォルトゲートウェイへ ping を送り、失敗が続くと
段階的に強い手を打つ（NetworkManager で再接続 → Wi-Fi ドライバの再読み込み → リブート）。

対象は Pi 内蔵の Wi-Fi（`brcmfmac` ドライバ）。

## 失敗とみなすもの

| 状態 | 意味 |
|---|---|
| デフォルトルートが無い | アソシエーションか DHCP のリースが切れた |
| ゲートウェイが ping に応えない | 経路はあるが通じない |

デフォルトルートが無いことは、飛ばさずに失敗として数える。Wi-Fi が完全に切れたとき
（いちばん復旧が要る場面）がこれで、飛ばすと復旧の段階にいつまでも進まない。

## 段階

1. 60 秒ごとに確かめる
2. 3 回続けて失敗: NetworkManager で再接続（`nmcli device disconnect` / `connect`）
3. さらに 3 回: Wi-Fi ドライバを読み込み直す（`rmmod` / `modprobe`）
4. さらに 3 回: リブート

既定値では、切れたままだとおよそ 9〜10 分でリブートに至る。早めたいときは
`keep_wifi_max_fails` か `keep_wifi_interval` を下げる。

```
[正常] <------------------------------------+
  |                                         |
  | ルートが無い、または ping 失敗           | 通じたら戻る
  v                                         |
[失敗 +1] -- 3 回未満 --------------------->+
  |                                         |
  | 3 回に達した                             |
  v                                         |
[段階 0: nmcli 再接続] -------------------->+
  |                                         |
  | さらに 3 回                              |
  v                                         |
[段階 1: ドライバ再読み込み] -------------->+
  |                                         |
  | さらに 3 回                              |
  v                                         |
[段階 2: リブート]                          |
                                            |
  どの段階からでも、通じたら戻る -----------+
```

nmcli が無いとき、Wi-Fi のデバイスが見つからないときは段階 0 を飛ばす。

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `keep_wifi_interval` | `60` | 確かめる間隔（秒） |
| `keep_wifi_max_fails` | `3` | 次の段階に進むまでの連続失敗回数 |
| `keep_wifi_disable_powersave` | `true` | Wi-Fi の省電力を切る（下記） |
| `keep_wifi_interface` | `""` | 再接続する Wi-Fi のインターフェース。空なら探す |
| `keep_wifi_reconnect_sleep` | `15` | 再接続のあと待つ秒数 |
| `keep_wifi_reload_sleep` | `10` | ドライバ再読み込みのあと待つ秒数 |
| `keep_wifi_persist_log` | `true` | ブートパーティションにイベントを記録する（下記） |
| `keep_wifi_log_path` | `/boot/firmware/keep-wifi.log` | 記録先 |
| `keep_wifi_log_max_bytes` | `65536` | これを超えたら新しい半分だけ残す |

## 省電力を切る

`brcmfmac` は省電力が既定で有効。まどろんでいるクライアントは、AP がためておいた
マルチキャストを DTIM ビーコンのときにしか受け取れず、AP 側（特にメッシュ）は取りこぼす。
その結果、**mDNS（`.local`）の名前解決がときどき失敗し**、遅延も跳ねる。

NetworkManager の全体の既定として `/etc/NetworkManager/conf.d/10-wifi-powersave.conf` に
書く。接続プロファイルに書かないのは、netplan が生成するプロファイル（`netplan-wlan0-*`）が
作り直しで上書きされるため:

```ini
[connection]
wifi.powersave = 2    # 0=既定 1=変えない 2=無効 3=有効
```

効くのは次に接続が上がったとき。ロールの中ではデバイスを上げ直さず（SSH が切れる）、
Playbook 最後のリブートで反映する。

```sh
NetworkManager --print-config | grep -A2 '^\[connection\]'   # 読み込まれたか
iw wlan0 get power_save                                      # 無線側（iw が必要）
dmesg | grep brcmf_cfg80211_set_power_mgmt
```

NetworkManager を使っていないホストでは何も変えず、警告を出す。

## イベントの記録（SD への書き込みは少なく）

overlay ファイルシステムでは journal が RAM にあり、リブートで消えるので、あとから
障害を調べられない。`keep_wifi_persist_log` を有効にすると、ブートパーティションに記録が残る。

SD カードを傷めないよう、**書くのは障害の始まりと終わりだけ**。正常なときは書かない:

| イベント | |
|---|---|
| `DOWN` | 障害の始まり（1 回の障害につき 1 回）。理由つき |
| `ACTION` | 再接続・ドライバ再読み込み・リブートをした |
| `UP` | 回復した。かかった時間つき |

```
2026-01-23T11:25:19+00:00 up=338s DOWN   no default route
2026-01-23T11:26:20+00:00 up=399s UP     gateway=192.168.1.1 recovered after 61s
```

`up=` は起動からの秒数。overlay の機器では時計が変わらない保存値から始まる
（`/var/lib/systemd/timesync/clock` が読み取り専用の層にある）ので、起動直後は NTP で
合うまで日付が何か月もずれることがある。順番は `up=` で分かる。

```sh
cat /boot/firmware/keep-wifi.log
```

## 管理

```sh
sudo systemctl status keep-wifi.timer
sudo /usr/local/bin/keep-wifi.sh          # すぐ 1 回確かめる
sudo journalctl -u keep-wifi
```

ゲートウェイは `ip route` から取る。状態（`失敗回数 段階 障害開始`）は
`/var/lib/keep-wifi/state` に置く（overlay の機器では RAM なので SD に書かない）。

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS。
