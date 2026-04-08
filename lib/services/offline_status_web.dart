import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class OfflineStatusImpl {
  static final ValueNotifier<bool> online = ValueNotifier(true);
  static bool _initialized = false;

  static void ensure() {
    if (_initialized) return;
    _initialized = true;
    online.value = html.window.navigator.onLine ?? true;
    html.window.onOnline.listen((_) => online.value = true);
    html.window.onOffline.listen((_) => online.value = false);
  }
}
