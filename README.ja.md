# pi-setup-pub

[English](README.md)

Raspberry Pi OS を書き込んだばかりの SD カードから、キオスク画面・カメラ・小さな
サーバといった「完成した機器」を、コマンド 1 つで何度でも作るための Ansible の
ロールと Playbook です。

Raspberry Pi を家電のように使う講義・セミナーの教材として書いています。ロールは
作者が実際に使っている環境から、環境ごとの部分を取り除いて、少しずつ移しています。

## このリポジトリで示していること

- **ロールと Playbook。** ロールは使い回せる部品（読み取り専用のルート
  ファイルシステム、watchdog、キオスクのブラウザなど）。Playbook は、ある種類の
  機器をどのロールで作るかを書いたもの。
- **探しやすい inventory。** グループとホストは `inventory/hosts/` に並べ、
  ホストごとの設定は `inventory/host_vars/<ホスト>.yml`、グループごとの設定は
  `inventory/group_vars/<グループ>.yml` に置く。
- **秘密の値はリポジトリの外に。** パスワードやトークンは、同じ形の、コミット
  しないディレクトリに置く（[秘密の値](#秘密の値)）。
- **道具は公開、自分の環境は非公開。** 自分のホストや秘密の値は、これらのロールを
  使う非公開のリポジトリに置く（[自分のリポジトリから使う](#自分のリポジトリから使う)）。

## 必要なもの

- Raspberry Pi OS の Raspberry Pi。SSH で入れて `sudo` できるユーザ（例では `pi`）。
  Raspberry Pi Imager で設定できます。ロールは Debian 13（trixie）ベースの版で
  作っています。
- 制御する側（コントローラ）として、Python 3.10 以上の Linux・macOS、または別の Pi。

## はじめかた

```sh
git clone https://github.com/ytx/pi-setup-pub.git
cd pi-setup-pub
python3 -m venv venv
venv/bin/pip install -r requirements.txt
. venv/bin/activate

cd ansible
# 例の inventory を自分の Pi に向ける
$EDITOR inventory/host_vars/raspi-01.yml
ansible-playbook ping.yml
```

`ping.yml` はログインして Python を動かし、ボードの型番を表示するだけです。全部の
Pi が表示されれば、ansible でセットアップできます。

次の `base.yml` は、機器ごとの Playbook の骨組みです（overlay ファイルシステムを
解除し、パッケージを上げ、watchdog と config-persistence を入れ、overlay を戻す）。
Pi をリブートするので、使っていない Pi で試してください:

```sh
ansible-playbook base.yml --limit raspi-01
```

ロールの一覧は [ansible/roles/](ansible/roles/README.md) にあります。

## 構成

```
ansible/
├── ansible.cfg          # inventory とロールの場所
├── inventory/
│   ├── hosts/           # グループとそのホストだけ。機器の種類ごとに 1 ファイル
│   ├── group_vars/      # <グループ>.yml: グループの設定（all.yml は全ホスト）
│   └── host_vars/       # <ホスト>.yml: 1 台ごとの設定
├── roles/               # ロールごとに 1 ディレクトリ。それぞれ README.md / README.ja.md 付き
└── *.yml                # Playbook。機器の種類ごとに 1 つ
scripts/check-leaks.sh   # 秘密の値や個人的な情報のコミットを止める
```

Playbook は、`ansible.cfg` が使われるよう `ansible/` で実行します。

```sh
ansible-playbook <playbook>.yml --limit <ホスト>
```

## 秘密の値

パスワード・鍵・トークンはリポジトリに入れず、`inventory/` と同じ形で、変数だけを
置くディレクトリに書きます。

```
~/.config/pi-setup/secrets/      # chmod 700、ファイルは chmod 600
├── hosts.yml                    # 中身は all: {} だけ
├── group_vars/<グループ>.yml
└── host_vars/<ホスト>.yml
```

`ansible.cfg` に足します。

```ini
inventory = inventory, ~/.config/pi-setup/secrets
```

`hosts.yml` にグループを書かないのはわざとです。ここに書いたグループには、そのホストが
入ってしまいます。同じ変数が両方にあれば、秘密の値のディレクトリが優先です。リポジトリ
側には、使う場所に `# web_password: 秘密の値のディレクトリにある` のようなコメントを
残しておきます。

## 自分のリポジトリから使う

実際の機器の設定は、inventory や自分だけのものを入れた非公開のリポジトリに置き、
このリポジトリの隣に並べます。

```
~/git/pi-setup-pub/    このリポジトリ
~/git/my-site/ansible/
├── ansible.cfg
├── inventory/
├── roles/             # 自分だけのロール
└── *.yml              # 自分の Playbook
```

```ini
# ~/git/my-site/ansible/ansible.cfg
[defaults]
inventory = inventory, ~/.config/pi-setup/secrets
roles_path = roles:../../pi-setup-pub/ansible/roles
```

こうすると、自分の Playbook からこのリポジトリのロールを名前だけで使え、こちらで
`git pull` すれば修正も入ります。このリポジトリの Playbook も、そちらから
`ansible-playbook ../../pi-setup-pub/ansible/ping.yml` のように実行できます。

## 手を入れるときと、漏れチェック

```sh
venv/bin/pip install -r requirements-dev.txt
git config core.hooksPath .githooks      # clone ごとに 1 回
```

コミットの前に `scripts/check-leaks.sh` が動き、次のものが入っているとコミットを
止めます。vault のデータ、秘密鍵、AWS のアクセスキー ID、URL の中のパスワード、
そのまま書いたパスワードやトークン、例に使う `192.168.1.0/24` 以外のプライベート
IPv4 アドレス。例には `example.com` と `192.168.1.x` を使ってください。

さらに、自分のドメイン・SSID・ネットワークなどのパターンを、このリポジトリに
**入れない**ファイルから読みます（既定は `../pi-setup/pub-leak-patterns.txt`、または
`$PI_SETUP_LEAK_PATTERNS`。1 行に 1 つの拡張正規表現）。コミットの作者の名前と
メールアドレスもこれと照らし合わせます。GitHub Actions は、push のたびに一般的な
チェック、yamllint、ansible-lint を実行します。

## ライセンス

[MIT](LICENSE)
