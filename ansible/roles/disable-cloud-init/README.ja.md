# disable-cloud-init

[English](README.md)

`/etc/cloud/cloud-init.disabled` を作り、cloud-init を止める。

最近の Raspberry Pi OS のイメージは、Raspberry Pi Imager で設定したもの（ユーザ、
Wi-Fi、ホスト名）を、最初の起動で cloud-init が反映する。ansible で管理するように
なったあとは、cloud-init がまた動いても邪魔になるだけ（`/boot/firmware/network-config`
からネットワーク設定を書き戻すなど）。

ファイルは一度だけ作り、時刻も変えないので、2 回目からは「変更なし」になる。

## 変数

なし。

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS。
