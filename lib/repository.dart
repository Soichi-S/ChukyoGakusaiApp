import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// データの取得元。
enum DataSource { remote, cache, bundled }

class LoadedFestival {
  final Festival festival;
  final DataSource source;

  /// 画像パスの基点（remote/cache は URL、bundled はアセットパス）
  final String imageBase;

  const LoadedFestival(this.festival, this.source, this.imageBase);

  bool get imagesFromNetwork => source != DataSource.bundled;

  String imageUrl(String path) => '$imageBase$path';
}

/// パンフレットデータの読み込み。
///
/// 1. ネット上の data/（[remoteBaseUrl]）から最新を取得し、端末に保存
/// 2. 取得できなければ、前回保存したデータ
/// 3. それもなければ、アプリに同梱した data/
///
/// 公開先の URL はビルド時に指定する:
///   flutter run --dart-define=DATA_BASE_URL=https://example.github.io/chukyo-fes-data/
class FestivalRepository {
  static const remoteBaseUrl = String.fromEnvironment('DATA_BASE_URL');
  static const _cacheJsonKey = 'festival_json';
  static const _cacheBaseKey = 'festival_image_base';

  Future<LoadedFestival> load() async {
    if (remoteBaseUrl.isNotEmpty) {
      try {
        return await _loadRemote();
      } catch (_) {
        // 電波が悪い会場でも表示できるよう、失敗時はキャッシュへ
      }
      final cached = await _loadCache();
      if (cached != null) return cached;
    }
    return _loadBundled();
  }

  Future<LoadedFestival> _loadRemote() async {
    final base = remoteBaseUrl.endsWith('/') ? remoteBaseUrl : '$remoteBaseUrl/';
    final index = await _getJson(Uri.parse('${base}index.json'));
    final path = _currentPath(index);
    final url = Uri.parse(base).resolve(path);
    final raw = await _getString(url);
    final festival = Festival.fromJson(jsonDecode(raw));
    final imageBase = url.resolve('.').toString();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheJsonKey, raw);
    await prefs.setString(_cacheBaseKey, imageBase);
    return LoadedFestival(festival, DataSource.remote, imageBase);
  }

  Future<LoadedFestival?> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheJsonKey);
    final base = prefs.getString(_cacheBaseKey);
    if (raw == null || base == null) return null;
    return LoadedFestival(
        Festival.fromJson(jsonDecode(raw)), DataSource.cache, base);
  }

  Future<LoadedFestival> _loadBundled() async {
    final index = jsonDecode(await rootBundle.loadString('data/index.json'));
    final path = _currentPath(index);
    final raw = await rootBundle.loadString('data/$path');
    final dir = path.substring(0, path.lastIndexOf('/') + 1);
    return LoadedFestival(
        Festival.fromJson(jsonDecode(raw)), DataSource.bundled, 'data/$dir');
  }

  String _currentPath(Json index) {
    final year = index['currentYear'];
    final edition = (index['editions'] as List)
        .cast<Json>()
        .firstWhere((e) => e['year'] == year);
    return edition['path'] as String;
  }

  Future<Json> _getJson(Uri url) async => jsonDecode(await _getString(url));

  Future<String> _getString(Uri url) async {
    final res = await http.get(url).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw http.ClientException('HTTP ${res.statusCode}', url);
    }
    return utf8.decode(res.bodyBytes);
  }
}
