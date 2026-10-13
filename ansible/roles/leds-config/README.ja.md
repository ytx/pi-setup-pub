# leds-config

[English](README.md)

Pi の 2 つの LED（ACT＝緑、PWR＝赤）に何を表示させるか、または消すかを設定する
（寝室やショーケースに置く機器など）。`/boot/firmware/config.txt` に書き、次の起動から効く。

## 変数

| 変数 | 初期値 | |
|---|---|---|
| `leds_enabled` | `true` | `false` で両方消す（下の `*_off_*` の値を書く） |
| `act_led_trigger` | `mmc0` | ACT: `none`、`mmc0`（SD カードのアクセス）、`heartbeat`、`timer`、`default-on` |
| `act_led_activelow` | `on` | ACT の極性: `on` / `off` |
| `pwr_led_trigger` | `default-on` | PWR: `none`、`default-on`、`heartbeat`、`timer` |
| `pwr_led_activelow` | `on` | PWR の極性: `on` / `off` |
| `act_led_off_trigger` / `act_led_off_activelow` | `none` / `off` | `leds_enabled: false` のとき ACT に書く値 |
| `pwr_led_off_trigger` / `pwr_led_off_activelow` | `off` / `on` | `leds_enabled: false` のとき PWR に書く値 |

inventory での例:

```yaml
# host_vars/raspi-01.yml: 両方消す
leds_enabled: false

# host_vars/raspi-02.yml: 緑を心拍のように点滅
act_led_trigger: heartbeat
```

## 注意

- PWR LED の極性は機種で違う。**Pi 3B+** は GPIO エクスパンダ経由の active-low で、
  `trigger=none`・`activelow=off` では消えない。そのため「消す」ときの既定値は、
  3B+ で消える `trigger=off`・`activelow=on` にしてある。別の機種で消えなければ、
  そのホストで `pwr_led_off_*` を上書きする
- LED ごとの行は `config.txt` の `# BEGIN/END ANSIBLE MANAGED` の間に入り、
  次に流したときに置き換わる

## 確認した環境

Debian 13（trixie）ベースの Raspberry Pi OS（上の PWR LED の注意は Pi 3B+ で確かめたもの）。
