import 'package:flutter/foundation.dart';

import 'preview_url_stub.dart'
    if (dart.library.js_interop) 'preview_url_web.dart';

// 日時はすべて日本時間の「壁時計」として扱う。
// 端末のタイムゾーンに左右されないよう、UTC の DateTime に日本時間の値を入れて比較する。

/// ビルド時に固定する日時:
///   flutter run --dart-define=DEBUG_NOW=2025-11-02T13:55
const _debugNow = String.fromEnvironment('DEBUG_NOW');

/// 実行中に日時を切り替えられるようにするか。
/// 確認用ビルド（/preview/ や TestFlight 向け）だけ true にする:
///   flutter build web --dart-define=ALLOW_TIME_OVERRIDE=true
/// ストアで配布する本番ビルドでは指定しないため、機能ごと無効になる。
const timeOverrideAllowed =
    bool.fromEnvironment('ALLOW_TIME_OVERRIDE') || kDebugMode;

/// 表示に使う日時。null なら実際の日時（または DEBUG_NOW）を使う。
final previewClock = ValueNotifier<DateTime?>(null);

/// 起動時に一度だけ呼ぶ。URL の ?now=2025-11-02T13:55 か DEBUG_NOW を初期値にする。
void initPreviewClock() {
  if (!timeOverrideAllowed) return;
  final fromUrl = nowFromUrl();
  final initial = fromUrl ?? (_debugNow.isEmpty ? null : _debugNow);
  if (initial == null) return;
  previewClock.value = tryParseJst(initial);
}

/// 日時を切り替える。null に戻すと実際の日時に戻る。URL にも反映する。
void setPreviewClock(DateTime? value) {
  if (!timeOverrideAllowed) return;
  previewClock.value = value;
  setNowInUrl(value == null ? null : formatJst(value));
}

DateTime jstNow() {
  if (timeOverrideAllowed) {
    // 確認用ビルドでは DEBUG_NOW は初期値としてのみ使う（initPreviewClock）。
    // そのため「解除」すると実際の日時に戻る。
    final override = previewClock.value;
    if (override != null) return override;
  } else if (_debugNow.isNotEmpty) {
    return DateTime.parse('${_debugNow}Z');
  }
  return DateTime.now().toUtc().add(const Duration(hours: 9));
}

/// "2025-11-02" と "13:55" から日本時間の日時を作る
DateTime jst(String date, String hm) => DateTime.parse('${date}T$hm:00Z');

/// "2025-11-02T13:55" を読む。読めなければ null。
DateTime? tryParseJst(String value) => DateTime.tryParse('${value}Z');

/// "2025-11-02T13:55"
String formatJst(DateTime t) =>
    '${jstDateString(t)}T${two(t.hour)}:${two(t.minute)}';

/// "2025/11/02 13:55"
String formatJstForDisplay(DateTime t) =>
    '${t.year}/${two(t.month)}/${two(t.day)} ${two(t.hour)}:${two(t.minute)}';

String jstDateString(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${two(t.month)}-${two(t.day)}';

String two(int n) => n.toString().padLeft(2, '0');
