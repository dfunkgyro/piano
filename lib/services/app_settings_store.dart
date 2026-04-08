import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsStore {
  static const _keyVolume = 'safe_volume';
  static const _keyAutoLoop = 'lesson_auto_loop';
  static const _keyLastSong = 'lesson_last_song';
  static const _keyOfflinePack = 'offline_pack_ready';
  static const _keyStyleIndex = 'ui_style_index';
  static const _keyLayoutIndex = 'ui_layout_index';
  static const _keyGuideAudio = 'lesson_guide_audio';
  static const _keyTimingWindowMs = 'lesson_timing_window_ms';
  static const _keyListenOnly = 'lesson_listen_only';
  static const _keyMetronomeEnabled = 'lesson_metronome_enabled';
  static const _keyMetronomeBpm = 'lesson_metronome_bpm';
  static const _keyPerformanceMode = 'performance_mode';
  static const _keyUltraMode = 'ultra_performance_mode';
  static const _keyQwertyEnabled = 'qwerty_enabled';
  static const _keyPlayVisualizationMode = 'play_visualization_mode';
  static const _keyPlayTempoMode = 'play_tempo_mode';
  static const _keyPlayManualBpm = 'play_manual_bpm';
  static const _keyPlayAutoKey = 'play_auto_key';
  static const _keyPlayManualKeySignature = 'play_manual_key_signature';
  static const _keyPlayAutoTimeSignature = 'play_auto_time_signature';
  static const _keyPlayManualTimeSignature = 'play_manual_time_signature';
  static const _keyPlayPanelStyle = 'play_panel_style';
  static const _keyPlayPanelLayout = 'play_panel_layout';
  static const _keyPlayPanelFocusMode = 'play_panel_focus_mode';
  static const _keyPlayPanelHeight = 'play_panel_height';
  static const _keyPlayScoreColorTheme = 'play_score_color_theme';
  static const _keyFavoriteSongIds = 'favorite_song_ids';
  static const _keyRecentSongSearches = 'recent_song_searches';
  static const _keyLibrarySort = 'library_sort';
  static const _keyLibraryDifficulty = 'library_difficulty';
  static const _keyLibraryTimeSignature = 'library_time_signature';
  static const _keyLibraryKeySignature = 'library_key_signature';
  static const _keyLibraryFavoritesOnly = 'library_favorites_only';
  static const _keyPlayShowLabels = 'play_show_labels';
  static const _keyPlayPinchZoom = 'play_pinch_zoom';
  static const _keyBridgeUrl = 'midi_bridge_url';
  static const _keyWebTransportPreference = 'web_transport_preference';
  static const _keyAudioLatencyMs = 'audio_latency_ms';
  static const _keyAudioSustain = 'audio_sustain_enabled';
  static const _keyAudioReverb = 'audio_reverb_level';
  static const _keyVelocityCurvePreset = 'velocity_curve_preset';
  static const _keyVelocityCurveExponent = 'velocity_curve_exponent';
  static const _keyAudioDebugLogging = 'audio_debug_logging';

  static Future<SharedPreferences> _prefs() =>
      SharedPreferences.getInstance();

  static Future<double> getVolume() async {
    final prefs = await _prefs();
    return prefs.getDouble(_keyVolume) ?? 0.8;
  }

  static Future<void> setVolume(double value) async {
    final prefs = await _prefs();
    await prefs.setDouble(_keyVolume, value);
  }

  static Future<bool> getAutoLoop() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyAutoLoop) ?? true;
  }

  static Future<void> setAutoLoop(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyAutoLoop, value);
  }

  static Future<String?> getLastSongId() async {
    final prefs = await _prefs();
    return prefs.getString(_keyLastSong);
  }

  static Future<void> setLastSongId(String id) async {
    final prefs = await _prefs();
    await prefs.setString(_keyLastSong, id);
  }

  static Future<bool> getOfflinePackReady() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyOfflinePack) ?? false;
  }

  static Future<void> setOfflinePackReady(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyOfflinePack, value);
  }

  static Future<int> getStyleIndex() async {
    final prefs = await _prefs();
    return prefs.getInt(_keyStyleIndex) ?? 0;
  }

  static Future<void> setStyleIndex(int value) async {
    final prefs = await _prefs();
    await prefs.setInt(_keyStyleIndex, value);
  }

  static Future<int> getLayoutIndex() async {
    final prefs = await _prefs();
    return prefs.getInt(_keyLayoutIndex) ?? 3;
  }

  static Future<void> setLayoutIndex(int value) async {
    final prefs = await _prefs();
    await prefs.setInt(_keyLayoutIndex, value);
  }

  static Future<bool> getGuideAudio() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyGuideAudio) ?? false;
  }

  static Future<void> setGuideAudio(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyGuideAudio, value);
  }

  static Future<double> getTimingWindowMs() async {
    final prefs = await _prefs();
    return (prefs.getDouble(_keyTimingWindowMs) ?? 250.0)
        .clamp(120.0, 450.0);
  }

  static Future<void> setTimingWindowMs(double value) async {
    final prefs = await _prefs();
    await prefs.setDouble(_keyTimingWindowMs, value.clamp(120.0, 450.0));
  }

  static Future<bool> getListenOnly() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyListenOnly) ?? false;
  }

  static Future<void> setListenOnly(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyListenOnly, value);
  }

  static Future<bool> getMetronomeEnabled() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyMetronomeEnabled) ?? false;
  }

  static Future<void> setMetronomeEnabled(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyMetronomeEnabled, value);
  }

  static Future<int> getMetronomeBpm() async {
    final prefs = await _prefs();
    return (prefs.getInt(_keyMetronomeBpm) ?? 80).clamp(40, 200);
  }

  static Future<void> setMetronomeBpm(int value) async {
    final prefs = await _prefs();
    await prefs.setInt(_keyMetronomeBpm, value.clamp(40, 200));
  }

  static Future<bool> getPerformanceMode() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyPerformanceMode) ?? true;
  }

  static Future<void> setPerformanceMode(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyPerformanceMode, value);
  }

  static Future<String> getUltraPerformanceMode() async {
    final prefs = await _prefs();
    return prefs.getString(_keyUltraMode) ?? 'off';
  }

  static Future<void> setUltraPerformanceMode(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyUltraMode, value);
  }

  static Future<bool> getQwertyEnabled() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyQwertyEnabled) ?? true;
  }

  static Future<void> setQwertyEnabled(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyQwertyEnabled, value);
  }

  static Future<String> getPlayVisualizationMode() async {
    final prefs = await _prefs();
    return prefs.getString(_keyPlayVisualizationMode) ?? 'both';
  }

  static Future<void> setPlayVisualizationMode(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyPlayVisualizationMode, value);
  }

  static Future<String> getPlayTempoMode() async {
    final prefs = await _prefs();
    return prefs.getString(_keyPlayTempoMode) ?? 'adaptive';
  }

  static Future<void> setPlayTempoMode(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyPlayTempoMode, value);
  }

  static Future<int> getPlayManualBpm() async {
    final prefs = await _prefs();
    return (prefs.getInt(_keyPlayManualBpm) ?? 80).clamp(40, 220);
  }

  static Future<void> setPlayManualBpm(int value) async {
    final prefs = await _prefs();
    await prefs.setInt(_keyPlayManualBpm, value.clamp(40, 220));
  }

  static Future<bool> getPlayAutoKey() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyPlayAutoKey) ?? true;
  }

  static Future<void> setPlayAutoKey(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyPlayAutoKey, value);
  }

  static Future<String> getPlayManualKeySignature() async {
    final prefs = await _prefs();
    return prefs.getString(_keyPlayManualKeySignature) ?? 'C Major';
  }

  static Future<void> setPlayManualKeySignature(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyPlayManualKeySignature, value);
  }

  static Future<bool> getPlayAutoTimeSignature() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyPlayAutoTimeSignature) ?? true;
  }

  static Future<void> setPlayAutoTimeSignature(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyPlayAutoTimeSignature, value);
  }

  static Future<String> getPlayManualTimeSignature() async {
    final prefs = await _prefs();
    return prefs.getString(_keyPlayManualTimeSignature) ?? '4/4';
  }

  static Future<void> setPlayManualTimeSignature(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyPlayManualTimeSignature, value);
  }

  static Future<String> getPlayPanelStyle() async {
    final prefs = await _prefs();
    return prefs.getString(_keyPlayPanelStyle) ?? 'studio';
  }

  static Future<void> setPlayPanelStyle(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyPlayPanelStyle, value);
  }

  static Future<String> getPlayPanelLayout() async {
    final prefs = await _prefs();
    return prefs.getString(_keyPlayPanelLayout) ?? 'stacked';
  }

  static Future<void> setPlayPanelLayout(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyPlayPanelLayout, value);
  }

  static Future<bool> getPlayPanelFocusMode() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyPlayPanelFocusMode) ?? true;
  }

  static Future<void> setPlayPanelFocusMode(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyPlayPanelFocusMode, value);
  }

  static Future<double> getPlayPanelHeight() async {
    final prefs = await _prefs();
    return (prefs.getDouble(_keyPlayPanelHeight) ?? 0.75).clamp(0.75, 1.6);
  }

  static Future<void> setPlayPanelHeight(double value) async {
    final prefs = await _prefs();
    await prefs.setDouble(_keyPlayPanelHeight, value.clamp(0.75, 1.6));
  }

  static Future<String> getPlayScoreColorTheme() async {
    final prefs = await _prefs();
    return prefs.getString(_keyPlayScoreColorTheme) ?? 'ivory';
  }

  static Future<void> setPlayScoreColorTheme(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyPlayScoreColorTheme, value);
  }

  static Future<bool> getPlayShowLabels() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyPlayShowLabels) ?? true;
  }

  static Future<void> setPlayShowLabels(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyPlayShowLabels, value);
  }

  static Future<bool> getPlayPinchZoom() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyPlayPinchZoom) ?? true;
  }

  static Future<void> setPlayPinchZoom(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyPlayPinchZoom, value);
  }

  static Future<String> getWebTransportPreference() async {
    final prefs = await _prefs();
    return prefs.getString(_keyWebTransportPreference) ?? 'auto';
  }

  static Future<void> setWebTransportPreference(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyWebTransportPreference, value);
  }

  static Future<String> getBridgeUrl() async {
    final prefs = await _prefs();
    return prefs.getString(_keyBridgeUrl) ?? 'ws://127.0.0.1:8765/midi';
  }

  static Future<void> setBridgeUrl(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyBridgeUrl, value.trim());
  }

  static Future<double> getAudioLatencyMs() async {
    final prefs = await _prefs();
    return (prefs.getDouble(_keyAudioLatencyMs) ?? 0.0).clamp(-100.0, 200.0);
  }

  static Future<void> setAudioLatencyMs(double value) async {
    final prefs = await _prefs();
    await prefs.setDouble(_keyAudioLatencyMs, value.clamp(-100.0, 200.0));
  }

  static Future<bool> getAudioSustain() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyAudioSustain) ?? false;
  }

  static Future<void> setAudioSustain(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyAudioSustain, value);
  }

  static Future<double> getAudioReverbLevel() async {
    final prefs = await _prefs();
    return (prefs.getDouble(_keyAudioReverb) ?? 0.3).clamp(0.0, 1.0);
  }

  static Future<void> setAudioReverbLevel(double value) async {
    final prefs = await _prefs();
    await prefs.setDouble(_keyAudioReverb, value.clamp(0.0, 1.0));
  }

  static Future<String> getVelocityCurvePreset() async {
    final prefs = await _prefs();
    return prefs.getString(_keyVelocityCurvePreset) ?? 'linear';
  }

  static Future<void> setVelocityCurvePreset(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyVelocityCurvePreset, value);
  }

  static Future<double> getVelocityCurveExponent() async {
    final prefs = await _prefs();
    return (prefs.getDouble(_keyVelocityCurveExponent) ?? 1.0).clamp(0.5, 2.0);
  }

  static Future<void> setVelocityCurveExponent(double value) async {
    final prefs = await _prefs();
    await prefs.setDouble(_keyVelocityCurveExponent, value.clamp(0.5, 2.0));
  }

  static Future<bool> getAudioDebugLogging() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyAudioDebugLogging) ?? false;
  }

  static Future<void> setAudioDebugLogging(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyAudioDebugLogging, value);
  }

  static Future<Set<String>> getFavoriteSongIds() async {
    final prefs = await _prefs();
    return (prefs.getStringList(_keyFavoriteSongIds) ?? const []).toSet();
  }

  static Future<void> setFavoriteSongIds(Set<String> ids) async {
    final prefs = await _prefs();
    await prefs.setStringList(_keyFavoriteSongIds, ids.toList()..sort());
  }

  static Future<List<String>> getRecentSongSearches() async {
    final prefs = await _prefs();
    return prefs.getStringList(_keyRecentSongSearches) ?? const [];
  }

  static Future<void> addRecentSongSearch(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;
    final prefs = await _prefs();
    final current = prefs.getStringList(_keyRecentSongSearches) ?? <String>[];
    current.removeWhere((item) => item.toLowerCase() == normalized.toLowerCase());
    current.insert(0, normalized);
    if (current.length > 8) {
      current.removeRange(8, current.length);
    }
    await prefs.setStringList(_keyRecentSongSearches, current);
  }

  static Future<String> getLibrarySort() async {
    final prefs = await _prefs();
    return prefs.getString(_keyLibrarySort) ?? 'relevance';
  }

  static Future<void> setLibrarySort(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyLibrarySort, value);
  }

  static Future<String> getLibraryDifficulty() async {
    final prefs = await _prefs();
    return prefs.getString(_keyLibraryDifficulty) ?? 'All';
  }

  static Future<void> setLibraryDifficulty(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyLibraryDifficulty, value);
  }

  static Future<String> getLibraryTimeSignature() async {
    final prefs = await _prefs();
    return prefs.getString(_keyLibraryTimeSignature) ?? 'All';
  }

  static Future<void> setLibraryTimeSignature(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyLibraryTimeSignature, value);
  }

  static Future<String> getLibraryKeySignature() async {
    final prefs = await _prefs();
    return prefs.getString(_keyLibraryKeySignature) ?? 'All';
  }

  static Future<void> setLibraryKeySignature(String value) async {
    final prefs = await _prefs();
    await prefs.setString(_keyLibraryKeySignature, value);
  }

  static Future<bool> getLibraryFavoritesOnly() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyLibraryFavoritesOnly) ?? false;
  }

  static Future<void> setLibraryFavoritesOnly(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyLibraryFavoritesOnly, value);
  }
}
