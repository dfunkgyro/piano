import 'dart:collection';
import 'dart:async';

import 'package:flutter/foundation.dart';

class AppDebugLogService {
  AppDebugLogService._();
  static final AppDebugLogService instance = AppDebugLogService._();

  static const int _maxEntries = 600;
  final ValueNotifier<List<String>> logs = ValueNotifier<List<String>>(const []);
  final ListQueue<String> _buffer = ListQueue<String>();
  Timer? _flushTimer;

  void add(String source, String message) {
    final timestamp = DateTime.now().toIso8601String();
    _buffer.add('[$timestamp] [$source] $message');
    _flushTimer ??= Timer(const Duration(milliseconds: 80), _flush);
    debugPrint('[$source] $message');
  }

  void clear() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _buffer.clear();
    logs.value = const [];
  }

  String exportText() => logs.value.join('\n');

  void _flush() {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_buffer.isEmpty) return;

    final next = List<String>.from(logs.value);
    while (_buffer.isNotEmpty) {
      next.add(_buffer.removeFirst());
    }
    if (next.length > _maxEntries) {
      next.removeRange(0, next.length - _maxEntries);
    }
    logs.value = UnmodifiableListView(next);
  }
}
