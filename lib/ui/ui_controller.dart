import 'package:flutter/foundation.dart';
import '../services/app_settings_store.dart';
import 'ui_presets.dart';

class UiConfig {
  final int styleIndex;
  final int layoutIndex;
  const UiConfig({required this.styleIndex, required this.layoutIndex});
}

class UiController {
  static final ValueNotifier<UiConfig> config =
      ValueNotifier(const UiConfig(styleIndex: 0, layoutIndex: 0));
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final style = await AppSettingsStore.getStyleIndex();
    final layout = await AppSettingsStore.getLayoutIndex();
    config.value = UiConfig(
      styleIndex: style.clamp(0, UiPresets.styles.length - 1),
      layoutIndex: layout.clamp(0, UiPresets.layouts.length - 1),
    );
  }

  static Future<void> setStyle(int index) async {
    final next = index.clamp(0, UiPresets.styles.length - 1);
    config.value = UiConfig(styleIndex: next, layoutIndex: config.value.layoutIndex);
    await AppSettingsStore.setStyleIndex(next);
  }

  static Future<void> setLayout(int index) async {
    final next = index.clamp(0, UiPresets.layouts.length - 1);
    config.value = UiConfig(styleIndex: config.value.styleIndex, layoutIndex: next);
    await AppSettingsStore.setLayoutIndex(next);
  }
}
