import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';

// Import all services
import 'midi_service.dart';
import 'audio_player_service.dart';
import 'latency_settings_screen.dart';
import 'proactive_ai_tutor_service.dart';
import 'piano_keyboard_widget.dart';
import 'piano_lesson_screen.dart';
import 'theme_service.dart';
import 'settings_screen.dart';
import 'debug_log_panel.dart';
import 'classical_songs_library.dart';
import 'midi_controller_presets.dart';
import 'enhanced_device_selection_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool envLoaded = false;
  bool supabaseInitialized = false;
  bool aiInitialized = false;

  try {
    await WakelockPlus.enable();
    print('🔒 Wake lock enabled - device will stay awake during practice');
  } catch (e) {
    print('⚠️ Wake lock error: $e');
  }

  try {
    await dotenv.load(fileName: "assets/.env");
    envLoaded = true;
    print('✅ .env file loaded successfully');
  } catch (e) {
    print('⚠️ .env file not found - running in local-only mode');
  }

  if (envLoaded) {
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
        await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
        supabaseInitialized = true;
        print('✅ Supabase initialized');
      }
    } catch (e) {
      print('⚠️ Supabase init failed: $e');
    }

    try {
      final openAiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
      if (openAiKey.isNotEmpty) {
        ProactiveAITutorService.initialize(openAiKey);
        aiInitialized = true;
        print('✅ AI Tutor initialized');
      }
    } catch (e) {
      print('⚠️ AI init failed: $e');
    }
  }

  await ThemeService.loadTheme();

  print('\n📊 Initialization Summary:');
  print('Environment: ${envLoaded ? "✅" : "❌"}');
  print('Supabase: ${supabaseInitialized ? "✅" : "❌"}');
  print('AI Tutor: ${aiInitialized ? "✅" : "❌"}');
  print('Theme: ${ThemeService.theme.name}');
  print('Layout: ${ThemeService.layout.name}');
  print('\n🚀 Starting MIDI Piano Pro...\n');

  runApp(MidiPianoApp(
    supabaseEnabled: supabaseInitialized,
    aiEnabled: aiInitialized,
  ));
}

class MidiPianoApp extends StatefulWidget {
  final bool supabaseEnabled;
  final bool aiEnabled;

  const MidiPianoApp({
    super.key,
    required this.supabaseEnabled,
    required this.aiEnabled,
  });

  @override
  State<MidiPianoApp> createState() => _MidiPianoAppState();
}

class _MidiPianoAppState extends State<MidiPianoApp> {
  void _refreshTheme() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService.theme;

    return CupertinoApp(
      title: 'MIDI Piano Pro',
      theme: CupertinoThemeData(
        primaryColor: theme.primaryColor,
        brightness: theme.brightness,
        scaffoldBackgroundColor: theme.backgroundColor,
        textTheme: CupertinoTextThemeData(
          primaryColor: theme.textColor,
        ),
      ),
      home: MidiPianoHome(
        supabaseEnabled: widget.supabaseEnabled,
        aiEnabled: widget.aiEnabled,
        onThemeChanged: _refreshTheme,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MidiPianoHome extends StatefulWidget {
  final bool supabaseEnabled;
  final bool aiEnabled;
  final VoidCallback onThemeChanged;

  const MidiPianoHome({
    super.key,
    required this.supabaseEnabled,
    required this.aiEnabled,
    required this.onThemeChanged,
  });

  @override
  State<MidiPianoHome> createState() => _MidiPianoHomeState();
}

class _MidiPianoHomeState extends State<MidiPianoHome>
    with WidgetsBindingObserver {
  final MidiService _midiService = MidiService();
  final AudioPlayerService _audioService = AudioPlayerService();
  late final ProactiveAITutorService _aiTutor;

  bool _isConnected = false;
  bool _isScanning = false;
  String _connectionStatus = 'Disconnected';
  String _deviceType = '';
  List<Map<String, dynamic>> _availableDevices = [];
  final Set<int> _activeNotes = {};
  double _latency = 0.0;
  double _volume = 1.0;
  String _aiTutorMessage = '';
  bool _showAITutor = true;
  Timer? _aiTutorTimer;
  int _currentTab = 0;
  bool _wakeLockEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _aiTutor = ProactiveAITutorService();
    _setupProactiveAI();
    _initializeServices();
    _loadWakeLockPreference();

    if (widget.aiEnabled) {
      _loadWelcomeMessage();
    } else {
      setState(() {
        _aiTutorMessage =
            'Welcome to MIDI Piano Pro! Connect your 88-key MIDI controller to begin. 🎹';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _aiTutorTimer?.cancel();
    _midiService.dispose();
    _audioService.dispose();
    _aiTutor.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _audioService.stopAllNotes();
      if (_wakeLockEnabled) {
        WakelockPlus.disable();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wakeLockEnabled) {
        WakelockPlus.enable();
      }
    }
  }

  Future<void> _loadWakeLockPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('wake_lock_enabled') ?? true;
      setState(() => _wakeLockEnabled = enabled);
      if (_wakeLockEnabled) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (e) {
      print('Error loading wake lock preference: $e');
    }
  }

  void _setupProactiveAI() {
    _aiTutor.onProactiveSuggestion = (message) {
      _showAITutorTip(message, duration: 8);
    };
    _aiTutor.onEncouragement = (message) {
      _showAITutorTip(message, duration: 5);
    };
  }

  Future<void> _initializeServices() async {
    await _audioService.initialize();
    await _loadLatencySettings();

    // Listen for device list updates
    _midiService.onDevicesUpdated = (devices) {
      if (mounted) {
        setState(() {
          _availableDevices = devices;
        });
      }
    };

    // Listen for scanning status changes
    _midiService.onScanStatusChanged = (isScanning) {
      if (mounted) {
        setState(() {
          _isScanning = isScanning;
        });
      }
    };

    _midiService.onMidiDataReceived = _handleMidiData;
    _midiService.onConnectionStatusChanged = (status, deviceName, deviceType) {
      setState(() {
        _isConnected = status;
        _deviceType = deviceType;
        _connectionStatus =
            status ? 'Connected to $deviceName' : 'Disconnected';
      });
      if (status) {
        _showAITutorTip(
            '🎉 Connected to $deviceName! All 88 keys ready. Let\'s make music!');
      }
    };

    _midiService.onErrorOccurred = (error) {
      _showErrorDialog('MIDI Error', error);
    };
  }

  Future<void> _loadWelcomeMessage() async {
    if (!widget.aiEnabled) return;
    try {
      final message = await _aiTutor.getWelcomeMessage();
      setState(() {
        _aiTutorMessage = message;
        _showAITutor = true;
      });
    } catch (e) {
      print('Failed to load welcome message: $e');
      setState(() {
        _aiTutorMessage =
            '👋 Welcome! I\'m your AI piano tutor. Connect your MIDI keyboard and let\'s start learning!';
      });
    }
  }

  Future<void> _loadLatencySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLatency = prefs.getDouble('latency_setting') ?? 0.0;
      final savedVolume = prefs.getDouble('volume_setting') ?? 1.0;
      setState(() {
        _latency = savedLatency;
        _volume = savedVolume;
      });
      _audioService.setLatency(savedLatency);
      _audioService.setMasterVolume(savedVolume);
    } catch (e) {
      print('Using default latency: $e');
    }
  }

  void _handleMidiData(List<int> data) {
    if (data.isEmpty) return;
    final status = data[0];
    final statusType = status & 0xF0;

    if (statusType == 0x90 || statusType == 0x80) {
      if (data.length < 3) return;
      final note = data[1];
      final velocity = data[2];
      if (note < 21 || note > 108) return;

      if (statusType == 0x90 && velocity > 0) {
        _audioService.playNote(note, velocity / 127.0, fromMidi: true);
        setState(() => _activeNotes.add(note));
        if (widget.aiEnabled) {
          _aiTutor.trackNotePlay(note, velocity / 127.0);
        }
      } else {
        _audioService.stopNote(note);
        setState(() => _activeNotes.remove(note));
      }
    } else if (statusType == 0xB0 && data.length >= 3) {
      final controller = data[1];
      final value = data[2];
      if (controller == 64) {
        _audioService.setSustain(value >= 64);
      }
    }
  }

  Future<void> _showAITutorTip(String message, {int duration = 5}) async {
    setState(() {
      _aiTutorMessage = message;
      _showAITutor = true;
    });
    _aiTutorTimer?.cancel();
    _aiTutorTimer = Timer(Duration(seconds: duration), () {
      if (mounted && _currentTab == 0) {
        setState(() => _showAITutor = true);
      }
    });
  }

  Future<void> _scanForDevices() async {
    setState(() {
      _isScanning = true;
      _availableDevices.clear();
    });
    await _midiService.scanForDevices();
    // isScanning state is now handled by the onScanStatusChanged callback
  }

  Future<void> _connectToDevice(String deviceId, String deviceName) async {
    try {
      await _midiService.connectToDevice(deviceId, deviceName);
      if (mounted) {
        Navigator.pop(context); // Close the dialog
      }
    } catch (e) {
      _showErrorDialog('Connection Failed', e.toString());
    }
  }

  void _showDeviceSelectionDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => EnhancedDeviceSelectionDialog(
        onConnect: _connectToDevice,
        onScan: _scanForDevices,
        availableDevices: _availableDevices,
        isScanning: _isScanning,
        autoConnectEnabled: _midiService.autoConnectEnabled,
        onAutoConnectChanged: (enabled) {
          _midiService.setAutoConnect(enabled);
          setState(() {});
        },
        lastConnectedDevice: _midiService.lastConnectedDeviceName,
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService.theme;
    final layout = ThemeService.layout;

    return CupertinoPageScaffold(
      backgroundColor: theme.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: theme.cardGradient,
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => SettingsScreen(
                            onThemeChanged: () {
                              widget.onThemeChanged();
                              setState(() {});
                            },
                          ),
                        ),
                      );
                    },
                    child: Icon(
                      CupertinoIcons.settings,
                      color: theme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'MIDI Piano Pro',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => DebugLogPanel(
                            getDebugStats: () => _midiService.getDebugStats(),
                            getDebugLog: () => _midiService.getDebugLog(),
                            onClearLog: () {},
                          ),
                        ),
                      );
                    },
                    child: Icon(
                      CupertinoIcons.chart_bar_alt_fill,
                      color: theme.accentColor,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: [
                  _buildHomeTab(theme, layout),
                  PianoLessonScreen(
                    aiTutor: _aiTutor,
                    audioService: _audioService,
                    activeNotes: _activeNotes,
                  ),
                  ClassicalSongsScreen(
                    audioService: _audioService,
                    aiTutor: _aiTutor,
                    activeNotes: _activeNotes,
                  ),
                  LatencySettingsScreen(
                    currentLatency: _latency,
                    currentVolume: _volume,
                    onLatencyChanged: (newLatency) {
                      setState(() => _latency = newLatency);
                      _audioService.setLatency(newLatency);
                    },
                    onVolumeChanged: (newVolume) {
                      setState(() => _volume = newVolume);
                      _audioService.setMasterVolume(newVolume);
                    },
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: theme.cardGradient,
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildNavButton(0, CupertinoIcons.house_fill, 'Home', theme),
                  _buildNavButton(
                      1, CupertinoIcons.book_fill, 'Lessons', theme),
                  _buildNavButton(
                      2, CupertinoIcons.music_albums_fill, 'Songs', theme),
                  _buildNavButton(
                      3, CupertinoIcons.slider_horizontal_3, 'Settings', theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(
      int index, IconData icon, String label, ThemeData theme) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 12),
        onPressed: () => setState(() => _currentTab = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.primaryColor
                  : theme.textColor.withOpacity(0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.primaryColor
                    : theme.textColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab(ThemeData theme, LayoutData layout) {
    return Container(
      decoration: BoxDecoration(gradient: theme.backgroundGradient),
      child: Column(
        children: [
          if (_showAITutor && layout.showAIBanner)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: layout.padding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.withOpacity(0.2),
                    theme.secondaryColor.withOpacity(0.2),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.sparkles,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _aiTutorMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _showAITutor = false),
                    child: Icon(
                      CupertinoIcons.xmark,
                      size: 20,
                      color: theme.textColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: layout.padding,
            decoration: BoxDecoration(
              gradient: _isConnected
                  ? LinearGradient(
                      colors: [
                        theme.accentColor.withOpacity(0.2),
                        theme.accentColor.withOpacity(0.1),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        CupertinoColors.systemGrey6,
                        CupertinoColors.systemGrey5,
                      ],
                    ),
            ),
            child: Row(
              children: [
                Icon(
                  _isConnected
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.xmark_circle_fill,
                  color: _isConnected
                      ? theme.accentColor
                      : CupertinoColors.systemGrey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _connectionStatus,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                      if (_isConnected && !layout.compactControls) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Active: ${_activeNotes.length} | Latency: ${_latency.toStringAsFixed(1)}ms',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isConnected
                ? Column(
                    children: [
                      PianoKeyboardWidget(
                        activeNotes: _activeNotes,
                        height: layout.keyboardHeight,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: CompactPianoDisplay(
                          activeNotes: _activeNotes,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.music_note_2,
                                size: 80,
                                color: theme.primaryColor.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Playing...',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: theme.textColor.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '88 Keys Ready (A0-C8)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textColor.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : _buildWelcomeScreen(theme),
          ),
          if (layout.showQuickStats && _isConnected)
            Container(
              padding: layout.padding,
              decoration: BoxDecoration(
                gradient: theme.cardGradient,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickStat(
                    icon: CupertinoIcons.music_note_2,
                    label: 'Notes',
                    value: '${_activeNotes.length}',
                    color: theme.primaryColor,
                    textColor: theme.textColor,
                  ),
                  _QuickStat(
                    icon: CupertinoIcons.timer,
                    label: 'Latency',
                    value: '${_latency.toStringAsFixed(0)}ms',
                    color: theme.accentColor,
                    textColor: theme.textColor,
                  ),
                  _QuickStat(
                    icon: CupertinoIcons.speaker_2_fill,
                    label: 'Volume',
                    value: '${(_volume * 100).toInt()}%',
                    color: theme.secondaryColor,
                    textColor: theme.textColor,
                  ),
                ],
              ),
            ),
          if (_isConnected)
            Container(
              padding: layout.padding,
              child: CupertinoButton.filled(
                onPressed: () => _midiService.disconnect(),
                child: const Text('Disconnect'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primaryColor, theme.secondaryColor],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.music_note_2,
                size: 70,
                color: CupertinoColors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'MIDI Piano Pro',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI-Powered • 88 Keys • Low Latency',
              style: TextStyle(
                fontSize: 16,
                color: theme.textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: _showDeviceSelectionDialog,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.bluetooth),
                    SizedBox(width: 12),
                    Text('Connect MIDI Device'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.info_circle_fill,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Supports 88-Key Controllers',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• M-Audio Oxygen 88\n• Yamaha, Roland, Korg pianos\n• Any standard 88-key MIDI device',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color textColor;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
