// Web 以外（Android / iOS）では URL がないので何もしない。
// 実体は preview_url_web.dart（time_utils.dart の条件付き import で切り替わる）。

String? nowFromUrl() => null;

void setNowInUrl(String? value) {}
