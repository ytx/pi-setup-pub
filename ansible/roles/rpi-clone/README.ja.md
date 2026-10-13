# rpi-clone

[English](README.md)

動いている Pi の SD カードを、別のカード（USB カードリーダーに挿したもの）に複製し、
複製に別のホスト名を付けるための道具。設定済みの 1 台から何台も作るときに使う。

## 入れるコマンド

| コマンド | |
|---|---|
| `clone-dd` | 起動しているカードを `dd` で複製する。overlay が有効でも使える |
| `clone-rename` | 複製したカードのホスト名を変える |
| `rpi-clone` | [billw2/rpi-clone](https://github.com/billw2/rpi-clone)。ファイル単位で複製し、パーティションの大きさも合わせる。overlay が無効のときだけ |
| `rpi-clone-setup` | その設定の補助 |

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `rpi_clone_base_url` | `https://raw.githubusercontent.com/billw2/rpi-clone/master` | rpi-clone のダウンロード元 |
| `rpi_clone_install_dir` | `/usr/local/sbin` | コマンドの置き場所 |

## clone-dd（おすすめ）

overlay が有効でも使える。起動しているカード（`/dev/mmcblk0`）を、最後のパーティションの
終わりまで（カード全体ではない）複製する。書き込む前に確認する:

```sh
sudo clone-dd sdb                 # /dev/sdb に複製
sudo clone-dd sdb raspi-02        # 複製して、ホスト名を raspi-02 にする
```

複製先が小さければ止まる。同じ容量の表示でもカードごとにわずかに大きさが違うので、
ルートパーティションをカードいっぱいに広げていると、「同じ容量」のカードへの複製が
失敗することがある。先にルートパーティションを縮めておくと安全（別のマシンで、
カードをリーダーに挿して）:

```sh
sudo e2fsck -f /dev/sdb2
sudo resize2fs /dev/sdb2 6G
sudo parted /dev/sdb resizepart 2 6.5GB
```

## clone-rename

```sh
sudo clone-rename sdb raspi-02
```

複製のルート（パーティション 2）とブート（パーティション 1）をマウントし、`/etc/hostname` に
新しい名前を書き、`/etc/hosts` と（あれば）`/boot/firmware/user-data`（cloud-init）の古い名前を
置き換えて、アンマウントする。

## rpi-clone

```sh
sudo rpi-clone sdb
```

overlay が無効のときだけ。使い方は rpi-clone 自身の説明を見る。

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS。
