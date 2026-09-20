# 中京大学祭 パンフレットアプリ（chukyo_fes）

大学祭のパンフレットを、年度ごとの JSON データ（`data/`）から描画する Flutter アプリ。

## 構成

```
data/                  … パンフレット内容（年度ごと）。書き方は data/README.md
lib/
  main.dart            … 起動・テーマ・下部タブ
  models.dart          … festival.json の型
  repository.dart      … データ取得（ネット → 端末キャッシュ → 同梱データ）
  time_utils.dart      … 日本時間の扱い
  widgets.dart         … 共通部品
  screens/             … 各画面
tool/serve_web.ps1     … build\web をローカルで配信する確認用サーバー
```

## 開発時の注意（Windows）

フォルダ名に日本語が含まれると Dart の解析ツールが動かないため、
英数字のパス `C:\Users\user\dev\chukyo_fes`（このフォルダへのジャンクション）で作業する。

```bash
cd C:\Users\user\dev\chukyo_fes
```

## 実行

```bash
flutter run -d chrome
```

開催中の表示を確かめたいときは、現在時刻を差し替えられる:

```bash
flutter run -d chrome --dart-define=DEBUG_NOW=2025-11-02T13:55
```

ネット上に公開したデータを読む場合（未指定ならアプリ同梱の data/ を使う）:

```bash
flutter run -d chrome --dart-define=DATA_BASE_URL=https://example.github.io/chukyo-fes-data/
```

## 公開URL

| URL | 日時 | 用途 |
|---|---|---|
| https://soichi-s.github.io/ChukyoGakusaiApp/ | 実際の日時 | 本番 |
| https://soichi-s.github.io/ChukyoGakusaiApp/preview/ | 11/2 13:55 固定 | 開催中の表示確認 |
| https://soichi-s.github.io/ChukyoGakusaiApp/preview-before/ | 10/25 12:00 固定 | 開催前の表示確認 |

固定する日時は `.github/workflows/deploy.yml` の `PREVIEW_NOW` / `PREVIEW_BEFORE_NOW` で変更する。

## ビルド

```bash
flutter build web
```

iPhone 版のビルドには Mac（Xcode）またはクラウドビルド（Codemagic 等）が必要。
