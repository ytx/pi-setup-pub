# boot-splash

[English](README.md)

Pi の起動中に画面に出るものを変える。虹色の四角を消し、Raspberry Pi のロゴと流れる起動
メッセージの代わりに、好きな画像や Plymouth のテーマを出せる。電源を入れたところから
画面を人が見る機器向け。

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `splash_hide_logo` | `false` | 左上の Raspberry Pi のロゴを消す |
| `splash_hide_text` | `false` | 起動メッセージを消す（`quiet`、`loglevel=0`） |
| `splash_hide_cursor` | `false` | 点滅するカーソルを消す |
| `plymouth_use_fkms` | `false` | KMS の代わりに FKMS を使う（下記） |
| `plymouth_hdmi_force_hotplug` | `true` | 起動時に画面が見つからなくても HDMI に出す |
| `splash_image` | （なし） | 既定のテーマの画像と入れ替える PNG（ansible を動かす側にあるファイル） |
| `plymouth_theme` | （なし） | 使う Plymouth のテーマ（入っているもの） |
| `plymouth_theme_url` | （なし） | ダウンロードして入れるテーマのアーカイブ（`.tar.gz`） |
| `plymouth_theme_name` | （なし） | そのアーカイブのテーマ名 |

入っているテーマ: `pix`（Raspberry Pi OS のもの）、`spinner`、`fade-in`、`solar`、
`spinfinity`、`glow`、`tribar`、`text`、`details`。ほかに
[adi1090x/plymouth-themes](https://github.com/adi1090x/plymouth-themes)（80 以上）や
[gnome-look.org](https://www.gnome-look.org/browse?cat=108&ord=latest) にある。

## 例

```yaml
# host_vars/raspi-01.yml: 静かな起動
splash_hide_logo: true
splash_hide_text: true
splash_hide_cursor: true

# host_vars/raspi-02.yml: 自分の画像（1920x1080 の PNG）を Playbook の横に置いて
splash_image: "{{ playbook_dir }}/splash/my-logo.png"
splash_hide_logo: true
splash_hide_text: true

# 標準のテーマ
plymouth_theme: spinner

# adi1090x のテーマ集から
plymouth_theme_url: "https://github.com/adi1090x/plymouth-themes/releases/download/v1.0/spin.tar.gz"
plymouth_theme_name: spin
```

`splash_image` を相対パスで書くと、まずロールのフォルダの中から探される。自分の画像は
フルパス（`{{ playbook_dir }}/...`）で書く。

## 変えるもの

- `/boot/firmware/config.txt`: `disable_splash=1`（虹色の四角を消す）、
  `hdmi_force_hotplug=1`、指定があれば FKMS
- initramfs に `vc4` を入れ、`simplefb` / `simpledrm` を無効にする（Plymouth が早く画面を使えるように）
- `/etc/plymouth/plymouthd.conf`: `ShowDelay=0`、`DeviceTimeout=8`、テーマ
- `/boot/firmware/cmdline.txt`: `splash`、指定に応じて `quiet`、`loglevel=0`、
  `logo.nologo`、`vt.global_cursor_default=0`
- 中身が変わったときは initramfs を作り直す。どれも次の起動から出る

## FKMS

`plymouth_use_fkms: true` で `dtoverlay=vc4-kms-v3d` を `vc4-fkms-v3d` に変える。FKMS では
ファームウェアが画面を扱うので、起動中に「信号なし」になる瞬間が無くなり、Plymouth の
アニメーションも安定する。3D のアプリは遅くなることがある。

## 確認

```sh
plymouth-set-default-theme --list     # 入っているテーマ
plymouth-set-default-theme            # 今のテーマ
# プレビュー（デスクトップのセッションから）
sudo plymouthd --mode=boot; sudo plymouth --show-splash
sudo plymouth quit
```

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS。
