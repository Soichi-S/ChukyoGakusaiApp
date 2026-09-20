import 'package:web/web.dart' as web;

// Web 版で、確認用の日時を URL（?now=2025-11-02T13:55）とやり取りする。

String? nowFromUrl() {
  final value = Uri.base.queryParameters['now'];
  return (value == null || value.isEmpty) ? null : value;
}

/// 画面を再読み込みせずにアドレスバーだけ書き換える。
/// これで、その時の表示をそのままURLとして共有できる。
void setNowInUrl(String? value) {
  final uri = Uri.base;
  final params = Map<String, String>.from(uri.queryParameters);
  if (value == null) {
    params.remove('now');
  } else {
    params['now'] = value;
  }
  // Uri.replace は queryParameters に null を渡すと「変更しない」扱いになるため、
  // 文字列として組み立てる
  final base = '${uri.origin}${uri.path}';
  final next =
      params.isEmpty ? base : '$base?${Uri(queryParameters: params).query}';
  web.window.history.replaceState(null, '', next);
}
