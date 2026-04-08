import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceId {
  static const _prefKey = 'device_id';

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random();
    // Avoid 1<<32 on web (JS bitshift wraps to 0). Use 31-bit range.
    final id =
        'dev-${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(1 << 31)}';
    await prefs.setString(_prefKey, id);
    return id;
  }
}
