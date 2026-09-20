# 中京大学祭 パンフレットアプリ（chukyo_fes）

紙のパンフレットの内容を、年度ごとのデータ（`data/`）から描画する Flutter アプリ。
画像を貼り付けているのではなくデータから組み立てているので、**翌年は `data/` を差し替えるだけ**で中身が変わる。

- 本番: https://soichi-s.github.io/ChukyoGakusaiApp/
- 確認用（開催中の表示）: https://soichi-s.github.io/ChukyoGakusaiApp/preview/
- 確認用（開催前の表示）: https://soichi-s.github.io/ChukyoGakusaiApp/preview-before/

`main` ブランチに push すると、GitHub Actions が上記3つを自動で公開する。

## 内容を編集したい人へ

**[EDITING.md](EDITING.md) に「この画面を直したいときはどのファイルを編集するか」をまとめてある。**
まずそちらを読むこと。データの書き方の詳細は [data/README.md](data/README.md)。

## ファイル構成

```
data/                       … パンフレットの内容（年度ごと）。書き方は data/README.md
  index.json                … 表示する年度の指定
  2025/festival.json        … 2025年（第72回）の全内容
  2025/images/              … 表紙・マップ・ブース図・グッズ・ゲスト写真
lib/
  main.dart                 … 起動、配色、下部の5タブ
  models.dart               … festival.json を読むための型
  repository.dart           … データ取得（ネット → 端末の保存 → アプリ同梱）
  time_utils.dart           … 日本時間の扱い、確認用の日時固定
  widgets.dart              … 共通部品（イベントのカード、画像、見出しなど）
  schedule_chart.dart       … タイムテーブル図
  screens/                  … 各画面（下表を参照）
web/                        … Web版の土台（タイトル、アイコン、ホーム画面追加時の設定）
android/ ios/               … 各OS向けの設定（アプリ名、権限など）
tool/serve_web.ps1          … build\web をローカルで表示する確認用サーバー
.github/workflows/deploy.yml … 自動ビルドと公開の設定
```

## 開発環境

| 項目 | 内容 |
|---|---|
| フレームワーク | Flutter（stable） |
| 対応 | Web / Android / iOS |
| 必要なもの | Flutter SDK、Git。Android版は Android Studio（SDK・NDK・エミュレーター）|

### Windows での注意

- フォルダ名に日本語が含まれると Dart の解析ツールが動かないため、
  英数字のパス `C:\Users\user\dev\chukyo_fes`（このフォルダへのジャンクション）で作業する。
- Android のビルドには `JAVA_HOME` に Android Studio 同梱の JDK を指定する。
- Gradle がジャンクション先の日本語パスを見るため、`android/gradle.properties` に
  `android.overridePathCheck=true` を入れてある。

```bash
cd C:\Users\user\dev\chukyo_fes
```

## 実行

```bash
flutter run -d chrome
```

Android エミュレーターで動かす場合（エミュレーターを起動してから）:

```bash
flutter run -d emulator-5554
```

開催中の表示を確認したいときは、現在時刻を差し替える:

```bash
flutter run -d chrome --dart-define=DEBUG_NOW=2025-11-02T13:55
```

ネット上に公開したデータを読む場合（未指定ならアプリ同梱の `data/` を使う）:

```bash
flutter run -d chrome --dart-define=DATA_BASE_URL=https://soichi-s.github.io/ChukyoGakusaiApp/data/
```

## ビルド

```bash
flutter build web
```

```bash
flutter build apk
```

iOS 版のビルドには Mac（Xcode）またはクラウドビルド（Codemagic 等）が必要。

## 公開

`main` に push すると [.github/workflows/deploy.yml](.github/workflows/deploy.yml) が動き、
Web版と `data/` を GitHub Pages に公開する。確認用ページの固定日時は、このファイルの
`PREVIEW_NOW` / `PREVIEW_BEFORE_NOW` で変更する。

```bash
git add -A
```
```bash
git commit -m "内容を更新"
```
```bash
git push
```
