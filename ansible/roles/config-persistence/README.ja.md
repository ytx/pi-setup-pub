# config-persistence

[English](README.md)

overlay ファイルシステムの機器で、選んだファイルやディレクトリをリブートしても残す。
`/boot/firmware/config/`（ブートパーティション。[overlay-enable](../overlay-enable/README.ja.md)
が書き込めるままにしている）に保存し、起動のたびに元の場所へ戻す。

セットアップのあとに機器の上で変わるもの（ログインのトークン、ブラウザの
ローカルストレージ、Web 画面で変えた設定など）に使う。

入れるもの:

- `/boot/firmware/config/save.sh` と `load.sh`、残すものの一覧 `files.json`
  （空で作る。上書きはしない）
- 起動時、ネットワークより前に `load.sh --all` を実行する `config-persistence.service`
- 両方のスクリプトが使う `jq`

## 保存

```sh
# ファイルかディレクトリ（パスで指定。相対パスも可）
sudo /boot/firmware/config/save.sh ~/.config/rclone/rclone.conf
sudo /boot/firmware/config/save.sh "$HOME/.config/chromium/Default/Local Storage"

# 一覧にあるものを全部保存し直す（変わったあと）
sudo /boot/firmware/config/save.sh --all

# 前回の起動で何が起きたか
cat /tmp/load.sh-log
```

ロールから自分のファイルを登録するときも同じで、ファイルができたあとに
`save.sh <パス>` を実行するタスクを置く。

`files.json`:

```json
{
  "files": [
    { "name": "rclone.conf", "path": "/home/pi/.config/rclone/rclone.conf",
      "type": "file", "owner": "pi", "group": "pi", "mode": "600" },
    { "name": "Local Storage.tar", "path": "/home/pi/.config/chromium/Default/Local Storage",
      "type": "directory", "owner": "pi", "group": "pi" }
  ]
}
```

- ディレクトリは tar で保存し（モードを保つ）、元の所有者で戻す。中のファイルの
  所有者はすべて同じでなければならない
- `/` や最上位のシステムディレクトリ（`/etc`、`/home` など）への復元は、保存時にも
  読み込み時にも拒否する
- **ブートパーティションは FAT32 で、パーミッションが無い。** そこに保存したものは
  （パスワードやトークンも）、SD カードを手にした人なら誰でも読める

## 変数

なし。

## トラブルシューティング

保存で `Read-only file system` になる: ブートパーティションが読み取り専用でマウント
されている。overlay-enable が `/etc/fstab` で書き込み可にしているが、手で直すなら:

```sh
mount | grep /boot/firmware
sudo mount -o remount,rw /boot/firmware
```

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS。Pi Zero W、3B、4B、5。
