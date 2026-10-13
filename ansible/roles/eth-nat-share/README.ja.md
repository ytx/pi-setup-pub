# eth-nat-share

[English](README.md)

この Pi の Wi-Fi 接続を、有線 LAN の口に直結した 1 台の機器と共有する。機器は DHCP で
アドレスをもらい、NAT を通して LAN とインターネットに出られる。Wi-Fi の無い機器
（古い Pi やマイコンボード）を、ケーブル 1 本でつなぐための構成。

```
[LAN / インターネット]
      | Wi-Fi (DHCP)
+-----+-----------------------------+
| この Pi (raspi-01)                |
|  wlan0: DHCP（上り）              |
|  eth0:  10.42.0.1/30 (shared)     | <- DHCP・DNS・NAT は NetworkManager が構成
+-----+-----------------------------+
      | 有線ケーブル
+-----+-----------------------------+
| つないだ機器（設定不要）          |
|  eth0: 10.42.0.2 (DHCP)           | <- MAC に関係なく常にこのアドレス
+-----------------------------------+
```

## 仕組み

- NetworkManager の `ipv4.method shared` を使う。dnsmasq（DHCP サーバと DNS フォワーダ）の
  起動、IP フォワーディング、NAT（masquerade）のルールまで NetworkManager がする。
  自分で dnsmasq や iptables を設定しなくてよい
- サブネットを **/30** にすると配れるアドレスが 1 つだけになり、つないだ機器は
  **MAC に関係なく常に同じアドレス**をもらう（`10.42.0.1/30` なら、この Pi が `.1`、機器が `.2`）
- 1 つしかないので、前につないだ機器のリースが邪魔になりうる。`dhcp-authoritative`
  （`/etc/NetworkManager/dnsmasq-shared.d/` に置く）で、それでもすぐ配るようにしている
- そのインターフェースに前から付いていた NetworkManager の接続（固定アドレスなど）は
  `autoconnect no` にする
- その場では切り替えない（流している SSH がそのインターフェース経由かもしれないため）。
  **次のリブートから有効**（最後の [overlay-enable](../overlay-enable/README.ja.md) のリブートでよい）

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `share_interface` | `eth0` | 共有する（下りの）インターフェース |
| `share_connection_name` | `{{ share_interface }}-shared` | NetworkManager の接続名 |
| `share_ip` | `10.42.0.1/30` | この Pi 側のアドレス（CIDR）。/30 で機器のアドレスが決まる。LAN で使っていないサブネットにする |

## 例

```yaml
roles:
  - static-ip        # static_ip が無ければ何もしない
  - keep-wifi
  - wifi-fallback
  - eth-nat-share

post_tasks:
  - name: Enable the overlay filesystem
    ansible.builtin.include_role:
      name: overlay-enable
```

この Pi を経由して、つないだ機器に SSH するには:

```
# ~/.ssh/config
Host raspi-01-device
  HostName 10.42.0.2
  User pi
  ProxyJump raspi-01
```

## 確認（リブートのあと）

```sh
# この Pi で
nmcli connection show            # eth0-shared が有効
ip addr show eth0                # 10.42.0.1/30
ps aux | grep dnsmasq            # NetworkManager の dnsmasq に --dhcp-range=10.42.0.2,10.42.0.2
ip route                         # デフォルトルートは wlan0 のまま

# つないだ機器で
ip addr show eth0                # 10.42.0.2
ping -c1 1.1.1.1                 # NAT を通って外に出られる
```

## 注意

1. **先に Wi-Fi が使えること。** 適用後、有線の口は機器のためだけになるので、この Pi への
   SSH は Wi-Fi 経由になる。適用前に AP につながることを確かめる（keep-wifi・wifi-fallback と
   一緒に使うとよい）。`share_interface` に `static_ip` を設定していたら、inventory から外す
   （static-ip とぶつかる）
2. **/30 の shared モードは NetworkManager の版によって違うかもしれない。** 最初に
   dnsmasq の `--dhcp-range` が `.2,.2` になっているか確かめる。うまくいかなければ、
   `dhcp-range` を固定した自前の dnsmasq に切り替える（このロールの範囲外）
3. **つなげるのは 1 台だけ。** /30 には 1 台分しか無い。スイッチで何台もつなぐなら
   `share_ip` を広げる（/24 など）。そのときアドレスは固定されない
4. **機器の側は設定不要。** DHCP クライアントが動いていれば（Raspberry Pi OS は動いている）、
   つなぐだけでアドレス・DNS・デフォルトルートが入る

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS。Pi 4B。
