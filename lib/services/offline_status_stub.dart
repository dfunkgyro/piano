import 'package:flutter/foundation.dart';

class OfflineStatusImpl {
  static final ValueNotifier<bool> online = ValueNotifier(true);
  static void ensure() {}
}
