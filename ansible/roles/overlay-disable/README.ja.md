# overlay-disable

[English](README.md)

overlay ファイルシステムを解除して、すぐにリブートする。Playbook のこのあとの変更を
SD カードに残すため。Playbook の**最初**に置き、最後に
[overlay-enable](../overlay-enable/README.ja.md) を置く。

overlay が有効だと、ルートファイルシステムの下の層は読み取り専用で、変更はすべて
RAM（tmpfs）に入る。シャットダウンせずに電源を切られる機器には向いているが、
そのままでは Playbook で入れたものが次の起動で消えてしまう。

すること:

1. overlay から抜けられなくなったホスト（下記）なら、それを直す
2. overlay が有効なら（`raspi-config nonint get_overlay_now`）解除し
   （`raspi-config nonint do_overlayfs 1`）、その場でリブートする。もともと
   無効ならリブートしない
3. `systemd-remount-fs.service` が mask されていないことを確かめ、zram の swap を
   戻す（overlay-enable が swap を止めるので、大きなインストールでメモリが足りなくなる）

## 変数

なし。

## overlay から抜けられないホスト

`raspi-config` は overlay の有効・無効をカーネルのコマンドライン
（`/boot/firmware/cmdline.txt`）で切り替える。ところが `overlayroot` パッケージは
`/etc/overlayroot.conf` も読み、**こちらが優先される**。conf に
`overlayroot="tmpfs"` と書かれたホストでは:

- `raspi-config nonint get_overlay_now` はコマンドラインしか見ないので「無効」と答える
- しかし実際は overlay で起動するので、書いたもの（conf を戻すタスクも含めて）は
  すべて tmpfs に入り、次のリブートで消える

overlay の中からは抜け出せない。そこで、`/` が overlay でマウントされていて
（`findmnt`）、**かつ**下の層（`lowerdir=` から取得。通常 `/media/root-ro`）の conf が
overlay を強制しているときだけ、その層を rw でマウントし直して `overlayroot=""` に
書き換え、読み取り専用に戻してからリブートする。正常なホスト（conf が空）では
丸ごと飛ばし、マウントし直しもしない。

手で確かめるには:

```sh
mount | grep "^overlayroot on / "                               # overlay で動いているか
sudo grep '^overlayroot=' /media/root-ro/etc/overlayroot.conf   # "tmpfs" なら抜けられない状態
```

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS。Pi Zero W、3B、4B、5。
