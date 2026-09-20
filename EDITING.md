# 編集ガイド

「この内容を変えたい」ときに、どのファイルを触ればよいかの早見表。
**文章・時間・場所・店名などの中身は、ほぼすべて `data/2025/festival.json` にある。**
見た目や画面の作りを変えたいときだけ `lib/` のコードを触る。

- データの書き方（項目の意味、毎年の更新手順）→ **[data/README.md](data/README.md)**
- 環境の準備・実行・公開の方法 → **[README.md](README.md)**

---

## 1. 内容（文章・時間・場所）を変えたい

すべて **[data/2025/festival.json](data/2025/festival.json)** を編集する。翌年の作り方は [data/README.md](data/README.md) を参照。

| 変えたいもの | JSON の場所 |
|---|---|
| 回数・テーマ字・開催日・開場時間 | `edition` |
| 当日のお知らせ（出演中止など） | `notices` |
| 学長・実行委員長の挨拶 | `greetings` |
| ご来場の注意 | `rules` |
| グッズ（値段・販売場所・時間） | `goods` |
| 会場（ガレリアステージ等）と**並び順** | `venues`（この並び順がタイムテーブルの会場の順になる） |
| ステージ出演・大会・ゲスト・ビンゴ | `events` |
| 教室企画・終日の企画（営業時間・最終受付） | `projects` |
| ブース（模擬店・展示・体験） | `booths`、エリアと図は `boothAreas` |
| キャンパスマップ、施設、学食、体育館への行き方 | `campusMap` |
| 協賛企業・広告・クーポン | `sponsors` |
| 編集後記・連絡先・公式SNS | `about` |

画像（表紙、マップ、ブース図、グッズ、ゲスト写真）は **`data/2025/images/`** に置き、
JSON からファイル名で参照する。

### よくある編集

- **出演が中止になった** → `events` の該当項目に `"status": "cancelled"` を追加し、`notices` にお知らせを足す（項目は消さない）
- **時間が変わった** → `events` の `start` / `end`、`projects` の `schedule`
- **体育館への行き方ボタンを出す会場を変えたい** → `venues` の `"showGymDirections": true`

---

## 2. 画面の見た目・作りを変えたい

| 画面 | ファイル |
|---|---|
| 全体の配色、下部の5つのタブ、起動処理 | [lib/main.dart](lib/main.dart) |
| ホーム（表紙、お知らせ、今日のステージ、開幕までの日数、メニュー） | [lib/screens/home_screen.dart](lib/screens/home_screen.dart) |
| タイムテーブル（日付タブ、ステージ・大会／企画の時間の切り替え） | [lib/screens/timetable_screen.dart](lib/screens/timetable_screen.dart) |
| タイムテーブル図（横棒のグラフ、凡例、現在時刻の線） | [lib/schedule_chart.dart](lib/schedule_chart.dart) |
| 企画の一覧・ブースの一覧・検索 | [lib/screens/explore_screen.dart](lib/screens/explore_screen.dart) |
| 企画の詳細 | [lib/screens/project_detail_screen.dart](lib/screens/project_detail_screen.dart) |
| ステージ・大会の詳細 | [lib/screens/event_detail_screen.dart](lib/screens/event_detail_screen.dart) |
| マップ、体育館への行き方 | [lib/screens/map_screen.dart](lib/screens/map_screen.dart) |
| その他（挨拶・注意・グッズ・協賛・連絡先） | [lib/screens/info_screen.dart](lib/screens/info_screen.dart) |
| イベントのカード、見出し、タグ、画像の共通部品 | [lib/widgets.dart](lib/widgets.dart) |

### 仕組みに関わる部分

| 変えたいこと | ファイル |
|---|---|
| データの取得元・保存（オフライン対応） | [lib/repository.dart](lib/repository.dart) |
| JSON の項目を増やす | [lib/models.dart](lib/models.dart) …追加後、上の画面ファイルで表示する |
| 「今」の判定、確認用の日時固定 | [lib/time_utils.dart](lib/time_utils.dart) |

### アプリ名・アイコンなど

| 対象 | ファイル |
|---|---|
| Web版のタイトル、ホーム画面追加時の名前 | [web/index.html](web/index.html)、[web/manifest.json](web/manifest.json) |
| Android版のアプリ名・権限 | `android/app/src/main/AndroidManifest.xml` |
| iOS版の表示名 | `ios/Runner/Info.plist` |
| アプリのアイコン | `web/icons/`、`android/app/src/main/res/mipmap-*/`、`ios/Runner/Assets.xcassets/` |

---

## 3. 公開に関する設定

| 変えたいこと | ファイル |
|---|---|
| 自動ビルド・公開の手順、確認用ページの固定日時 | [.github/workflows/deploy.yml](.github/workflows/deploy.yml) |
| 使用するライブラリ、アプリのバージョン、同梱する `data/` | [pubspec.yaml](pubspec.yaml) |

---

## 編集したあとの確認手順

1. JSON を書き換えたら、書式が壊れていないか確認する（かっこやカンマの付け忘れが多い）
2. ローカルで表示を確認する

   ```bash
   flutter run -d chrome
   ```

3. 問題なければ公開する

   ```bash
   git add -A
   ```
   ```bash
   git commit -m "内容を更新"
   ```
   ```bash
   git push
   ```

push から数分で、本番URLに反映される。
