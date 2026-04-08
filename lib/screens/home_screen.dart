// ============================================
// FIXED home_screen.dart - ALL ERRORS RESOLVED
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    hide ThemeData; // FIXED: Hide Material ThemeData
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/audio_player_service.dart';
import '../services/midi_service.dart';
import '../services/aws_service.dart';
import '../services/enhanced_ai_tutor_service.dart';
import '../services/web_audio_engine.dart';
import '../services/app_settings_store.dart';
import '../utils/theme_service.dart' as theme_service; // FIXED: Use alias
import '../models/complete_songs_library.dart'; // FIXED: Correct import
import '../widgets/enhanced_piano_keyboard.dart';
import '../widgets/keyboard_settings_panel.dart';
import '../widgets/connection_status_panel.dart';
import '../widgets/ai_chat_widget.dart';
import '../utils/note_state_controller.dart';
import '../utils/velocity_curve.dart';
import '../utils/qwerty_midi.dart';
import 'lesson_screen.dart';
import 'complete_song_lesson_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';

class CompleteHomeScreen extends StatefulWidget {
  final bool cloudEnabled;
  final bool aiEnabled;
  final Function() onThemeChanged;

  const CompleteHomeScreen({
    super.key,
    required this.cloudEnabled,
    required this.aiEnabled,
    required this.onThemeChanged,
  });

  @override
  State<CompleteHomeScreen> createState() => _CompleteHomeScreenState();
}

class _CompleteHomeScreenState extends State<CompleteHomeScreen>
    with TickerProviderStateMixin {
  // Services
  final AudioPlayerService _audioService = AudioPlayerService();
  final MidiService _midiService =
      MidiService(); // FIXED: Use MidiService (not ImprovedMidiService)
  final AwsService _cloudService = AwsService.instance;
  EnhancedAITutorService? _aiTutor;

  // State
  final NoteStateController _noteState = NoteStateController();
  final ValueNotifier<double> _lastMidiVelocity = ValueNotifier(0.0);
  final ValueNotifier<Map<String, dynamic>> _perfStats =
      ValueNotifier(<String, dynamic>{});
  Timer? _perfTimer;

  // Connection status
  bool _isMidiConnected = false;
  String _midiDeviceName = '';
  String _midiDeviceType = '';
  bool _isScanning = false;

  // UI State
  int _selectedTab = 0;
  KeyboardSettings _keyboardSettings = KeyboardSettings();
  String? _currentSessionId;
  double _masterVolume = 0.8;
  String _ultraMode = 'off';
  bool _qwertyEnabled = true;
  final FocusNode _qwertyFocusNode = FocusNode();
  final QwertyMidiController _qwertyController = QwertyMidiController();
  bool _audioReady = !kIsWeb;
  String _audioStatus = kIsWeb ? 'Tap Enable Audio' : 'Audio Ready';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final settings = await _loadKeyboardSettings();
    _audioService.setPerformanceMode(settings.performanceMode);
    _masterVolume = await AppSettingsStore.getVolume();
    _audioService.setMasterVolume(_masterVolume);
    await _audioService.initialize();
    await _loadUltraMode();
    await _loadQwerty();
    if (!kIsWeb) {
      await _setupMidiService(); // FIXED: Setup MIDI callbacks properly
      await _midiService.ensurePermissionsAndServices();
    }

    if (widget.aiEnabled) {
      _aiTutor = EnhancedAITutorService();
    }

    if (widget.cloudEnabled && _cloudService.isInitialized) {
      _currentSessionId = await _cloudService.startSession();
    }

    _startPerformanceMonitor();
  }

  // FIXED: Setup MIDI service callbacks
  Future<void> _setupMidiService() async {
    // Setup MIDI data callback
    _midiService.onMidiDataReceived = (data) {
      // Parse MIDI data manually since onNoteEvent doesn't exist
      if (data.length >= 3) {
        final status = data[0];
        final messageType = status & 0xF0;
        final note = data[1];
        final velocity = data[2];

        if (messageType == 0xB0 && note == 64) {
          if (_keyboardSettings.pedalInstalled) {
            _audioService.setSustain(velocity >= 64);
          }
          return;
        }

        if (messageType == 0x90 && velocity > 0) {
          // Note On
          final normalizedVelocity = velocity / 127.0;
          _lastMidiVelocity.value = normalizedVelocity;
          _noteState.noteOn(note, normalizedVelocity);
          _audioService.playNote(note, normalizedVelocity);
          _aiTutor?.trackNotePlay(note, normalizedVelocity);
        } else if (messageType == 0x80 ||
            (messageType == 0x90 && velocity == 0)) {
          // Note Off
          _noteState.noteOff(note);
          _audioService.stopNote(note);
        }
      }
    };

    // Setup connection status callback
    _midiService.onConnectionStatusChanged =
        (connected, deviceName, deviceType) {
      setState(() {
        _isMidiConnected = connected;
        _midiDeviceName = deviceName;
        _midiDeviceType = deviceType;
      });
    };

    // Setup error callback
    _midiService.onErrorOccurred = (error) {
      _showErrorDialog(error);
    };
  }

  Future<KeyboardSettings> _loadKeyboardSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = KeyboardSettings(
      height: prefs.getDouble('keyboard_height') ?? 200.0,
      showNoteNames: prefs.getBool('show_note_names') ?? true,
      performanceMode: prefs.getBool('performance_mode') ?? true,
      pedalInstalled: prefs.getBool('pedal_installed') ?? false,
      velocityCurvePreset: velocityCurvePresetFromString(
          prefs.getString('velocity_curve_preset')),
      velocityCurveExponent:
          prefs.getDouble('velocity_curve_exponent') ?? 1.0,
    );
    setState(() {
      _keyboardSettings = settings;
    });
    _audioService.setVelocityCurve(
        settings.velocityCurvePreset, settings.velocityCurveExponent);
    return settings;
  }

  Future<void> _saveKeyboardSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('keyboard_height', _keyboardSettings.height);
    await prefs.setBool('show_note_names', _keyboardSettings.showNoteNames);
    await prefs.setBool('performance_mode', _keyboardSettings.performanceMode);
    await AppSettingsStore.setPerformanceMode(_keyboardSettings.performanceMode);
    await prefs.setBool('pedal_installed', _keyboardSettings.pedalInstalled);
    await prefs.setString('velocity_curve_preset',
        velocityCurvePresetToString(_keyboardSettings.velocityCurvePreset));
    await prefs.setDouble(
        'velocity_curve_exponent', _keyboardSettings.velocityCurveExponent);
  }

  Future<void> _loadUltraMode() async {
    final value = await AppSettingsStore.getUltraPerformanceMode();
    setState(() => _ultraMode = value);
    _audioService.setUltraMode(ultraModeFromString(value));
  }

  Future<void> _loadQwerty() async {
    final enabled = await AppSettingsStore.getQwertyEnabled();
    setState(() => _qwertyEnabled = enabled);
    _qwertyController.enabled = enabled;
  }

  void _handleTouchNote(int note) {
    _noteState.noteOn(note, 0.8);
    _audioService.playNote(note, 0.8);
    _aiTutor?.trackNotePlay(note, 0.8);
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

  void _handleTouchRelease(int note) {
    _noteState.noteOff(note);
    _audioService.stopNote(note);
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _startPerformanceMonitor() {
    _perfTimer?.cancel();
    _perfTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_keyboardSettings.performanceMode) return;
      final audio = _audioService.getPerformanceStats();
      _perfStats.value = {
        'queue': _midiService.queueSize,
        'dropped': _midiService.droppedPackets,
        'voices': audio['activeNotes'],
        'poly': audio['maxPlayersPerNote'],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = theme_service.ThemeService.theme; // FIXED: Use alias

    final content = CupertinoPageScaffold(
      backgroundColor: theme.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(theme),
            Expanded(
              child: _buildTabContent(theme),
            ),
            _buildKeyboard(),
            _buildBottomNav(theme),
          ],
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
        onTap: () => _qwertyFocusNode.requestFocus(),
        child: content,
      ),
    );
  }

  // ============================================
  // TOP BAR
  // ============================================
  Widget _buildTopBar(theme_service.ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: theme.cardGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('????', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GrandPiano',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  Text(
                    _isMidiConnected
                        ? 'Connected: $_midiDeviceName'
                        : 'Not Connected',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showConnectionPanelModal(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isMidiConnected
                        ? CupertinoColors.systemGreen.withOpacity(0.2)
                        : CupertinoColors.systemOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isMidiConnected
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemOrange,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _isMidiConnected
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.bluetooth,
                    color: _isMidiConnected
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemOrange,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showKeyboardSettingsModal(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CupertinoIcons.settings,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _audioStatus,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    color: theme.primaryColor.withOpacity(0.15),
                    onPressed: _enableAudio,
                    child: Text(
                      _audioReady ? 'Test Audio' : 'Enable Audio',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_keyboardSettings.performanceMode)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ValueListenableBuilder<Map<String, dynamic>>(
                valueListenable: _perfStats,
                builder: (context, stats, child) {
                  if (stats.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    "MIDI Q:${stats['queue']}  Drop:${stats['dropped']}  Voices:${stats['voices']}  Poly:${stats['poly']}",
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textColor.withOpacity(0.7),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ============================================
  // TAB CONTENT
  // ============================================
  Widget _buildTabContent(theme_service.ThemeData theme) {
    switch (_selectedTab) {
      case 0:
        return _buildHomeTab(theme);
      case 1:
        return _buildLessonsTab(theme);
      case 2:
        return _buildAITab(theme);
      case 3:
        return _buildStatsTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab(theme);
    }
  }

  Widget _buildHomeTab(theme_service.ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withOpacity(0.2),
                theme.secondaryColor.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<NoteState>(
                valueListenable: _noteState.notifier,
                builder: (context, state, child) {
                  return Text(
                    'Ready to practice? ${state.activeCount} notes playing',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textColor.withOpacity(0.7),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildQuickActionCard(
                'Learn Songs',
                CupertinoIcons.music_note_list,
                theme.primaryColor,
                () => setState(() => _selectedTab = 1),
                theme),
            _buildQuickActionCard(
                'AI Tutor',
                CupertinoIcons.chat_bubble_text_fill,
                CupertinoColors.systemPurple,
                () => setState(() => _selectedTab = 2),
                theme),
            _buildQuickActionCard(
                'My Stats',
                CupertinoIcons.chart_bar_fill,
                CupertinoColors.systemGreen,
                () => setState(() => _selectedTab = 3),
                theme),
            _buildQuickActionCard(
                'Profile',
                CupertinoIcons.person_fill,
                CupertinoColors.systemIndigo,
                () => setState(() => _selectedTab = 4),
                theme),
          ],
        ),
        const SizedBox(height: 20),
        _buildStatusCard(theme),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color,
      VoidCallback onTap, theme_service.ThemeData theme) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(theme_service.ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: theme.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
              'MIDI',
              _isMidiConnected ? 'Connected' : 'Disconnected',
              _isMidiConnected,
              theme),
          _buildStatusRow('AI Tutor', widget.aiEnabled ? 'Ready' : 'Offline',
              widget.aiEnabled, theme),
          _buildStatusRow(
              'Cloud Sync',
              widget.cloudEnabled ? 'Active' : 'Offline',
              widget.cloudEnabled,
              theme),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isActive,
      theme_service.ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
                color: theme.textColor.withOpacity(0.7), fontSize: 14),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemGrey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsTab(theme_service.ThemeData theme) {
    // FIXED: Create categories manually since getSongsByCategory() doesn't exist
    final allSongs = SongsLibrary.getSongs();
    final Map<String, List<CompleteSong>> categories = {
      'Beginner':
          allSongs.where((song) => song.difficulty == 'Beginner').toList(),
      'Intermediate':
          allSongs.where((song) => song.difficulty == 'Intermediate').toList(),
      'Advanced':
          allSongs.where((song) => song.difficulty == 'Advanced').toList(),
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Learn Piano Songs',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 20),
        if (categories['Beginner']?.isNotEmpty ?? false) ...[
          _buildSongCategory('Beginner', categories['Beginner']!, theme),
          const SizedBox(height: 20),
        ],
        if (categories['Intermediate']?.isNotEmpty ?? false) ...[
          _buildSongCategory(
              'Intermediate', categories['Intermediate']!, theme),
          const SizedBox(height: 20),
        ],
        if (categories['Advanced']?.isNotEmpty ?? false) ...[
          _buildSongCategory('Advanced', categories['Advanced']!, theme),
        ],
      ],
    );
  }

  Widget _buildSongCategory(String category, List<CompleteSong> songs,
      theme_service.ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 12),
        ...songs.map((song) => _buildSongCard(song, theme)),
      ],
    );
  }

  Widget _buildSongCard(CompleteSong song, theme_service.ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => CompleteSongLessonScreen(song: song),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: theme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withOpacity(0.3),
                      theme.secondaryColor.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.music_note_2,
                  color: theme.primaryColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.composer,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.star_fill,
                            size: 12, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          song.difficulty,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.play_circle_fill,
                  color: theme.primaryColor, size: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAITab(theme_service.ThemeData theme) {
    if (!widget.aiEnabled || _aiTutor == null) {
      return _buildFeatureDisabled('AI Tutor', theme);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CupertinoColors.systemPurple,
                CupertinoColors.systemIndigo
              ],
            ),
          ),
          child: const Row(
            children: [
              Icon(CupertinoIcons.sparkles, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'AI Piano Tutor',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: AIChatWidget(aiTutor: _aiTutor!),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    return const AnalyticsScreen();
  }

  Widget _buildProfileTab() {
    return const ProfileScreen();
  }

  Widget _buildFeatureDisabled(
      String featureName, theme_service.ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 64,
            color: theme.textColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '$featureName Offline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This feature requires configuration',
            style: TextStyle(color: theme.textColor.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    return ValueListenableBuilder<NoteState>(
      valueListenable: _noteState.notifier,
      builder: (context, state, child) {
        return EnhancedPianoKeyboard(
          activeNotes: state.activeNotes,
          noteVelocities: state.velocities,
          onKeyPressed: _handleTouchNote,
          onKeyReleased: _handleTouchRelease,
          settings: _keyboardSettings,
        );
      },
    );
  }

  Widget _buildBottomNav(theme_service.ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, CupertinoIcons.house_fill, 'Home', theme),
            _buildNavItem(1, CupertinoIcons.book_fill, 'Lessons', theme),
            _buildNavItem(
                2, CupertinoIcons.chat_bubble_text_fill, 'AI Tutor', theme),
            _buildNavItem(3, CupertinoIcons.chart_bar_fill, 'Stats', theme),
            _buildNavItem(4, CupertinoIcons.person_fill, 'Profile', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, String label, theme_service.ThemeData theme) {
    final isSelected = _selectedTab == index;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 12),
      onPressed: () => setState(() => _selectedTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? theme.primaryColor
                : theme.textColor.withOpacity(0.4),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.primaryColor
                  : theme.textColor.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Proper modal methods
  void _showConnectionPanelModal() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => ConnectionStatusPanel(
        midiService: _midiService,
        isConnected: _isMidiConnected,
        deviceName: _midiDeviceName,
        deviceType: _midiDeviceType,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _showKeyboardSettingsModal() {
    Navigator.of(context).push(
      CupertinoPageRoute(
          builder: (context) => KeyboardSettingsPanel(
            settings: _keyboardSettings,
            lastMidiVelocity: _lastMidiVelocity,
            masterVolume: _masterVolume,
            onVolumeChanged: (value) {
              setState(() => _masterVolume = value);
              _audioService.setMasterVolume(value);
              AppSettingsStore.setVolume(value);
            },
            ultraMode: _ultraMode,
            onUltraModeChanged: (value) {
              setState(() => _ultraMode = value);
              if (value != 'off' && !_keyboardSettings.performanceMode) {
                setState(() {
                  _keyboardSettings = _keyboardSettings..performanceMode = true;
                });
              }
              _audioService.setUltraMode(ultraModeFromString(value));
              AppSettingsStore.setUltraPerformanceMode(value);
            },
            qwertyEnabled: _qwertyEnabled,
            onQwertyChanged: (value) {
              setState(() => _qwertyEnabled = value);
              _qwertyController.enabled = value;
              AppSettingsStore.setQwertyEnabled(value);
            },
            onSettingsChanged: (newSettings) {
              setState(() => _keyboardSettings = newSettings);
              _audioService.setPerformanceMode(newSettings.performanceMode);
              _audioService.setVelocityCurve(newSettings.velocityCurvePreset,
                  newSettings.velocityCurveExponent);
              _saveKeyboardSettings();
            },
          ),
        ),
      );
  }

  @override
  void dispose() {
    _midiService.dispose();
    _audioService.dispose();
    _noteState.dispose();
    _lastMidiVelocity.dispose();
    _perfTimer?.cancel();
    _perfStats.dispose();
    _qwertyFocusNode.dispose();
    if (_currentSessionId != null && widget.cloudEnabled) {
      _cloudService.endSession(_currentSessionId!);
    }
    super.dispose();
  }

  KeyEventResult _handleQwertyEvent(KeyEvent event) {
    return _qwertyController.handleEvent(
      event,
      onNoteOn: (note, velocity) {
        _noteState.noteOn(note, velocity);
        _audioService.playNote(note, velocity);
        _aiTutor?.trackNotePlay(note, velocity);
      },
      onNoteOff: (note) {
        _noteState.noteOff(note);
        _audioService.stopNote(note);
      },
    );
  }
}
