import 'dart:convert';
import 'package:flutter/services.dart';
import 'app_settings_store.dart';

class OfflineCacheService {
  static Future<int> prefetchCoreAssets({
    void Function(int done, int total)? onProgress,
  }) async {
    Map<String, dynamic> data;
    try {
      final manifest =
          await rootBundle.loadString('AssetManifest.json');
      data = json.decode(manifest) as Map<String, dynamic>;
    } catch (_) {
      return 0;
    }
    final assets = data.keys.where((key) {
      return key.startsWith('assets/sounds/') ||
          key.startsWith('assets/images/') ||
          key.startsWith('assets/sheet_music/') ||
          key.startsWith('assets/tutorials/');
    }).toList();

    var done = 0;
    for (final asset in assets) {
      try {
        await rootBundle.load(asset);
        done++;
        onProgress?.call(done, assets.length);
      } catch (_) {
        // Skip missing/corrupt assets to avoid startup crashes.
      }
    }

    await AppSettingsStore.setOfflinePackReady(true);
    return assets.length;
  }

  static Future<bool> isOfflinePackReady() {
    return AppSettingsStore.getOfflinePackReady();
  }
}
