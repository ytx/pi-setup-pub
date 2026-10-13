# watchdog

[English](README.md)

システムが固まったとき、SoC のハードウェア watchdog で自動的に再起動させる:

- `/boot/firmware/config.txt` に `dtparam=watchdog=on`
- systemd が watchdog を叩く（`/etc/systemd/system.conf` の `RuntimeWatchdogSec`）。
  systemd がその時間応答しないと、ハードウェアがボードをリセットする
- 別の `watchdog` デーモンが入っていれば止めて無効にする（両方で動かさないため）

どちらも次の起動から効く（最後に [overlay-enable](../overlay-enable/README.ja.md) が
リブートする）。

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `watchdog_timeout` | `10` | systemd が応答しなくなってからリセットするまでの秒数 |

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS。Pi Zero W、3B、4B、5。
