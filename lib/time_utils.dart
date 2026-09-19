// 日時はすべて日本時間の「壁時計」として扱う。
// 端末のタイムゾーンに左右されないよう、UTC の DateTime に日本時間の値を入れて比較する。

/// 動作確認用に現在時刻を差し替えられる:
///   flutter run --dart-define=DEBUG_NOW=2025-11-02T13:55
const _debugNow = String.fromEnvironment('DEBUG_NOW');

DateTime jstNow() {
  if (_debugNow.isNotEmpty) return DateTime.parse('${_debugNow}Z');
  return DateTime.now().toUtc().add(const Duration(hours: 9));
}

/// "2025-11-02" と "13:55" から日本時間の日時を作る
DateTime jst(String date, String hm) => DateTime.parse('${date}T$hm:00Z');

String jstDateString(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
