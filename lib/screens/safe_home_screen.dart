import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import '../services/audio_player_service.dart';
import '../services/web_audio_engine.dart';
import '../services/midi_service_lite.dart';
import '../services/app_settings_store.dart';
import '../utils/qwerty_midi.dart';
import '../widgets/basic_piano_keyboard.dart';
import '../widgets/live_play_visualization.dart';
import '../widgets/motion_fx.dart';
import '../widgets/sheet_music_view.dart';
import '../ui/ui_controller.dart';
import '../ui/ui_presets.dart';
import '../ui/ui_switcher.dart';

class SafeHomeScreen extends StatefulWidget {
  const SafeHomeScreen({super.key});

  @override
  State<SafeHomeScreen> createState() => _SafeHomeScreenState();
}

class _SafeHomeScreenState extends State<SafeHomeScreen> {
  static const int _maxVisualizedNotes = 96;
  final Set<int> _activeNotes = {};
  final AudioPlayerService _audioService = AudioPlayerService();
  final MidiServiceLite _midi = MidiServiceLite.instance;
  final FocusNode _qwertyFocusNode = FocusNode();
  final QwertyMidiController _qwertyController = QwertyMidiController();
  final Map<int, DateTime> _activeNoteStarts = {};
  final Map<int, int> _activeNoteIndices = {};
  final Set<int> _sustainedNotes = {};
  Timer? _visualizationTicker;
  StreamSubscription<MidiInputEvent>? _midiEventSub;
  bool _qwertyEnabled = true;
  String _lastEvent = 'Idle';
  bool _showLabels = true;
  String _status = 'Performance Mode: ON';
  List<MidiDeviceInfo> _devices = [];
  bool _autoConnect = true;
  bool _bleDirect = false;
  bool _pinchZoom = true;
  double _zoom = 1.0;
  double _keyboardZoomStart = 1.0;
  bool _audioReady = !kIsWeb;
  String _audioStatus = kIsWeb ? 'Tap Enable Audio' : 'Audio Ready';
  PlayVisualizationMode _visualizationMode = PlayVisualizationMode.both;
  PlayTempoMode _tempoMode = PlayTempoMode.adaptive;
  int _manualBpm = 80;
  bool _autoDetectKeySignature = true;
  String _manualKeySignature = 'C Major';
  bool _autoDetectTimeSignature = true;
  String _manualTimeSignature = '4/4';
  PlayPanelStyle _panelStyle = PlayPanelStyle.studio;
  PlayPanelLayout _panelLayout = PlayPanelLayout.stacked;
  PlayScoreColorTheme _scoreColorTheme = PlayScoreColorTheme.ivory;
  bool _panelFocusMode = true;
  double _panelHeightFactor = 0.75;
  final List<ScoreNote> _playedNotes = [];
  DateTime? _sessionStart;
  bool _sustainPedalDown = false;
  bool _autoAudioPrimed = false;

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
    _loadPerformanceMode();
    _loadUltraMode();
    _loadQwerty();
    _loadVisualizationMode();
    _loadPerformanceScoreOptions();
    _loadPlayInteractionOptions();
    _visualizationTicker = Timer.periodic(
      const Duration(milliseconds: 120),
      (_) {
        if (!mounted) return;
        if (_activeNotes.isEmpty && _playedNotes.isEmpty) return;
        setState(() {});
      },
    );
    _midiEventSub = _midi.events.listen((event) {
      switch (event.type) {
        case MidiInputEventType.noteOn:
          _externalNoteOn(event.note, event.velocity / 127.0);
          break;
        case MidiInputEventType.noteOff:
          _externalNoteOff(event.note);
          break;
        case MidiInputEventType.sustain:
          _handleSustainPedal(event.sustainEnabled);
          break;
      }
    });
    _midi.devicesStream.listen((devices) {
      setState(() => _devices = devices);
    });
    _midi.status.listen((message) {
      setState(() => _status = message);
    });
    _autoConnect = _midi.autoConnectEnabled;
    _bleDirect = _midi.preferBle;
  }

  Future<void> _loadPerformanceMode() async {
    final enabled = await AppSettingsStore.getPerformanceMode();
    _audioService.setPerformanceMode(enabled);
  }

  Future<void> _loadUltraMode() async {
    final value = await AppSettingsStore.getUltraPerformanceMode();
    _audioService.setUltraMode(ultraModeFromString(value));
  }

  Future<void> _loadQwerty() async {
    final enabled = await AppSettingsStore.getQwertyEnabled();
    setState(() => _qwertyEnabled = enabled);
    _qwertyController.enabled = enabled;
  }

  Future<void> _loadVisualizationMode() async {
    final value = await AppSettingsStore.getPlayVisualizationMode();
    if (!mounted) return;
    setState(() {
      _visualizationMode = playVisualizationModeFromString(value);
    });
  }

  Future<void> _loadPerformanceScoreOptions() async {
    final tempoMode = await AppSettingsStore.getPlayTempoMode();
    final manualBpm = await AppSettingsStore.getPlayManualBpm();
    final autoKey = await AppSettingsStore.getPlayAutoKey();
    final manualKey = await AppSettingsStore.getPlayManualKeySignature();
    final autoTime = await AppSettingsStore.getPlayAutoTimeSignature();
    final manualTime = await AppSettingsStore.getPlayManualTimeSignature();
    final panelStyle = await AppSettingsStore.getPlayPanelStyle();
    final panelLayout = await AppSettingsStore.getPlayPanelLayout();
    final scoreColorTheme = await AppSettingsStore.getPlayScoreColorTheme();
    final panelFocusMode = await AppSettingsStore.getPlayPanelFocusMode();
    final panelHeight = await AppSettingsStore.getPlayPanelHeight();
    if (!mounted) return;
    setState(() {
      _tempoMode = playTempoModeFromString(tempoMode);
      _manualBpm = manualBpm;
      _autoDetectKeySignature = autoKey;
      _manualKeySignature = manualKey;
      _autoDetectTimeSignature = autoTime;
      _manualTimeSignature = manualTime;
      _panelStyle = playPanelStyleFromString(panelStyle);
      _panelLayout = playPanelLayoutFromString(panelLayout);
      _scoreColorTheme = playScoreColorThemeFromString(scoreColorTheme);
      _panelFocusMode = panelFocusMode;
      _panelHeightFactor = panelHeight;
    });
  }

  Future<void> _loadPlayInteractionOptions() async {
    final showLabels = await AppSettingsStore.getPlayShowLabels();
    final pinchZoom = await AppSettingsStore.getPlayPinchZoom();
    if (!mounted) return;
    setState(() {
      _showLabels = showLabels;
      _pinchZoom = pinchZoom;
    });
  }

  Future<void> _setManualMidiTranspose(int value) async {
    await _midi.setManualTranspose(value);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _armMidiCalibration() async {
    await _midi.armCalibration(targetLabel: 'C');
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _resetMidiDeviceAlignment() async {
    await _midi.clearCurrentDeviceTranspose();
    if (!mounted) return;
    setState(() {});
  }

  void _noteOn(int note, {double velocity = 0.8}) {
    final now = DateTime.now();
    _sessionStart ??= now;
    final elapsed = now.difference(_sessionStart!).inMilliseconds / 1000.0;
    final existingIndex = _activeNoteIndices[note];
    if (existingIndex != null && existingIndex < _playedNotes.length) {
      _finalizeNoteDuration(note, now);
    }
    final scoreNote = ScoreNote(
      midiNote: note,
      time: elapsed,
      duration: 0.18,
      hand: note < 60 ? 'L' : 'R',
      velocity: (velocity.clamp(0.0, 1.0) * 127).round(),
    );
    setState(() {
      _activeNotes.add(note);
      _sustainedNotes.remove(note);
      _lastEvent = 'Note on: $note';
      _activeNoteStarts[note] = now;
      _playedNotes.add(scoreNote);
      _activeNoteIndices[note] = _playedNotes.length - 1;
      if (_playedNotes.length > _maxVisualizedNotes) {
        _trimVisualizedNotes();
      }
    });
    _audioService.playNote(note, velocity);
  }

  void _externalNoteOn(int note, double velocity) {
    final now = DateTime.now();
    _sessionStart ??= now;
    final elapsed = now.difference(_sessionStart!).inMilliseconds / 1000.0;
    final existingIndex = _activeNoteIndices[note];
    if (existingIndex != null && existingIndex < _playedNotes.length) {
      _finalizeNoteDuration(note, now);
    }
    final scoreNote = ScoreNote(
      midiNote: note,
      time: elapsed,
      duration: 0.18,
      hand: note < 60 ? 'L' : 'R',
      velocity: (velocity.clamp(0.0, 1.0) * 127).round(),
    );
    if (!mounted) return;
    setState(() {
      _activeNotes.add(note);
      _sustainedNotes.remove(note);
      _lastEvent = 'External note on: $note';
      _activeNoteStarts[note] = now;
      _playedNotes.add(scoreNote);
      _activeNoteIndices[note] = _playedNotes.length - 1;
      if (_playedNotes.length > _maxVisualizedNotes) {
        _trimVisualizedNotes();
      }
    });
  }

  Future<void> _enableAudio() async {
    if (!kIsWeb) return;
    setState(() => _audioStatus = 'Enabling audio...');
    await WebAudioEngine.instance.unlock();
    await WebAudioEngine.instance.warmup();
    final ok = await WebAudioEngine.instance.testSound();
    setState(() {
      _audioReady = ok;
      _audioStatus = ok ? 'Audio Ready' : 'Audio failed (tap again)';
    });
  }

  void _primeAudioIfNeeded() {
    if (!kIsWeb || _audioReady || _autoAudioPrimed) return;
    _autoAudioPrimed = true;
    _enableAudio().whenComplete(() {
      _autoAudioPrimed = false;
    });
  }

  void _noteOff(int note) {
    if (_sustainPedalDown) {
      setState(() {
        _sustainedNotes.add(note);
        _lastEvent = 'Sustain hold: $note';
      });
      return;
    }
    final now = DateTime.now();
    setState(() {
      _activeNotes.remove(note);
      _lastEvent = 'Note off: $note';
      _finalizeNoteDuration(note, now);
    });
    _audioService.stopNote(note);
  }

  void _externalNoteOff(int note) {
    if (_sustainPedalDown) {
      if (!mounted) return;
      setState(() {
        _sustainedNotes.add(note);
        _lastEvent = 'External sustain hold: $note';
      });
      return;
    }
    final now = DateTime.now();
    if (!mounted) return;
    setState(() {
      _activeNotes.remove(note);
      _lastEvent = 'External note off: $note';
      _finalizeNoteDuration(note, now);
    });
  }

  void _handleSustainPedal(bool enabled) {
    if (_sustainPedalDown == enabled) return;
    final now = DateTime.now();
    setState(() {
      _sustainPedalDown = enabled;
      _lastEvent = enabled ? 'Sustain pedal down' : 'Sustain pedal up';
      if (!enabled) {
        for (final note in _sustainedNotes.toList()) {
          _activeNotes.remove(note);
          _finalizeNoteDuration(note, now);
          _audioService.stopNote(note);
        }
        _sustainedNotes.clear();
      }
    });
  }

  void _trimVisualizedNotes() {
    final overflow = _playedNotes.length - _maxVisualizedNotes;
    if (overflow <= 0) return;
    _playedNotes.removeRange(0, overflow);
    final adjusted = <int, int>{};
    _activeNoteIndices.forEach((note, index) {
      final nextIndex = index - overflow;
      if (nextIndex >= 0 && nextIndex < _playedNotes.length) {
        adjusted[note] = nextIndex;
      }
    });
    _activeNoteIndices
      ..clear()
      ..addAll(adjusted);
  }

  void _finalizeNoteDuration(int note, DateTime now) {
    final startedAt = _activeNoteStarts.remove(note);
    final index = _activeNoteIndices.remove(note);
    if (startedAt == null || index == null) return;
    if (index < 0 || index >= _playedNotes.length) return;
    final original = _playedNotes[index];
    final durationSeconds =
        now.difference(startedAt).inMilliseconds.clamp(80, 8000) / 1000.0;
    _playedNotes[index] = ScoreNote(
      midiNote: original.midiNote,
      time: original.time,
      duration: durationSeconds,
      hand: original.hand,
      velocity: original.velocity,
    );
  }

  List<ScoreNote> _liveScoreNotes() {
    final now = DateTime.now();
    return List<ScoreNote>.generate(_playedNotes.length, (index) {
      final note = _playedNotes[index];
      final activeIndex = _activeNoteIndices[note.midiNote];
      if (activeIndex != index) return note;
      final startedAt = _activeNoteStarts[note.midiNote];
      if (startedAt == null) return note;
      final durationSeconds =
          now.difference(startedAt).inMilliseconds.clamp(80, 8000) / 1000.0;
      return ScoreNote(
        midiNote: note.midiNote,
        time: note.time,
        duration: durationSeconds,
        hand: note.hand,
        velocity: note.velocity,
      );
    });
  }

  Future<void> _setVisualizationMode(PlayVisualizationMode mode) async {
    setState(() => _visualizationMode = mode);
    await AppSettingsStore.setPlayVisualizationMode(
      playVisualizationModeToString(mode),
    );
  }

  Future<void> _setShowLabels(bool value) async {
    setState(() => _showLabels = value);
    await AppSettingsStore.setPlayShowLabels(value);
  }

  Future<void> _setPinchZoom(bool value) async {
    setState(() => _pinchZoom = value);
    await AppSettingsStore.setPlayPinchZoom(value);
  }

  Future<void> _setTempoMode(PlayTempoMode mode) async {
    setState(() => _tempoMode = mode);
    await AppSettingsStore.setPlayTempoMode(playTempoModeToString(mode));
  }

  Future<void> _setManualBpm(int bpm) async {
    final next = bpm.clamp(40, 220);
    setState(() => _manualBpm = next);
    await AppSettingsStore.setPlayManualBpm(next);
  }

  Future<void> _setAutoDetectKey(bool value) async {
    setState(() => _autoDetectKeySignature = value);
    await AppSettingsStore.setPlayAutoKey(value);
  }

  Future<void> _setManualKeySignature(String value) async {
    setState(() => _manualKeySignature = value);
    await AppSettingsStore.setPlayManualKeySignature(value);
  }

  Future<void> _setAutoDetectTimeSignature(bool value) async {
    setState(() => _autoDetectTimeSignature = value);
    await AppSettingsStore.setPlayAutoTimeSignature(value);
  }

  Future<void> _setManualTimeSignature(String value) async {
    setState(() => _manualTimeSignature = value);
    await AppSettingsStore.setPlayManualTimeSignature(value);
  }

  Future<void> _setPanelStyle(PlayPanelStyle value) async {
    setState(() => _panelStyle = value);
    await AppSettingsStore.setPlayPanelStyle(playPanelStyleToString(value));
  }

  Future<void> _setPanelLayout(PlayPanelLayout value) async {
    setState(() => _panelLayout = value);
    await AppSettingsStore.setPlayPanelLayout(playPanelLayoutToString(value));
  }

  Future<void> _setPanelFocusMode(bool value) async {
    setState(() => _panelFocusMode = value);
    await AppSettingsStore.setPlayPanelFocusMode(value);
  }

  Future<void> _setScoreColorTheme(PlayScoreColorTheme value) async {
    setState(() => _scoreColorTheme = value);
    await AppSettingsStore.setPlayScoreColorTheme(
      playScoreColorThemeToString(value),
    );
  }

  Future<void> _setPanelHeightFactor(double value) async {
    final next = value.clamp(0.75, 1.6);
    setState(() => _panelHeightFactor = next);
    await AppSettingsStore.setPlayPanelHeight(next);
  }

  KeyEventResult _handleQwertyEvent(KeyEvent event) {
    return _qwertyController.handleEvent(
      event,
      onNoteOn: (note, velocity) {
        _noteOn(note, velocity: velocity);
      },
      onNoteOff: (note) {
        _noteOff(note);
      },
    );
  }

  @override
  void dispose() {
    _visualizationTicker?.cancel();
    _midiEventSub?.cancel();
    _qwertyFocusNode.dispose();
    super.dispose();
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
        final screenSize = MediaQuery.sizeOf(context);

        final compactPlayLayout =
            screenSize.width < 760 || screenSize.height < 820;
        final keyboardHeight = compactPlayLayout
            ? math.min(
                layout.keyboardHeight,
                screenSize.height < 700 ? 168.0 : 196.0,
              )
            : layout.keyboardHeight;
        final keyboard = SizedBox(
          height: keyboardHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: layout.contentPadding.horizontal / 2,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onScaleStart: (_) {
                if (!_pinchZoom) return;
                _keyboardZoomStart = _zoom;
              },
              onScaleUpdate: (details) {
                if (!_pinchZoom || details.scale == 1.0) return;
                setState(() {
                  _zoom = (_keyboardZoomStart * details.scale).clamp(0.7, 1.8);
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: theme.surfaceColor.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(layout.cardRadius),
                  border: Border.all(color: theme.textColor.withOpacity(0.1)),
                ),
                child: BasicPianoKeyboard(
                  activeNotes: Set<int>.from(_activeNotes),
                  showNoteLabels: _showLabels,
                  allowPinchZoom: false,
                  zoom: _zoom,
                  onNoteOn: _noteOn,
                  onNoteOff: _noteOff,
                ),
              ),
            ),
          ),
        );
        final liveNotes = _liveScoreNotes();
        final currentTime = _sessionStart == null
            ? 0.0
            : DateTime.now().difference(_sessionStart!).inMilliseconds / 1000.0;

        final deviceList = _devices.isNotEmpty
            ? SizedBox(
                height: layout.compactControls ? 96 : 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final d = _devices[index];
                    return MotionCard(
                      color: theme.surfaceColor.withOpacity(0.76),
                      borderColor: theme.textColor.withOpacity(0.1),
                      radius: layout.cardRadius,
                      glowColor: theme.primaryColor,
                      margin: const EdgeInsets.fromLTRB(12, 0, 0, 12),
                      padding: const EdgeInsets.all(12),
                      child: Container(
                      width: 220,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            d.source,
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            color: d.isConnected
                                ? CupertinoColors.systemGreen
                                : theme.primaryColor.withOpacity(0.8),
                            onPressed: d.isConnected
                                ? _midi.disconnect
                                : () => _midi.connect(d.id),
                            child: Text(
                              d.isConnected ? 'Connected' : 'Connect',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      ),
                    );
                  },
                ),
              )
            : const SizedBox.shrink();

        final content = CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            backgroundColor: theme.surfaceColor,
            middle: Text(
              'GrandPiano',
              style: TextStyle(color: theme.textColor),
            ),
            trailing: const UiSwitcher(),
          ),
          child: MotionBackdrop(
            backgroundColor: theme.backgroundColor,
            surfaceColor: theme.surfaceColor,
            accentColor: theme.primaryColor,
            child: SafeArea(
              child: Column(
                children: [
            MotionReveal(
              delay: const Duration(milliseconds: 40),
              child: Padding(
              padding: EdgeInsets.fromLTRB(
                  layout.contentPadding.left,
                  layout.contentPadding.top,
                  layout.contentPadding.right,
                  layout.compactControls ? 4 : 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                  SizedBox(
                    width: compactPlayLayout ? 180 : 240,
                    child: Text(
                      _status,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (kIsWeb) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: compactPlayLayout ? 140 : 180,
                      child: Text(
                        _audioStatus,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor.withOpacity(0.7),
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 4),
                    CupertinoButton(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      color: theme.surfaceColor,
                      onPressed: _enableAudio,
                      child: Text(
                        _audioReady ? 'Test Audio' : 'Enable Audio',
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    color: theme.surfaceColor,
                    onPressed: () async {
                      final next = !_autoConnect;
                      await _midi.setAutoConnect(next);
                      setState(() => _autoConnect = next);
                    },
                    child: Text(
                      _autoConnect ? 'Auto: ON' : 'Auto: OFF',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    color: theme.surfaceColor,
                    onPressed: () async {
                      final next = !_bleDirect;
                      await _midi.setPreferBle(next);
                      setState(() => _bleDirect = next);
                    },
                    child: Text(
                      _bleDirect ? 'BLE: ON' : 'BLE: OFF',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    color: theme.surfaceColor,
                    onPressed: () => _midi.scan(),
                    child: Text(
                      _midi.isScanning ? 'Scanning...' : 'Scan MIDI',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    color: theme.surfaceColor,
                    onPressed: () => _setShowLabels(!_showLabels),
                    child: Text(
                      _showLabels ? 'Hide Labels' : 'Show Labels',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    color: theme.surfaceColor,
                    onPressed: () => _setPinchZoom(!_pinchZoom),
                    child: Text(
                      _pinchZoom ? 'Pinch: ON' : 'Pinch: OFF',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    color: theme.surfaceColor,
                    onPressed: () {
                      setState(() => _zoom = (_zoom - 0.1).clamp(0.7, 1.8));
                    },
                    child: Text(
                      'Zoom -',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    color: theme.surfaceColor,
                    onPressed: () {
                      setState(() => _zoom = (_zoom + 0.1).clamp(0.7, 1.8));
                    },
                    child: Text(
                      'Zoom +',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            )),
            MotionReveal(
              delay: const Duration(milliseconds: 110),
              child: Padding(
              padding: EdgeInsets.fromLTRB(
                layout.contentPadding.left,
                0,
                layout.contentPadding.right,
                compactPlayLayout ? 6 : 8,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: CupertinoSlidingSegmentedControl<PlayVisualizationMode>(
                  backgroundColor: theme.surfaceColor.withOpacity(0.74),
                  thumbColor: theme.primaryColor.withOpacity(0.88),
                  groupValue: _visualizationMode,
                  onValueChanged: (value) {
                    if (value == null) return;
                    _setVisualizationMode(value);
                  },
                  children: const {
                    PlayVisualizationMode.classic: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text('Classic'),
                    ),
                    PlayVisualizationMode.notation: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text('Staff'),
                    ),
                    PlayVisualizationMode.tablature: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text('Tab'),
                    ),
                    PlayVisualizationMode.both: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text('Both'),
                    ),
                  },
                ),
              ),
            )),
            if (_visualizationMode != PlayVisualizationMode.classic)
              MotionReveal(
                delay: const Duration(milliseconds: 170),
                child: LivePlayVisualization(
                notes: liveNotes,
                activeNotes: Set<int>.from(_activeNotes),
                currentTime: currentTime,
                timeSignature: '4/4',
                keySignature: 'C Major',
                backgroundColor: theme.backgroundColor.withOpacity(0.96),
                panelColor: theme.surfaceColor,
                textColor: theme.textColor,
                accentColor: theme.primaryColor,
                mode: _visualizationMode,
                sustainPedalDown: _sustainPedalDown,
                tempoMode: _tempoMode,
                manualBpm: _manualBpm,
                autoDetectKeySignature: _autoDetectKeySignature,
                manualKeySignature: _manualKeySignature,
                autoDetectTimeSignature: _autoDetectTimeSignature,
                manualTimeSignature: _manualTimeSignature,
                panelStyle: _panelStyle,
                panelLayout: _panelLayout,
                scoreColorTheme: _scoreColorTheme,
                focusMode: _panelFocusMode,
                panelHeightFactor: _panelHeightFactor,
                manualMidiTranspose: _midi.manualTranspose,
                deviceMidiTranspose: _midi.currentDeviceTranspose,
                effectiveMidiTranspose: _midi.effectiveTranspose,
                activeMidiDeviceName: _midi.activeInputDeviceName ?? '',
                midiCalibrationArmed: _midi.calibrationArmed,
                onTempoModeChanged: _setTempoMode,
                onManualBpmChanged: _setManualBpm,
                onAutoDetectKeyChanged: _setAutoDetectKey,
                onManualKeySignatureChanged: _setManualKeySignature,
                onAutoDetectTimeSignatureChanged: _setAutoDetectTimeSignature,
                onManualTimeSignatureChanged: _setManualTimeSignature,
                onPanelStyleChanged: _setPanelStyle,
                onPanelLayoutChanged: _setPanelLayout,
                onScoreColorThemeChanged: _setScoreColorTheme,
                onFocusModeChanged: _setPanelFocusMode,
                onPanelHeightChanged: _setPanelHeightFactor,
                onManualMidiTransposeChanged: (value) {
                  _setManualMidiTranspose(value);
                },
                onArmMidiCalibration: () {
                  _armMidiCalibration();
                },
                onResetMidiDeviceAlignment: () {
                  _resetMidiDeviceAlignment();
                },
              )),
            if (_visualizationMode != PlayVisualizationMode.classic)
              MotionReveal(
                delay: const Duration(milliseconds: 190),
                child: LivePlayAdjustmentPanel(
                  textColor: theme.textColor,
                  panelColor: theme.surfaceColor,
                  accentColor: theme.primaryColor,
                  tempoMode: _tempoMode,
                  manualBpm: _manualBpm,
                  autoDetectKeySignature: _autoDetectKeySignature,
                  manualKeySignature: _manualKeySignature,
                  autoDetectTimeSignature: _autoDetectTimeSignature,
                  manualTimeSignature: _manualTimeSignature,
                  panelStyle: _panelStyle,
                  panelLayout: _panelLayout,
                  scoreColorTheme: _scoreColorTheme,
                  focusMode: _panelFocusMode,
                  panelHeightFactor: _panelHeightFactor,
                  manualMidiTranspose: _midi.manualTranspose,
                  deviceMidiTranspose: _midi.currentDeviceTranspose,
                  effectiveMidiTranspose: _midi.effectiveTranspose,
                  activeMidiDeviceName: _midi.activeInputDeviceName ?? '',
                  midiCalibrationArmed: _midi.calibrationArmed,
                  onTempoModeChanged: _setTempoMode,
                  onManualBpmChanged: _setManualBpm,
                  onAutoDetectKeyChanged: _setAutoDetectKey,
                  onManualKeySignatureChanged: _setManualKeySignature,
                  onAutoDetectTimeSignatureChanged:
                      _setAutoDetectTimeSignature,
                  onManualTimeSignatureChanged: _setManualTimeSignature,
                  onPanelStyleChanged: _setPanelStyle,
                  onPanelLayoutChanged: _setPanelLayout,
                  onScoreColorThemeChanged: _setScoreColorTheme,
                  onFocusModeChanged: _setPanelFocusMode,
                  onPanelHeightChanged: _setPanelHeightFactor,
                  onManualMidiTransposeChanged: (value) {
                    _setManualMidiTranspose(value);
                  },
                  onArmMidiCalibration: () {
                    _armMidiCalibration();
                  },
                  onResetMidiDeviceAlignment: () {
                    _resetMidiDeviceAlignment();
                  },
                ),
              ),
            if (layout.keyboardOnTop) ...[
              MotionReveal(
                delay: const Duration(milliseconds: 230),
                child: keyboard,
              ),
              if (!compactPlayLayout) deviceList,
              if (!compactPlayLayout) const Spacer(),
            ] else ...[
              if (!compactPlayLayout) deviceList,
              if (!compactPlayLayout) const Spacer(),
              MotionReveal(
                delay: const Duration(milliseconds: 230),
                child: keyboard,
              ),
              if (compactPlayLayout) const SizedBox(height: 8),
              if (compactPlayLayout) deviceList,
            ],
                ],
              ),
            ),
          ),
        );

        return Focus(
          autofocus: true,
          focusNode: _qwertyFocusNode,
          onKeyEvent: (node, event) {
            if (!_qwertyEnabled) return KeyEventResult.ignored;
            return _handleQwertyEvent(event);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _primeAudioIfNeeded();
              _qwertyFocusNode.requestFocus();
            },
            onTapDown: (_) => _primeAudioIfNeeded(),
            onPanDown: (_) => _primeAudioIfNeeded(),
            child: content,
          ),
        );
      },
    );
  }
}
