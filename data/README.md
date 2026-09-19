# 大学祭アプリ コンテンツデータ

アプリは起動時に `index.json` を読み、`currentYear` の年度フォルダにある `festival.json` を表示する。
画像パスは `festival.json` と同じフォルダ（例: `2025/`）からの相対パス。

## ファイル構成

```
data/
  index.json            … 表示する年度の指定
  2025/
    festival.json       … その年のパンフレット内容すべて
    images/             … マップ・表紙・ゲスト写真・広告など
```

## festival.json の主なキー

| キー | 内容 | アプリでの使い道 |
|---|---|---|
| `edition` | 回数・テーマ字・開催日（`days`） | ホーム、日付タブ |
| `notices` | 当日のお知らせ（出演辞退など） | お知らせ一覧・ホームのバナー |
| `greetings` / `rules` / `goods` | 挨拶・注意事項・グッズ | 案内ページ |
| `venues` | 会場（ガレリアステージ等） | `events[].venueId` から参照 |
| `events` | 時刻が決まった催し（ステージ・大会・ゲスト・ビンゴ） | ステージのタイムテーブル、**開始前通知** |
| `projects` | 期間中ずっと開いている企画（日ごとの営業時間つき） | 企画一覧、全体タイムテーブル |
| `boothAreas` / `booths` | 出店エリアと各ブース | ブース一覧（エリアで絞り込み） |
| `campusMap` | マップ画像・施設・学食 | マップページ |
| `sponsors` | 寄付企業と広告 | 協賛ページ |
| `about` | 編集後記・連絡先・SNS | その他ページ |

### events の書き方

```json
{
  "id": "ev-1102-raf",          // 年内で重複しないID（通知の識別にも使う）
  "category": "stage",          // eventCategories の id
  "date": "2025-11-02", "start": "16:15", "end": "17:45",
  "venueId": "galleria",
  "title": "R.A.F",
  "status": "cancelled",        // 中止時のみ。省略時は通常開催
  "notify": true                // 開始前通知の対象にするか
}
```

- 時刻は `"HH:mm"`（日本時間）。
- `venues` に `"showGymDirections": true` を付けた会場（体育館・グラウンド）の企画は、
  詳細画面に「体育館への行き方を見る」ボタンが出る。`projects` の場合は `location.venueId` で会場を指定する。
- 出演が取り消しになったら、項目を消さずに `status: "cancelled"` を付け、`notices` にお知らせを追加する。

## 毎年の更新手順

1. `data/2026/` を作り、前年の `festival.json` をコピーして書き換える。
2. 画像を `data/2026/images/` に入れる。
3. `index.json` の `currentYear` と `editions` を更新する。
4. `updatedAt` を更新してから公開する（アプリ側の更新検知に使う）。
