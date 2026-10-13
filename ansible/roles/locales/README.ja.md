# locales

[English](README.md)

SSH クライアントが求めるロケールを Pi に用意する。

## 解決する問題

sshd はクライアントの `LANG` と `LC_*` を受け取る（`AcceptEnv`）。Pi に無いロケールを
送られると、ログインのたびに警告が出る:

```
bash: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8): No such file or directory
```

**警告だけでは済まない。** セッションは C ロケール（UTF-8 ではない）に落ち、
日本語などを含むファイル名が正しく表示できなくなる。

Raspberry Pi OS のイメージには `en_GB.UTF-8` しか入っていない一方、macOS の Terminal は
既定で `LC_ALL=en_US.UTF-8` を送る。そのため Mac からログインすると必ずこうなる。

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `locales_install_all` | `true` | `locales-all` を入れる（全ロケール。生成は不要） |
| `locales_generate` | `["en_US.UTF-8 UTF-8"]` | `locales_install_all: false` のとき生成するロケール。`/etc/locale.gen` の書き方で |
| `locales_default` | `""` | `/etc/default/locale` の `LANG`。空なら変えない |

`locales-all` はディスクで約 **231MB**（ダウンロードは 11MB）。`locales` パッケージを
置き換えず、横に入る。SD カードに余裕が無ければ `locales_install_all: false` にして、
必要なものだけ並べる。

## 手ではなく Playbook で入れる

overlay の機器で `apt install locales-all` を手で実行すると、overlay の上の層、
つまり RAM に書かれる:

```
$ df -h /
overlayroot     453M  6.5M  447M   2% /       ← tmpfs（RAM）
```

231MB は Pi 3B のメモリの 4 分の 1 で、しかも次のリブートで消える。Playbook は
最初に [overlay-disable](../overlay-disable/README.ja.md) を通すので、SD カードに書かれる。
`locale-gen` を手で実行した結果も同じく消える。

## 例

```yaml
roles:
  - overlay-disable
  - locales                    # locales-all
```

```yaml
# ディスクを節約するとき
- role: locales
  vars:
    locales_install_all: false
    locales_generate:
      - "en_US.UTF-8 UTF-8"
      - "ja_JP.UTF-8 UTF-8"
```

## このロールを使わない場合（クライアント側）

Pi に手を入れないなら、クライアントの `~/.ssh/config` で Pi にあるロケールを送らせる:

```
Host *
  SetEnv LC_ALL=en_GB.UTF-8
```

macOS なら Terminal の設定で「起動時にロケール環境変数を設定」を外しても同じ。
**`SendEnv -LC_*` は効かない。** ssh は `-o` とユーザの設定を先に読み、そのあと
`/etc/ssh/ssh_config` の `SendEnv LANG LC_*` が加え直すため。

## 確認

```sh
ssh <host> 'locale -a | wc -l'                              # locales-all なら数百
LC_ALL=en_US.UTF-8 ssh -o SendEnv=LC_ALL <host> 'locale'   # 警告が出なければ OK
```

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS。
