# usb-patch

[English](README.md)

起動時に USB メモリからパッチのファイルを探し、`/` に展開する。overlay ファイルシステムの
機器向け。ネットワークも ansible も無い現場で、機器を直したり試したりできる（USB メモリを
挿して電源を入れる）。USB メモリを抜いてリブートすれば元に戻る。

> **USB メモリを挿せる人なら誰でも、機器のどのファイルでも root として書き換えられる。**
> 信用できない人が USB の口に触れられる場所では使わないこと。

## 動き

```
起動 -> usb-patch.service（oneshot。dbus と NetworkManager のあと、getty@tty1 の前）
  -> USB ディスク（/dev/sd[a-z][0-9]）を usb_patch_timeout 秒まで待つ
  -> 読み取り専用でマウント
  -> usb_patch_file_pattern に合うファイルのうち最新を選ぶ
  -> / に展開
  -> ログを残してアンマウント
-> getty が自動ログイン -> パッチが入った状態でアプリが起動
```

サービスは CPU とディスクの優先度を最低にし、dbus と NetworkManager のあとで動く。
起動の早い段階で大きなファイルを展開すると dbus が動けなくなり、NetworkManager も
一緒に失敗するため。

USB メモリが無い、パッチが無いときは、ログに残して飛ばす（エラーにしない）。

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `usb_patch_file_pattern` | `update-*.tar*` | USB メモリの最上位で探すファイル名 |
| `usb_patch_mount_point` | `/mnt/usb-patch` | USB メモリを一時的にマウントする場所 |
| `usb_patch_timeout` | `10` | USB ディスクを待つ秒数 |

## パッチのファイル

`update-YYYYMMDD-N.tar.gz`（`.tar` でもよい）という名前にする。名前順で最後のものが最新:

```
update-20260215-1.tar.gz
update-20260215-2.tar.gz
update-20260301-1.tar.gz   <- これが適用される
```

アーカイブの中のパスが、そのまま置かれる場所になる:

```sh
# /opt/myapp/app.py を差し替える
mkdir -p patch/opt/myapp
cp app.py patch/opt/myapp/
tar czf update-20260215-1.tar.gz -C patch opt
# update-20260215-1.tar.gz を USB メモリの最上位に置く
```

すでにあるディレクトリ（`/`、`/opt` など）の所有者と権限は変えない（`--no-overwrite-dir`）。
自分のフォルダで `tar ... .` として作ると、起動時に `/` がそのフォルダの所有者と権限に
なってしまい、root 以外のサービスがすべて動けなくなるため。上の例のように最上位の
フォルダを名前で指定すると、`./` の項目そのものが入らない。

## ログ

`/tmp/usb-patch.log`:

```
2026-02-15 10:30:01 --- usb-patch start ---
2026-02-15 10:30:01 Found USB device: /dev/sda1
2026-02-15 10:30:01 Latest patch: update-20260215-2.tar.gz
2026-02-15 10:30:02 Extracted to /
2026-02-15 10:30:02 Done
```

## 注意

- overlay が有効なときだけ意味がある（無効なら、ほかの変更と同じくリブートしても残る）
- Playbook では、ほかのロールと同じく [overlay-enable](../overlay-enable/README.ja.md) より前に置く

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS（overlay ファイルシステム）。
