# static-ip

[English](README.md)

Pi の IPv4 アドレスを固定する。NetworkManager（今のリリース）と dhcpcd（古いリリース）の
両方に対応。インターフェースに付いている NetworkManager の接続は自分で探す。

`static_ip` の無いホストは、接続が manual のままなら DHCP に戻し、そうでなければ
何もしない。すべての Playbook に入れておき、必要なホストだけアドレスを固定できる。

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `static_ip` | （なし） | アドレス。プレフィックスは付けない（`/24` を足す）。ふつうは `host_vars/<host>.yml` に |
| `network_interface` | `wlan0` | インターフェース（有線なら `eth0`） |
| `gateway` | `""` | ルータ。`static_ip` を使うなら必須 |
| `dns_servers` | `[]` | ネームサーバ |
| `static_ip_revert` | `true` | `static_ip` が無いとき、manual のままの接続を DHCP に戻す。`false` なら何もしない |

`gateway` と `dns_servers` はふつう全ホストで同じ:

```yaml
# inventory/group_vars/all.yml
gateway: 192.168.1.1
dns_servers:
  - 192.168.1.1
  - 1.1.1.1

# inventory/host_vars/raspi-01.yml
static_ip: 192.168.1.50
network_interface: eth0
```

## 注意

- 新しいアドレスはすぐではなく、次のリブートから効く（流している SSH を切らないため）。
  最後の [overlay-enable](../overlay-enable/README.ja.md) のリブートで反映される
- プレフィックスは常に `/24`
- ホストから `static_ip` を消すと、次のリブートから DHCP（`ipv4.method auto`）に戻る。
  すでに DHCP の接続には何もしないが、手で（nmtui・nmcli）固定した接続も戻す。
  手で固定したものを残すなら `static_ip_revert: false`

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS（NetworkManager）。
