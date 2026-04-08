import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../services/app_settings_store.dart';
import '../services/audio_player_service.dart';
import '../services/connection_manager_service.dart';
import '../services/external_link.dart';
import '../services/midi_service_lite.dart';
import '../services/offline_cache_service.dart';
import '../services/offline_status.dart';
import '../services/web_transport_capability.dart';
import '../ui/ui_controller.dart';
import '../ui/ui_presets.dart';
import '../ui/ui_switcher.dart';
import '../utils/app_theme.dart';
import '../utils/velocity_curve.dart';
import '../widgets/live_play_visualization.dart';
import '../widgets/motion_fx.dart';

class SafeSettingsScreen extends StatefulWidget {
  const SafeSettingsScreen({super.key});

  @override
  State<SafeSettingsScreen> createState() => _SafeSettingsScreenState();
}

class _SafeSettingsScreenState extends State<SafeSettingsScreen> {
  final AudioPlayerService _audioService = AudioPlayerService();
  final MidiServiceLite _midi = MidiServiceLite.instance;
  final TextEditingController _bridgeUrlController = TextEditingController();

  double _volume = 0.8;
  bool _offlineReady = false;
  bool _prefetching = false;
  double _progress = 0.0;
  bool _performanceMode = true;
  UltraPerformanceMode _ultraMode = UltraPerformanceMode.off;
  bool _audioSustain = false;
  double _audioLatencyMs = 0.0;
  double _audioReverb = 0.3;
  bool _audioDebugLogging = false;
  VelocityCurvePreset _velocityCurvePreset = VelocityCurvePreset.linear;
  double _velocityCurveExponent = 1.0;
  PlayVisualizationMode _playMode = PlayVisualizationMode.both;
  bool _showLabels = true;
  bool _pinchZoom = true;
  bool _panelFocus = true;
  PlayPanelStyle _panelStyle = PlayPanelStyle.studio;
  PlayPanelLayout _panelLayout = PlayPanelLayout.stacked;
  PlayScoreColorTheme _scoreTheme = PlayScoreColorTheme.ivory;
  double _panelHeight = 0.75;
  bool _guideAudio = false;
  bool _metronomeEnabled = false;
  bool _listenOnly = false;
  double _timingWindowMs = 250.0;
  bool _autoConnect = true;
  bool _preferBle = true;
  int _manualMidiTranspose = 0;
  List<SavedDevice> _savedDevices = const [];
  String _bridgeStatus = 'Idle';
  WebTransportCapability? _webCapability;

  @override
  void initState() {
    super.initState();
    OfflineStatus.ensure();
    _load();
    _midi.status.listen((message) {
      if (!mounted) return;
      setState(() => _bridgeStatus = message);
    });
  }

  @override
  void dispose() {
    _bridgeUrlController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await ConnectionManagerService.initialize();
    final volume = await AppSettingsStore.getVolume();
    final ready = await OfflineCacheService.isOfflinePackReady();
    final performanceMode = await AppSettingsStore.getPerformanceMode();
    final ultraMode =
        ultraModeFromString(await AppSettingsStore.getUltraPerformanceMode());
    final audioSustain = await AppSettingsStore.getAudioSustain();
    final audioLatency = await AppSettingsStore.getAudioLatencyMs();
    final audioReverb = await AppSettingsStore.getAudioReverbLevel();
    final audioDebug = await AppSettingsStore.getAudioDebugLogging();
    final velocityPreset =
        velocityCurvePresetFromString(await AppSettingsStore.getVelocityCurvePreset());
    final velocityExponent = await AppSettingsStore.getVelocityCurveExponent();
    final playMode = playVisualizationModeFromString(
      await AppSettingsStore.getPlayVisualizationMode(),
    );
    final showLabels = await AppSettingsStore.getPlayShowLabels();
    final pinchZoom = await AppSettingsStore.getPlayPinchZoom();
    final panelFocus = await AppSettingsStore.getPlayPanelFocusMode();
    final panelStyle =
        playPanelStyleFromString(await AppSettingsStore.getPlayPanelStyle());
    final panelLayout =
        playPanelLayoutFromString(await AppSettingsStore.getPlayPanelLayout());
    final panelTheme =
        playScoreColorThemeFromString(await AppSettingsStore.getPlayScoreColorTheme());
    final panelHeight = await AppSettingsStore.getPlayPanelHeight();
    final guideAudio = await AppSettingsStore.getGuideAudio();
    final metronomeEnabled = await AppSettingsStore.getMetronomeEnabled();
    final listenOnly = await AppSettingsStore.getListenOnly();
    final timingWindowMs = await AppSettingsStore.getTimingWindowMs();
    final bridgeUrl = await AppSettingsStore.getBridgeUrl();
    final webCapability = await detectWebTransportCapability(
      bridgeConnected: _midi.bridgeConnected,
    );

    _bridgeUrlController.text = bridgeUrl;
    _audioService.setMasterVolume(volume);
    _audioService.setPerformanceMode(performanceMode);
    _audioService.setUltraMode(ultraMode);
    _audioService.setSustain(audioSustain);
    _audioService.setLatency(audioLatency);
    _audioService.setReverbLevel(audioReverb);
    _audioService.setDebugLogging(audioDebug);
    _audioService.setVelocityCurve(velocityPreset, velocityExponent);
    await _midi.setBridgeUrl(bridgeUrl);

    if (!mounted) return;
    setState(() {
      _volume = volume;
      _offlineReady = ready;
      _performanceMode = performanceMode;
      _ultraMode = ultraMode;
      _audioSustain = audioSustain;
      _audioLatencyMs = audioLatency;
      _audioReverb = audioReverb;
      _audioDebugLogging = audioDebug;
      _velocityCurvePreset = velocityPreset;
      _velocityCurveExponent = velocityExponent;
      _playMode = playMode;
      _showLabels = showLabels;
      _pinchZoom = pinchZoom;
      _panelFocus = panelFocus;
      _panelStyle = panelStyle;
      _panelLayout = panelLayout;
      _scoreTheme = panelTheme;
      _panelHeight = panelHeight;
      _guideAudio = guideAudio;
      _metronomeEnabled = metronomeEnabled;
      _listenOnly = listenOnly;
      _timingWindowMs = timingWindowMs;
      _autoConnect = _midi.autoConnectEnabled;
      _preferBle = _midi.preferBle;
      _manualMidiTranspose = _midi.manualTranspose;
      _savedDevices = ConnectionManagerService.savedDevices;
      _webCapability = webCapability;
    });
  }

  Future<void> _prefetch() async {
    setState(() {
      _prefetching = true;
      _progress = 0.0;
    });
    await OfflineCacheService.prefetchCoreAssets(
      onProgress: (done, total) {
        if (!mounted) return;
        setState(() {
          _progress = total == 0 ? 1.0 : done / total;
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _prefetching = false;
      _offlineReady = true;
      _progress = 1.0;
    });
  }

  Future<void> _resetDefaults() async {
    await AppSettingsStore.setPerformanceMode(true);
    await AppSettingsStore.setUltraPerformanceMode('off');
    await AppSettingsStore.setVolume(0.8);
    await AppSettingsStore.setAudioSustain(false);
    await AppSettingsStore.setAudioLatencyMs(0.0);
    await AppSettingsStore.setAudioReverbLevel(0.3);
    await AppSettingsStore.setVelocityCurvePreset('linear');
    await AppSettingsStore.setVelocityCurveExponent(1.0);
    await AppSettingsStore.setAudioDebugLogging(false);
    await AppSettingsStore.setPlayVisualizationMode('both');
    await AppSettingsStore.setPlayShowLabels(true);
    await AppSettingsStore.setPlayPinchZoom(true);
    await AppSettingsStore.setPlayPanelFocusMode(true);
    await AppSettingsStore.setPlayPanelStyle('studio');
    await AppSettingsStore.setPlayPanelLayout('stacked');
    await AppSettingsStore.setPlayScoreColorTheme('ivory');
    await AppSettingsStore.setPlayPanelHeight(0.75);
    await AppSettingsStore.setGuideAudio(false);
    await AppSettingsStore.setMetronomeEnabled(false);
    await AppSettingsStore.setListenOnly(false);
    await AppSettingsStore.setTimingWindowMs(250);
    await UiController.setStyle(0);
    await UiController.setLayout(3);
    await AppSettingsStore.setBridgeUrl('ws://127.0.0.1:8765/midi');
    await _midi.setAutoConnect(true);
    await _midi.setPreferBle(true);
    await _midi.setManualTranspose(0);
    await ConnectionManagerService.setAutoConnectEnabled(true);
    await _load();
  }

  Future<void> _clearSavedDevices() async {
    await ConnectionManagerService.clearAllDevices();
    if (!mounted) return;
    setState(() => _savedDevices = const []);
  }

  Future<void> _connectBridge() async {
    final url = _bridgeUrlController.text.trim();
    await AppSettingsStore.setBridgeUrl(url);
    await _midi.setBridgeUrl(url);
    await _midi.connect('bridge');
    await ConnectionManagerService.initialize();
    if (!mounted) return;
    setState(() => _savedDevices = ConnectionManagerService.savedDevices);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UiController.config,
      builder: (context, config, _) {
        final style = UiPresets.styles[config.styleIndex];
        final layout = UiPresets.layouts[config.layoutIndex];
        final theme = AppTheme.fromStyle(
          background: style.background,
          surface: style.surface,
          primary: style.primary,
          secondary: style.secondary,
          text: style.text,
          accent: style.accent,
          brightness: style.brightness,
        );

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            backgroundColor: theme.surfaceColor,
            middle: Text(
              'Settings',
              style: TextStyle(color: theme.textColor),
            ),
            trailing: const UiSwitcher(),
          ),
          child: MotionBackdrop(
            backgroundColor: theme.backgroundColor,
            surfaceColor: theme.surfaceColor,
            accentColor: theme.primaryColor,
            child: SafeArea(
              child: ListView(
                padding: layout.contentPadding,
                children: [
                  MotionReveal(delay: const Duration(milliseconds: 30), child: _statusCard(theme, layout)),
                  SizedBox(height: layout.panelSpacing),
                  MotionReveal(delay: const Duration(milliseconds: 60), child: _audioPerformanceCard(theme, layout)),
                  SizedBox(height: layout.panelSpacing),
                  MotionReveal(delay: const Duration(milliseconds: 90), child: _playDefaultsCard(theme, layout)),
                  SizedBox(height: layout.panelSpacing),
                  MotionReveal(delay: const Duration(milliseconds: 120), child: _interfaceCard(theme, layout, config)),
                  SizedBox(height: layout.panelSpacing),
                  MotionReveal(delay: const Duration(milliseconds: 150), child: _connectionsCard(theme, layout)),
                  if (kIsWeb) ...[
                    SizedBox(height: layout.panelSpacing),
                    MotionReveal(
                      delay: const Duration(milliseconds: 165),
                      child: _webTransportCard(theme, layout),
                    ),
                  ],
                  SizedBox(height: layout.panelSpacing),
                  MotionReveal(delay: const Duration(milliseconds: 180), child: _lessonCard(theme, layout)),
                  SizedBox(height: layout.panelSpacing),
                  MotionReveal(delay: const Duration(milliseconds: 210), child: _offlineDataCard(theme, layout)),
                  SizedBox(height: layout.panelSpacing),
                  MotionReveal(delay: const Duration(milliseconds: 240), child: _diagnosticsCard(theme, layout)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statusCard(AppTheme theme, UiLayoutPreset layout) {
    return MotionCard(
      color: theme.surfaceColor.withOpacity(0.74),
      borderColor: theme.textColor.withOpacity(0.1),
      radius: layout.cardRadius,
      glowColor: theme.primaryColor,
      padding: const EdgeInsets.all(16),
      child: ValueListenableBuilder<bool>(
        valueListenable: OfflineStatus.online,
        builder: (context, online, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('System Status', theme),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _statusPill(theme, online ? 'Online' : 'Offline', online ? CupertinoIcons.wifi : CupertinoIcons.wifi_slash, online ? CupertinoColors.systemGreen : CupertinoColors.systemRed),
                  _statusPill(theme, 'USB / OS MIDI', CupertinoIcons.cube_box, CupertinoColors.activeBlue),
                  _statusPill(theme, 'Bluetooth MIDI', CupertinoIcons.dot_radiowaves_left_right, CupertinoColors.systemTeal),
                  _statusPill(theme, 'Local Bridge', CupertinoIcons.antenna_radiowaves_left_right, _midi.bridgeConnected ? CupertinoColors.systemGreen : CupertinoColors.systemOrange),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'The app can use external controllers through OS MIDI / USB, direct Bluetooth MIDI, and an optional localhost bridge helper.',
                style: TextStyle(color: theme.textColor.withOpacity(0.72), fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _audioPerformanceCard(AppTheme theme, UiLayoutPreset layout) {
    return _settingsCard(theme, layout, 'Audio & Performance', [
      _sliderTile(theme, 'Master Volume', '${(_volume * 100).round()}%', CupertinoSlider(value: _volume, onChanged: (value) async { setState(() => _volume = value); _audioService.setMasterVolume(value); await AppSettingsStore.setVolume(value); }, activeColor: theme.primaryColor)),
      _switchTile(theme, 'Performance Mode', 'Reduces heavier processing and prioritizes responsiveness.', _performanceMode, (value) async { setState(() => _performanceMode = value); _audioService.setPerformanceMode(value); await AppSettingsStore.setPerformanceMode(value); }),
      _segmentedTile<UltraPerformanceMode>(theme, 'Ultra Performance', _ultraMode, { UltraPerformanceMode.off: const Text('Off'), UltraPerformanceMode.audioOnly: const Text('Audio'), UltraPerformanceMode.polyphony: const Text('Poly'), UltraPerformanceMode.visuals: const Text('Visual') }, (value) async { if (value == null) return; setState(() => _ultraMode = value); _audioService.setUltraMode(value); await AppSettingsStore.setUltraPerformanceMode(ultraModeToString(value)); }),
      _switchTile(theme, 'Sustain Behavior', 'Hold note release for a more piano-like tail.', _audioSustain, (value) async { setState(() => _audioSustain = value); _audioService.setSustain(value); await AppSettingsStore.setAudioSustain(value); }),
      _sliderTile(theme, 'Latency Compensation', '${_audioLatencyMs.round()} ms', CupertinoSlider(value: _audioLatencyMs, min: -100, max: 200, divisions: 30, activeColor: theme.primaryColor, onChanged: (value) async { setState(() => _audioLatencyMs = value); _audioService.setLatency(value); await AppSettingsStore.setAudioLatencyMs(value); })),
      _sliderTile(theme, 'Reverb', '${(_audioReverb * 100).round()}%', CupertinoSlider(value: _audioReverb, min: 0, max: 1, divisions: 20, activeColor: theme.primaryColor, onChanged: (value) async { setState(() => _audioReverb = value); _audioService.setReverbLevel(value); await AppSettingsStore.setAudioReverbLevel(value); })),
      _segmentedTile<VelocityCurvePreset>(theme, 'Velocity Curve', _velocityCurvePreset, { VelocityCurvePreset.linear: const Text('Linear'), VelocityCurvePreset.soft: const Text('Soft'), VelocityCurvePreset.hard: const Text('Hard'), VelocityCurvePreset.custom: const Text('Custom') }, (value) async { if (value == null) return; setState(() => _velocityCurvePreset = value); _audioService.setVelocityCurve(value, _velocityCurveExponent); await AppSettingsStore.setVelocityCurvePreset(velocityCurvePresetToString(value)); }),
      if (_velocityCurvePreset == VelocityCurvePreset.custom)
        _sliderTile(theme, 'Custom Curve Exponent', _velocityCurveExponent.toStringAsFixed(2), CupertinoSlider(value: _velocityCurveExponent, min: 0.5, max: 2.0, divisions: 15, activeColor: theme.primaryColor, onChanged: (value) async { setState(() => _velocityCurveExponent = value); _audioService.setVelocityCurve(_velocityCurvePreset, value); await AppSettingsStore.setVelocityCurveExponent(value); })),
      _switchTile(theme, 'Debug Logging', 'Useful for diagnosing audio and transport issues.', _audioDebugLogging, (value) async { setState(() => _audioDebugLogging = value); _audioService.setDebugLogging(value); await AppSettingsStore.setAudioDebugLogging(value); }),
    ]);
  }

  Widget _playDefaultsCard(AppTheme theme, UiLayoutPreset layout) {
    return _settingsCard(theme, layout, 'Play Tab Defaults', [
      _segmentedTile<PlayVisualizationMode>(theme, 'Default View', _playMode, { PlayVisualizationMode.classic: const Text('Classic'), PlayVisualizationMode.notation: const Text('Staff'), PlayVisualizationMode.tablature: const Text('Tab'), PlayVisualizationMode.both: const Text('Both') }, (value) async { if (value == null) return; setState(() => _playMode = value); await AppSettingsStore.setPlayVisualizationMode(playVisualizationModeToString(value)); }),
      _switchTile(theme, 'Show Key Labels', 'Display note names on white and black keys by default.', _showLabels, (value) async { setState(() => _showLabels = value); await AppSettingsStore.setPlayShowLabels(value); }),
      _switchTile(theme, 'Pinch Zoom', 'Allow gesture zoom on touch devices.', _pinchZoom, (value) async { setState(() => _pinchZoom = value); await AppSettingsStore.setPlayPinchZoom(value); }),
      _switchTile(theme, 'Focus Mode', 'Reduce chrome around the live performance score.', _panelFocus, (value) async { setState(() => _panelFocus = value); await AppSettingsStore.setPlayPanelFocusMode(value); }),
      _segmentedTile<PlayPanelStyle>(theme, 'Live Score Style', _panelStyle, { PlayPanelStyle.studio: const Text('Studio'), PlayPanelStyle.minimal: const Text('Minimal'), PlayPanelStyle.contrast: const Text('Contrast') }, (value) async { if (value == null) return; setState(() => _panelStyle = value); await AppSettingsStore.setPlayPanelStyle(playPanelStyleToString(value)); }),
      _segmentedTile<PlayPanelLayout>(theme, 'Live Score Layout', _panelLayout, { PlayPanelLayout.standard: const Text('Standard'), PlayPanelLayout.stacked: const Text('Stack'), PlayPanelLayout.compact: const Text('Compact') }, (value) async { if (value == null) return; setState(() => _panelLayout = value); await AppSettingsStore.setPlayPanelLayout(playPanelLayoutToString(value)); }),
      _segmentedTile<PlayScoreColorTheme>(theme, 'Score Palette', _scoreTheme, { PlayScoreColorTheme.classic: const Text('Classic'), PlayScoreColorTheme.ivory: const Text('Ivory'), PlayScoreColorTheme.aurora: const Text('Aurora'), PlayScoreColorTheme.ocean: const Text('Ocean') }, (value) async { if (value == null) return; setState(() => _scoreTheme = value); await AppSettingsStore.setPlayScoreColorTheme(playScoreColorThemeToString(value)); }),
      _sliderTile(theme, 'Score Height', '${_panelHeight.toStringAsFixed(2)}x', CupertinoSlider(value: _panelHeight, min: 0.75, max: 1.6, divisions: 17, activeColor: theme.primaryColor, onChanged: (value) async { setState(() => _panelHeight = value); await AppSettingsStore.setPlayPanelHeight(value); })),
    ]);
  }

  Widget _interfaceCard(AppTheme theme, UiLayoutPreset layout, UiConfig config) {
    return _settingsCard(theme, layout, 'Interface', [
      _choiceChips(theme, 'App Style', UiPresets.styles.asMap().entries.map((entry) => _ChoiceChipData(label: entry.value.name, selected: config.styleIndex == entry.key, onTap: () => UiController.setStyle(entry.key))).toList()),
      _choiceChips(theme, 'Layout Preset', UiPresets.layouts.asMap().entries.map((entry) => _ChoiceChipData(label: entry.value.name, selected: config.layoutIndex == entry.key, onTap: () => UiController.setLayout(entry.key))).toList()),
    ]);
  }

  Widget _connectionsCard(AppTheme theme, UiLayoutPreset layout) {
    return _settingsCard(theme, layout, 'Connections & Devices', [
      _switchTile(theme, 'Auto Connect', 'Reconnect to the remembered controller when possible.', _autoConnect, (value) async { setState(() => _autoConnect = value); await _midi.setAutoConnect(value); await ConnectionManagerService.setAutoConnectEnabled(value); }),
      _switchTile(theme, 'Prefer Bluetooth MIDI', 'Use direct BLE MIDI before OS MIDI when available.', _preferBle, (value) async { setState(() => _preferBle = value); await _midi.setPreferBle(value); }),
      Text('External MIDI Alignment', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Current device: ${_midi.activeInputDeviceName ?? "None"}  •  device align ${_midi.currentDeviceTranspose >= 0 ? "+" : ""}${_midi.currentDeviceTranspose}  •  effective ${_midi.effectiveTranspose >= 0 ? "+" : ""}${_midi.effectiveTranspose}', style: TextStyle(color: theme.textColor.withOpacity(0.72), fontSize: 12)),
      _sliderTile(theme, 'Manual Semitone Offset', '${_manualMidiTranspose >= 0 ? "+" : ""}${_manualMidiTranspose}', CupertinoSlider(value: _manualMidiTranspose.toDouble(), min: -12, max: 12, divisions: 24, activeColor: theme.primaryColor, onChanged: (value) async { final next = value.round(); setState(() => _manualMidiTranspose = next); await _midi.setManualTranspose(next); })),
      Row(children: [
        Expanded(child: CupertinoButton(padding: const EdgeInsets.symmetric(vertical: 10), color: theme.primaryColor, borderRadius: BorderRadius.circular(12), onPressed: _midi.activeInputDeviceId == null ? null : () async { await _midi.armCalibration(targetLabel: 'C'); if (!mounted) return; setState(() {}); }, child: const Text('Auto Align: Press C'))),
        const SizedBox(width: 8),
        Expanded(child: CupertinoButton(padding: const EdgeInsets.symmetric(vertical: 10), color: theme.surfaceColor.withOpacity(0.82), borderRadius: BorderRadius.circular(12), onPressed: _midi.activeInputDeviceId == null ? null : () async { await _midi.clearCurrentDeviceTranspose(); if (!mounted) return; setState(() {}); }, child: Text('Reset Device Align', style: TextStyle(color: theme.textColor)))),
      ]),
      Text(_midi.calibrationArmed ? 'Calibration armed: play a C on the external keyboard.' : 'Manual offset stays global. Auto align saves a device-specific correction and applies it automatically when that device reconnects.', style: TextStyle(color: theme.textColor.withOpacity(0.68), fontSize: 12)),
      Text('Local Bridge URL', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      CupertinoTextField(
        controller: _bridgeUrlController,
        placeholder: 'ws://127.0.0.1:8765/midi',
        style: TextStyle(color: theme.textColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withOpacity(0.32),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.textColor.withOpacity(0.08)),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: CupertinoButton(padding: const EdgeInsets.symmetric(vertical: 10), color: theme.primaryColor, borderRadius: BorderRadius.circular(12), onPressed: _connectBridge, child: const Text('Connect Local Bridge'))),
        const SizedBox(width: 8),
        CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), color: theme.surfaceColor.withOpacity(0.8), borderRadius: BorderRadius.circular(12), onPressed: _midi.disconnect, child: Text('Disconnect', style: TextStyle(color: theme.textColor))),
      ]),
      Text('Bridge status: ${_midi.bridgeConnected ? "Connected" : _bridgeStatus}', style: TextStyle(color: theme.textColor.withOpacity(0.7), fontSize: 12)),
      Text('Use the bridge only when direct Web MIDI or Web Bluetooth is not enough. The bridge should connect to the real device itself and expose it over localhost.', style: TextStyle(color: theme.textColor.withOpacity(0.68), fontSize: 12)),
      Text('Remembered devices: ${_savedDevices.length}', style: TextStyle(color: theme.textColor.withOpacity(0.7), fontSize: 12)),
    ]);
  }

  Widget _webTransportCard(AppTheme theme, UiLayoutPreset layout) {
    final capability = _webCapability;
    if (capability == null) {
      return _settingsCard(
        theme,
        layout,
        'Web Transport',
        [Text('Detecting browser transport capability...', style: TextStyle(color: theme.textColor.withOpacity(0.72), fontSize: 12))],
      );
    }

    final recommendationText = switch (capability.recommendation) {
      WebTransportRecommendation.nativeWeb => 'Direct browser transport is usable',
      WebTransportRecommendation.bridgeRecommended => 'Bridge is optional localhost fallback',
      WebTransportRecommendation.bridgeRequired => 'Bridge is required on this browser',
    };

    return _settingsCard(
      theme,
      layout,
      'Web Transport',
      [
        Text(
          '${capability.browserLabel} on ${capability.osLabel}',
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          recommendationText,
          style: TextStyle(color: theme.primaryColor, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          capability.reason,
          style: TextStyle(color: theme.textColor.withOpacity(0.72), fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          'Detected: Web Bluetooth ${capability.bluetoothSupported ? "yes" : "no"}  •  Web MIDI ${capability.webMidiSupported ? "yes" : "no"}  •  Web Serial ${capability.webSerialSupported ? "yes" : "no"}',
          style: TextStyle(color: theme.textColor.withOpacity(0.68), fontSize: 12),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: _midi.webTransportPreference == WebTransportPreference.auto
                    ? theme.primaryColor
                    : theme.surfaceColor.withOpacity(0.82),
                borderRadius: BorderRadius.circular(12),
                onPressed: () async {
                  await _midi.setWebTransportPreference(WebTransportPreference.auto);
                  await _load();
                },
                child: Text(
                  'Auto',
                  style: TextStyle(
                    color: _midi.webTransportPreference == WebTransportPreference.auto
                        ? CupertinoColors.white
                        : theme.textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: _midi.webTransportPreference == WebTransportPreference.webBluetooth
                    ? theme.primaryColor
                    : theme.surfaceColor.withOpacity(0.82),
                borderRadius: BorderRadius.circular(12),
                onPressed: () async {
                  await _midi.setWebTransportPreference(
                    WebTransportPreference.webBluetooth,
                  );
                  await _load();
                },
                child: Text(
                  'Direct Device',
                  style: TextStyle(
                    color: _midi.webTransportPreference == WebTransportPreference.webBluetooth
                        ? CupertinoColors.white
                        : theme.textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: _midi.webTransportPreference == WebTransportPreference.bridge
                    ? theme.primaryColor
                    : theme.surfaceColor.withOpacity(0.82),
                borderRadius: BorderRadius.circular(12),
                onPressed: () async {
                  await _midi.setWebTransportPreference(WebTransportPreference.bridge);
                  await _load();
                },
                child: Text(
                  'Bridge',
                  style: TextStyle(
                    color: _midi.webTransportPreference == WebTransportPreference.bridge
                        ? CupertinoColors.white
                        : theme.textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (capability.downloadLinks.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: capability.downloadLinks.map((link) {
              return CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: theme.primaryColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(12),
                onPressed: () => openExternalLink(link.url),
                child: Text(link.label, style: TextStyle(color: theme.textColor)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _lessonCard(AppTheme theme, UiLayoutPreset layout) {
    return _settingsCard(theme, layout, 'Lessons & Practice', [
      _switchTile(theme, 'Guide Audio', 'Play guide tones during lessons.', _guideAudio, (value) async { setState(() => _guideAudio = value); await AppSettingsStore.setGuideAudio(value); }),
      _switchTile(theme, 'Metronome Default', 'Start lessons with metronome enabled by default.', _metronomeEnabled, (value) async { setState(() => _metronomeEnabled = value); await AppSettingsStore.setMetronomeEnabled(value); }),
      _switchTile(theme, 'Listen Only Default', 'Open lessons in listen-only mode until you switch to play.', _listenOnly, (value) async { setState(() => _listenOnly = value); await AppSettingsStore.setListenOnly(value); }),
      _sliderTile(theme, 'Timing Tolerance', '${_timingWindowMs.round()} ms', CupertinoSlider(value: _timingWindowMs, min: 120, max: 450, divisions: 22, activeColor: theme.primaryColor, onChanged: (value) async { setState(() => _timingWindowMs = value); await AppSettingsStore.setTimingWindowMs(value); })),
    ]);
  }

  Widget _offlineDataCard(AppTheme theme, UiLayoutPreset layout) {
    return _settingsCard(theme, layout, 'Offline & Data', [
      Text('Offline Pack', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Download audio and visuals so lessons remain usable without internet.', style: TextStyle(color: theme.textColor.withOpacity(0.72), fontSize: 12)),
      const SizedBox(height: 10),
      if (_prefetching)
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CupertinoActivityIndicator(color: theme.primaryColor), const SizedBox(height: 8), Text('Caching ${(100 * _progress).round()}%', style: TextStyle(color: theme.textColor.withOpacity(0.72), fontSize: 12))])
      else
        Row(children: [Expanded(child: CupertinoButton(padding: const EdgeInsets.symmetric(vertical: 10), color: theme.primaryColor, borderRadius: BorderRadius.circular(12), onPressed: _prefetch, child: Text(_offlineReady ? 'Refresh Offline Pack' : 'Download Offline Pack'))), const SizedBox(width: 8), CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), color: CupertinoColors.systemRed.withOpacity(0.18), borderRadius: BorderRadius.circular(12), onPressed: _clearSavedDevices, child: const Text('Clear Devices'))]),
      const SizedBox(height: 10),
      CupertinoButton(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14), color: theme.surfaceColor.withOpacity(0.78), borderRadius: BorderRadius.circular(12), onPressed: _resetDefaults, child: Text('Reset App Defaults', style: TextStyle(color: theme.textColor))),
    ]);
  }

  Widget _diagnosticsCard(AppTheme theme, UiLayoutPreset layout) {
    final stats = _audioService.getPerformanceStats();
    return _settingsCard(theme, layout, 'Diagnostics', [
      Text('Build platform: ${kIsWeb ? "Web" : "Native"}', style: TextStyle(color: theme.textColor.withOpacity(0.76), fontSize: 12)),
      Text('Audio plays: ${stats['audioPlayCount']}    errors: ${stats['audioErrorCount']}', style: TextStyle(color: theme.textColor.withOpacity(0.76), fontSize: 12)),
      Text('Playback rate: ${stats['playbackRate']}    latency: ${stats['latency']} ms', style: TextStyle(color: theme.textColor.withOpacity(0.76), fontSize: 12)),
      Text('Last device: ${_midi.lastDeviceName ?? "None"}    bridge: ${_midi.bridgeConnected ? "connected" : "idle"}', style: TextStyle(color: theme.textColor.withOpacity(0.76), fontSize: 12)),
      if (_midi.bridgeError != null)
        Text('Bridge error: ${_midi.bridgeError}', style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 12)),
    ]);
  }

  Widget _settingsCard(AppTheme theme, UiLayoutPreset layout, String title, List<Widget> children) {
    return MotionCard(
      color: theme.surfaceColor.withOpacity(0.74),
      borderColor: theme.textColor.withOpacity(0.1),
      radius: layout.cardRadius,
      glowColor: theme.primaryColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title, theme),
          const SizedBox(height: 12),
          ..._withSpacing(children),
        ],
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> children) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i != children.length - 1) {
        items.add(const SizedBox(height: 14));
      }
    }
    return items;
  }

  Widget _sectionHeader(String title, AppTheme theme) {
    return Text(title, style: TextStyle(color: theme.textColor, fontSize: 17, fontWeight: FontWeight.w700));
  }

  Widget _statusPill(AppTheme theme, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withOpacity(0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: color), const SizedBox(width: 8), Text(label, style: TextStyle(color: theme.textColor, fontSize: 12, fontWeight: FontWeight.w600))]),
    );
  }

  Widget _switchTile(AppTheme theme, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: theme.textColor.withOpacity(0.68), fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CupertinoSwitch(value: value, activeColor: theme.primaryColor, onChanged: onChanged),
      ],
    );
  }

  Widget _sliderTile(AppTheme theme, String title, String valueLabel, Widget slider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Text(title, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)), const Spacer(), Text(valueLabel, style: TextStyle(color: theme.textColor.withOpacity(0.72), fontSize: 12))]),
        slider,
      ],
    );
  }

  Widget _segmentedTile<T extends Object>(AppTheme theme, String title, T groupValue, Map<T, Widget> children, ValueChanged<T?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CupertinoSlidingSegmentedControl<T>(
            backgroundColor: theme.backgroundColor.withOpacity(0.34),
            thumbColor: theme.primaryColor.withOpacity(0.88),
            groupValue: groupValue,
            onValueChanged: onChanged,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _choiceChips(AppTheme theme, String title, List<_ChoiceChipData> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) => GestureDetector(
            onTap: option.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: option.selected ? theme.primaryColor.withOpacity(0.24) : theme.backgroundColor.withOpacity(0.32),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: option.selected ? theme.primaryColor.withOpacity(0.4) : theme.textColor.withOpacity(0.08)),
              ),
              child: Text(option.label, style: TextStyle(color: theme.textColor, fontSize: 12, fontWeight: option.selected ? FontWeight.w700 : FontWeight.w500)),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

class _ChoiceChipData {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChipData({required this.label, required this.selected, required this.onTap});
}
