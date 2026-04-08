import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_theme.dart';
import '../services/offline_cache_service.dart';
import '../services/app_settings_store.dart';
import '../services/audio_player_service.dart';
import '../services/midi_service_lite.dart';
import '../services/web_audio_engine.dart';
import '../ui/ui_controller.dart';
import '../ui/ui_presets.dart';
import '../utils/velocity_curve.dart';
import '../widgets/connection_wizard.dart';
import 'safe_debug_screen.dart';
import 'safe_home_screen.dart';
import 'safe_library_screen.dart';
import 'safe_score_library_screen.dart';
import 'safe_settings_screen.dart';

class SafeShell extends StatefulWidget {
  const SafeShell({super.key});

  @override
  State<SafeShell> createState() => _SafeShellState();
}

class _SafeShellState extends State<SafeShell> {
  bool _prefetchStarted = false;
  final AudioPlayerService _audioService = AudioPlayerService();
  final MidiServiceLite _midi = MidiServiceLite.instance;
  StreamSubscription<MidiInputEvent>? _midiEventSub;
  bool _globalSustain = false;

  @override
  void initState() {
    super.initState();
    _startOfflinePackIfNeeded();
    UiController.load();
    _initGlobalMidi();
  }

  Future<void> _initGlobalMidi() async {
    await _midi.initialize();
    _midiEventSub = _midi.events.listen((event) {
      switch (event.type) {
        case MidiInputEventType.noteOn:
          _audioService.playNote(event.note, event.velocity / 127.0);
          break;
        case MidiInputEventType.noteOff:
          _audioService.stopNote(event.note);
          break;
        case MidiInputEventType.sustain:
          _globalSustain = event.sustainEnabled;
          _audioService.setSustain(_globalSustain);
          break;
      }
    });
  }

  Future<void> _startOfflinePackIfNeeded() async {
    if (_prefetchStarted) return;
    _prefetchStarted = true;
    try {
      final volume = await AppSettingsStore.getVolume();
      final performanceMode = await AppSettingsStore.getPerformanceMode();
      final ultraMode =
          ultraModeFromString(await AppSettingsStore.getUltraPerformanceMode());
      final audioSustain = await AppSettingsStore.getAudioSustain();
      final audioLatency = await AppSettingsStore.getAudioLatencyMs();
      final audioReverb = await AppSettingsStore.getAudioReverbLevel();
      final audioDebug = await AppSettingsStore.getAudioDebugLogging();
      final velocityPreset = velocityCurvePresetFromString(
        await AppSettingsStore.getVelocityCurvePreset(),
      );
      final velocityExponent =
          await AppSettingsStore.getVelocityCurveExponent();
      _audioService.setMasterVolume(volume);
      _audioService.setPerformanceMode(performanceMode);
      _audioService.setUltraMode(ultraMode);
      _audioService.setSustain(audioSustain);
      _audioService.setLatency(audioLatency);
      _audioService.setReverbLevel(audioReverb);
      _audioService.setDebugLogging(audioDebug);
      _audioService.setVelocityCurve(velocityPreset, velocityExponent);
      await _audioService.initialize();
      if (kIsWeb) {
        WebAudioEngine.instance.warmup();
      }
      final ready = await OfflineCacheService.isOfflinePackReady();
      if (!ready) {
        await OfflineCacheService.prefetchCoreAssets();
      }
    } catch (_) {
      // Ignore startup failures to keep the app booting.
    }
  }

  @override
  void dispose() {
    _midiEventSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UiController.config,
      builder: (context, config, _) {
        final style = UiPresets.styles[config.styleIndex];
        final theme = AppTheme.fromStyle(
          background: style.background,
          surface: style.surface,
          primary: style.primary,
          secondary: style.secondary,
          text: style.text,
          accent: style.accent,
          brightness: style.brightness,
        );
        return Stack(
          children: [
            CupertinoTabScaffold(
              tabBar: CupertinoTabBar(
                backgroundColor: theme.surfaceColor,
                activeColor: theme.primaryColor,
                inactiveColor: theme.textColor.withOpacity(0.5),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.music_note_2),
                    label: 'Play',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.music_albums),
                    label: 'Library',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.music_note_list),
                    label: 'Sheet Music',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.settings),
                    label: 'Settings',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.ant_circle),
                    label: 'Debug',
                  ),
                ],
              ),
              tabBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return const SafeHomeScreen();
                  case 1:
                    return const SafeLibraryScreen();
                  case 2:
                    return const SafeScoreLibraryScreen();
                  case 3:
                    return const SafeSettingsScreen();
                  default:
                    return const SafeDebugScreen();
                }
              },
            ),
            Positioned(
              top: 12,
              right: 12,
              child: SafeArea(
                bottom: false,
                child: ConnectionWizardButton(
                  backgroundColor: theme.surfaceColor,
                  textColor: theme.textColor,
                  accentColor: theme.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
