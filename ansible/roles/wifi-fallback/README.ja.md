# wifi-fallback

[English](README.md)

いつもの Wi-Fi が届かない場所で使う Wi-Fi を足す（外でのデモ用のスマートフォンの
テザリングやモバイルルータなど）。

いつものネットワーク（Raspberry Pi Imager で設定したもの）には手を付けない。足す側に
**負の `connection.autoconnect-priority`** を付けるので、NetworkManager はいつもの
ネットワークが見えればそちらを、見えなければ足した方を使う:

- いつものネットワーク: 優先度 `0`（NetworkManager の既定。変えない）
- 足したネットワーク: 指定しなければ優先度 `-10`
- 出かけると足した方に切り替わり、戻るといつもの方に戻る

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `wifi_fallbacks` | `[]` | 足すネットワーク（下記） |
| `wifi_interface` | `wlan0` | インターフェース |

`wifi_fallbacks` の各項目:

| キー | 必須 | |
|---|---|---|
| `ssid` | はい | ネットワークの名前 |
| `psk` | はい | WPA のパスワード |
| `priority` | いいえ | 既定は `-10`。複数あるとき順番を付ける |

パスワードは秘密の値なので、一覧はリポジトリではなく秘密の値のディレクトリに置く
（トップの README の「秘密の値」）:

```yaml
# ~/.config/pi-setup/secrets/group_vars/all.yml
wifi_fallbacks:
  - ssid: "MyPhoneHotspot"
    psk: "..."  # leak-ok: a placeholder
  - ssid: "MobileRouter"
    psk: "..."  # leak-ok: a placeholder
    priority: -20    # テザリング（-10）のあと
```

## すること

1. NetworkManager が動いているか確かめる（動いていなければ止める）
2. `/etc/NetworkManager/system-connections/<ssid>.nmconnection` が無ければ
   `nmcli connection add` で足す
3. `nmcli connection modify` でパスワードと優先度を設定し直す（パスワードを変えても追従する）

パスワードを扱うタスクは `no_log: true` なので、画面に出ない。

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS（NetworkManager）。
