# overlay-enable

[English](README.md)

読み取り専用のルート＋overlay ファイルシステムで動くように整え、overlay を有効にして
リブートする。Playbook の**最後**（`post_tasks`）に置き、最初に
[overlay-disable](../overlay-disable/README.ja.md) を置く:

```yaml
  post_tasks:
    - name: Enable the overlay filesystem
      ansible.builtin.include_role:
        name: overlay-enable
```

すること:

- swap を止める: dphys-swapfile（古いリリース）と zram（今のリリース。
  systemd-zram-generator が起動のたびに作り直すので、ユニットを mask する）。
  overlay の上の swap は RAM を使うだけ
- initramfs で `overlay` モジュールを読み込む。Pi のカーネルによっては overlayroot の
  フックが自分で読み込めず、overlay なしで起動してしまう
- `/etc/overlayroot.conf` を `overlayroot=""` にしておき、`raspi-config` が書き換える
  カーネルのコマンドラインだけで決まるようにする（そうしないとどうなるかは
  [overlay-disable](../overlay-disable/README.ja.md)）
- rsyslog に流量制限をかけ、ログで RAM が埋まらないようにする
- `systemd-remount-fs.service` を `/` が読み取り専用のときだけ動かす。overlay では
  カーネルが `/` のマウントし直しを拒むのでユニットが失敗し、NetworkManager が
  起動しない（ネットワークが無くなる）。mask すると overlay なしの起動が壊れる
- overlay を有効にし（`raspi-config nonint do_overlayfs 0`）、`/boot/firmware` は
  書き込めるままにする（[config-persistence](../config-persistence/README.ja.md) 用）
- リブートする

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `overlay_enabled` | `true` | `false` なら上のことは何もせず、リブートだけする。変更を続ける開発用ボード向け |

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS。Pi Zero W、3B、4B、5。
