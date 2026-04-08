import 'offline_status_stub.dart'
    if (dart.library.html) 'offline_status_web.dart';
import 'package:flutter/foundation.dart';

class OfflineStatus {
  static ValueNotifier<bool> get online => OfflineStatusImpl.online;
  static void ensure() => OfflineStatusImpl.ensure();
}
