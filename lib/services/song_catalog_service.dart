import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/complete_songs_library.dart';

class SongCatalogService {
  static const _cacheKey = 'pd_catalog_json';
  static const _cacheTimeKey = 'pd_catalog_time';
  static const _maxAge = Duration(hours: 24);
  static const _defaultPath = 'catalog/pd_catalog.json';

  static List<CompleteSong>? _memoryCache;

  static Future<List<CompleteSong>> loadCatalog({
    String? overrideUrl,
  }) async {
    if (_memoryCache != null) return _memoryCache!;

    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_cacheKey);
    final cachedTime = prefs.getInt(_cacheTimeKey);
    final now = DateTime.now().millisecondsSinceEpoch;
    final cacheValid = cachedTime != null &&
        (now - cachedTime) < _maxAge.inMilliseconds;

    if (cacheValid && cachedJson != null) {
      final parsed = _mergeWithBuiltIns(_parse(cachedJson));
      if (parsed.isNotEmpty) {
        _memoryCache = parsed;
        return parsed;
      }
    }

    try {
      final assetJson = await rootBundle.loadString(_defaultPath);
      final parsed = _mergeWithBuiltIns(_parse(assetJson));
      if (parsed.isNotEmpty) {
        _memoryCache = parsed;
        await prefs.setString(_cacheKey, assetJson);
        await prefs.setInt(_cacheTimeKey, now);
        return parsed;
      }
    } catch (_) {
      // Fallback to HTTP below.
    }

    try {
      final url = overrideUrl ??
          (kIsWeb
              ? Uri.base.resolve(_defaultPath).toString()
              : _defaultPath);
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final parsed = _mergeWithBuiltIns(_parse(resp.body));
        if (parsed.isNotEmpty) {
          _memoryCache = parsed;
          await prefs.setString(_cacheKey, resp.body);
          await prefs.setInt(_cacheTimeKey, now);
          return parsed;
        }
      }
    } catch (_) {
      // Fallback below.
    }

    if (cachedJson != null) {
      final parsed = _mergeWithBuiltIns(_parse(cachedJson));
      if (parsed.isNotEmpty) {
        _memoryCache = parsed;
        return parsed;
      }
    }

    _memoryCache = SongsLibrary.getSongs();
    return _memoryCache!;
  }

  static List<CompleteSong> _mergeWithBuiltIns(List<CompleteSong> catalog) {
    final merged = <CompleteSong>[];
    final seen = <String>{};

    void addSong(CompleteSong song) {
      final key = '${song.title.toLowerCase()}|${song.composer.toLowerCase()}';
      if (seen.add(key)) {
        merged.add(song);
      }
    }

    for (final song in SongsLibrary.getSongs()) {
      addSong(song);
    }
    for (final song in catalog) {
      addSong(song);
    }
    return merged;
  }

  static List<CompleteSong> _parse(String jsonStr) {
    try {
      final raw = jsonDecode(jsonStr);
      if (raw is List) {
        return raw
            .map((item) => CompleteSong.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
