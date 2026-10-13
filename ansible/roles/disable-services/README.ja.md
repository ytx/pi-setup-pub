# disable-services

[English](README.md)

並べた systemd のサービスを停止・無効化する。用途が一つの機器に要らないもの
（Bluetooth、Avahi、デスクトップの補助プログラムなど）に使う。入っていないサービスは、
Playbook を止めずに飛ばす。

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `services_to_disable` | `[]` | 停止・無効化するユニット名 |

## 例

```yaml
roles:
  - role: disable-services
    vars:
      services_to_disable:
        - bluetooth
        - avahi-daemon
```

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS。
