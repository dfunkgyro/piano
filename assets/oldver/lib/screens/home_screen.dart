// ============================================
// FIXED home_screen.dart - ALL ERRORS RESOLVED
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    hide ThemeData; // FIXED: Hide Material ThemeData
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../services/audio_player_service.dart';
import '../services/midi_service.dart';
import '../services/aws_service.dart';
import '../services/enhanced_ai_tutor_service.dart';
import '../utils/theme_service.dart' as theme_service; // FIXED: Use alias
import '../models/complete_songs_library.dart'; // FIXED: Correct import
import '../widgets/enhanced_piano_keyboard.dart';
import '../widgets/keyboard_settings_panel.dart';
import '../widgets/connection_status_panel.dart';
import '../widgets/ai_chat_widget.dart';
import '../utils/note_state_controller.dart';
import '../utils/velocity_curve.dart';
import '../utils/app_info.dart';
import 'lesson_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';

class CompleteHomeScreen extends StatefulWidget {
  final bool cloudEnabled;
  final bool signedIn;
  final bool guestMode;
  final bool aiEnabled;
  final Function() onThemeChanged;
  final VoidCallback onSignedOut;
  final VoidCallback onExitGuest;

  const CompleteHomeScreen({
    super.key,
    required this.cloudEnabled,
    required this.signedIn,
    required this.guestMode,
    required this.aiEnabled,
    required this.onThemeChanged,
    required this.onSignedOut,
    required this.onExitGuest,
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

  late final AnimationController _introController;
  late final Animation<Offset> _introSlide;
  late final Animation<double> _introFade;
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _introSlide = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    ));
    _introFade = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
    _initialize();
    _introController.forward();
  }

  Future<void> _initialize() async {
    final settings = await _loadKeyboardSettings();
    _audioService.setPerformanceMode(settings.performanceMode);
    await _audioService.initialize();
    await _setupMidiService(); // FIXED: Setup MIDI callbacks properly
    await _midiService.ensurePermissionsAndServices();

    // Defer cloud session start to avoid delaying first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_cloudActive && _cloudService.isInitialized) {
        _currentSessionId = await _cloudService.startSession();
      }
    });

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
      keyWidthScale: prefs.getDouble('keyboard_width_scale') ?? 1.0,
      blackKeyWidthFactor: prefs.getDouble('black_key_width_factor') ?? 0.6,
      blackKeyHeightFactor: prefs.getDouble('black_key_height_factor') ?? 0.6,
      velocityCurvePreset: velocityCurvePresetFromString(
          prefs.getString('velocity_curve_preset')),
      velocityCurveExponent:
          prefs.getDouble('velocity_curve_exponent') ?? 1.0,
    );
    settings.performanceMode = true;
    setState(() {
      _keyboardSettings = settings;
    });
    _audioService.setVelocityCurve(
        settings.velocityCurvePreset, settings.velocityCurveExponent);
    return settings;
  }

  Future<void> _saveKeyboardSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _keyboardSettings.performanceMode = true;
    await prefs.setDouble('keyboard_height', _keyboardSettings.height);
    await prefs.setBool('show_note_names', _keyboardSettings.showNoteNames);
    await prefs.setBool('performance_mode', _keyboardSettings.performanceMode);
    await prefs.setBool('pedal_installed', _keyboardSettings.pedalInstalled);
    await prefs.setDouble(
        'keyboard_width_scale', _keyboardSettings.keyWidthScale);
    await prefs.setDouble(
        'black_key_width_factor', _keyboardSettings.blackKeyWidthFactor);
    await prefs.setDouble(
        'black_key_height_factor', _keyboardSettings.blackKeyHeightFactor);
    await prefs.setString('velocity_curve_preset',
        velocityCurvePresetToString(_keyboardSettings.velocityCurvePreset));
    await prefs.setDouble(
        'velocity_curve_exponent', _keyboardSettings.velocityCurveExponent);
  }

  void _handleTouchNote(int note) {
    _noteState.noteOn(note, 0.8);
    _audioService.playNote(note, 0.8);
    _aiTutor?.trackNotePlay(note, 0.8);
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
        content: SelectableText(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('Copy'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              Navigator.pop(context);
            },
          ),
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

  bool get _cloudActive => widget.cloudEnabled && (widget.signedIn || widget.guestMode);

  @override
  Widget build(BuildContext context) {
    final theme = theme_service.ThemeService.theme; // FIXED: Use alias

    return CupertinoPageScaffold(
      backgroundColor: theme.backgroundColor,
      child: Stack(
        children: [
          _buildBackground(theme),
          Positioned(
            right: 12,
            bottom: 8,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.65,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.surfaceColor.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: theme.textColor.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    'Build ${AppInfo.buildStamp}',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.textColor.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1100;
                final showSegmented = constraints.maxWidth >= 820;
                final isPhone = constraints.maxWidth < 600;
                final isNarrow = constraints.maxWidth < 420;
                final isShort = constraints.maxHeight < 700;
                final keyboardHeight = (constraints.maxHeight *
                        (isShort ? 0.23 : (isPhone ? 0.26 : 0.28)))
                    .clamp(140.0, 230.0);

                return Column(
                  children: [
                    _buildTopBar(
                      theme,
                      showSegmented: showSegmented,
                      isCompact: isPhone,
                      isNarrow: isNarrow,
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          if (isWide) _buildSideNav(theme),
                          Expanded(
                            child: FadeTransition(
                              opacity: _introFade,
                              child: SlideTransition(
                                position: _introSlide,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: _buildTabContent(
                                    theme,
                                    isNarrow: isNarrow,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (isWide)
                            SizedBox(
                              width: 320,
                              child: _buildRightPanel(theme),
                            ),
                        ],
                      ),
                    ),
                    _buildKeyboardPanel(
                      theme,
                      keyboardHeight: keyboardHeight,
                      isPhone: isPhone,
                    ),
                    if (!showSegmented) _buildBottomNav(theme),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // TOP BAR
  // ============================================
  Widget _buildBackground(theme_service.ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: theme.backgroundGradient,
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final color = isActive ? activeColor : inactiveColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTopBar(
    theme_service.ThemeData theme, {
    required bool showSegmented,
    required bool isCompact,
    required bool isNarrow,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        isCompact ? 8 : 12,
        16,
        isCompact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        gradient: theme.cardGradient,
        border: Border(
          bottom: BorderSide(
            color: theme.textColor.withOpacity(0.08),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isCompact ? 36 : 44,
                    height: isCompact ? 36 : 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor.withOpacity(0.8),
                          theme.secondaryColor.withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.music_note_2,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GrandPiano Studio',
                        style: TextStyle(
                          fontSize: isCompact ? 16 : 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      Text(
                        _isMidiConnected
                            ? 'Connected: $_midiDeviceName'
                            : 'Not connected',
                        style: TextStyle(
                          fontSize: isCompact ? 10 : 11,
                          color: theme.textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isNarrow)
                    _buildStatusChip(
                      label: _isMidiConnected ? 'MIDI Live' : 'No MIDI',
                      isActive: _isMidiConnected,
                      activeColor: CupertinoColors.systemGreen,
                      inactiveColor: CupertinoColors.systemOrange,
                    ),
                  if (!isNarrow) const SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showConnectionPanelModal(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.surfaceColor.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.textColor.withOpacity(0.08),
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.waveform,
                        color: theme.primaryColor,
                        size: 20,
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
                        color: theme.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        CupertinoIcons.slider_horizontal_3,
                        color: theme.primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (showSegmented) ...[
            const SizedBox(height: 12),
            _buildSegmentedNav(theme),
          ],
          if (_keyboardSettings.performanceMode)
            Padding(
              padding: const EdgeInsets.only(top: 10),
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

  Widget _buildSegmentedNav(theme_service.ThemeData theme) {
    return CupertinoSlidingSegmentedControl<int>(
      groupValue: _selectedTab,
      thumbColor: theme.primaryColor.withOpacity(0.18),
      backgroundColor: theme.surfaceColor.withOpacity(0.5),
      children: const {
        0: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('Home'),
        ),
        1: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('Lessons'),
        ),
        2: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('AI Tutor'),
        ),
        3: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('Stats'),
        ),
        4: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('Profile'),
        ),
      },
      onValueChanged: (value) {
        if (value == null) return;
        setState(() => _selectedTab = value);
      },
    );
  }

  Widget _buildSideNav(theme_service.ThemeData theme) {
    return Container(
      width: 200,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: theme.surfaceColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.textColor.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _buildRailItem(0, CupertinoIcons.house_fill, 'Home', theme),
          _buildRailItem(1, CupertinoIcons.book_fill, 'Lessons', theme),
          _buildRailItem(2, CupertinoIcons.chat_bubble_text_fill, 'AI Tutor', theme),
          _buildRailItem(3, CupertinoIcons.chart_bar_fill, 'Stats', theme),
          _buildRailItem(4, CupertinoIcons.person_fill, 'Profile', theme),
        ],
      ),
    );
  }

  Widget _buildRailItem(
      int index, IconData icon, String label, theme_service.ThemeData theme) {
    final isSelected = _selectedTab == index;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      onPressed: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.primaryColor
                  : theme.textColor.withOpacity(0.6),
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.primaryColor
                    : theme.textColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightPanel(theme_service.ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
      child: Column(
        children: [
          _buildQuickControls(theme),
          const SizedBox(height: 16),
          Expanded(
            child: ConnectionStatusPanel(
              midiService: _midiService,
              isConnected: _isMidiConnected,
              deviceName: _midiDeviceName,
              deviceType: _midiDeviceType,
              onClose: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickControls(theme_service.ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.textColor.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keyboard Studio',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Height',
            style: TextStyle(
              fontSize: 12,
              color: theme.textColor.withOpacity(0.6),
            ),
          ),
          CupertinoSlider(
            value: _keyboardSettings.height,
            min: 140,
            max: 360,
            onChanged: (value) {
              setState(() => _keyboardSettings.height = value);
              _saveKeyboardSettings();
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Key Width',
            style: TextStyle(
              fontSize: 12,
              color: theme.textColor.withOpacity(0.6),
            ),
          ),
          CupertinoSlider(
            value: _keyboardSettings.keyWidthScale,
            min: 0.8,
            max: 1.6,
            onChanged: (value) {
              setState(() => _keyboardSettings.keyWidthScale = value);
              _saveKeyboardSettings();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: theme.primaryColor.withOpacity(0.15),
                  onPressed: () => _showKeyboardSettingsModal(),
                  child: const Text(
                    'More Settings',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardPanel(
    theme_service.ThemeData theme, {
    required double keyboardHeight,
    required bool isPhone,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: _buildKeyboard(
        keyboardHeight: keyboardHeight,
        isPhone: isPhone,
      ),
    );
  }

  // ============================================
  // TAB CONTENT
  // ============================================
  Widget _buildTabContent(theme_service.ThemeData theme,
      {required bool isNarrow}) {
    switch (_selectedTab) {
      case 0:
        return Container(
          key: const ValueKey('home'),
          child: _buildHomeTab(theme, isNarrow: isNarrow),
        );
      case 1:
        return Container(
          key: const ValueKey('lessons'),
          child: AppInfo.lessonsEnabled
              ? _buildLessonsTab(theme)
              : _buildLessonsDisabled(theme),
        );
      case 2:
        return Container(
          key: const ValueKey('ai'),
          child: _buildAITab(theme),
        );
      case 3:
        return Container(
          key: const ValueKey('stats'),
          child: _buildStatsTab(),
        );
      case 4:
        return Container(
          key: const ValueKey('profile'),
          child: _buildProfileTab(),
        );
      default:
        return Container(
          key: const ValueKey('home'),
          child: _buildHomeTab(theme, isNarrow: isNarrow),
        );
    }
  }

  Widget _buildHomeTab(theme_service.ThemeData theme,
      {required bool isNarrow}) {
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
          crossAxisCount: isNarrow ? 1 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isNarrow ? 2.4 : 1.5,
          children: [
            _buildQuickActionCard(
                'Learn Songs',
                CupertinoIcons.music_note_list,
                theme.primaryColor,
                () => setState(() => _selectedTab = 1),
                theme,
                isNarrow: isNarrow),
            _buildQuickActionCard(
                'AI Tutor',
                CupertinoIcons.chat_bubble_text_fill,
                CupertinoColors.systemPurple,
                () => setState(() => _selectedTab = 2),
                theme,
                isNarrow: isNarrow),
            _buildQuickActionCard(
                'My Stats',
                CupertinoIcons.chart_bar_fill,
                CupertinoColors.systemGreen,
                () => setState(() => _selectedTab = 3),
                theme,
                isNarrow: isNarrow),
            _buildQuickActionCard(
                'Profile',
                CupertinoIcons.person_fill,
                CupertinoColors.systemIndigo,
                () => setState(() => _selectedTab = 4),
                theme,
                isNarrow: isNarrow),
          ],
        ),
        const SizedBox(height: 20),
        _buildStatusCard(theme),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    theme_service.ThemeData theme, {
    required bool isNarrow,
  }) {
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
            Icon(icon, size: isNarrow ? 34 : 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isNarrow ? 13 : 14,
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
              _cloudActive ? (widget.guestMode ? 'Guest' : 'Active') : 'Offline',
              _cloudActive,
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
              builder: (context) => ImprovedLessonScreen(song: song),
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
      if (widget.aiEnabled) {
        _aiTutor = EnhancedAITutorService();
      } else {
        return _buildFeatureDisabled('AI Tutor', theme);
      }
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
    return ProfileScreen(
      onSignedOut: widget.onSignedOut,
      guestMode: widget.guestMode,
      onExitGuest: widget.onExitGuest,
    );
  }

  Widget _buildLessonsDisabled(theme_service.ThemeData theme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: theme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.textColor.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              color: theme.textColor.withOpacity(0.7),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Lessons temporarily disabled',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'We are isolating a startup issue. Other features remain available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildKeyboard({
    required double keyboardHeight,
    required bool isPhone,
  }) {
    return ValueListenableBuilder<NoteState>(
      valueListenable: _noteState.notifier,
      builder: (context, state, child) {
        final adjusted = KeyboardSettings(
          height: keyboardHeight,
          theme: _keyboardSettings.theme,
          animation: _keyboardSettings.animation,
          showNoteNames: _keyboardSettings.showNoteNames,
          showOctaveNumbers: _keyboardSettings.showOctaveNumbers,
          enableVelocityColors: _keyboardSettings.enableVelocityColors,
          enableShadows: _keyboardSettings.enableShadows,
          keySpacing: _keyboardSettings.keySpacing,
          cornerRadius: _keyboardSettings.cornerRadius,
          keyWidthScale: isPhone ? 1.25 : _keyboardSettings.keyWidthScale,
          blackKeyWidthFactor: _keyboardSettings.blackKeyWidthFactor,
          blackKeyHeightFactor: _keyboardSettings.blackKeyHeightFactor,
          performanceMode: _keyboardSettings.performanceMode,
          pedalInstalled: _keyboardSettings.pedalInstalled,
          velocityCurvePreset: _keyboardSettings.velocityCurvePreset,
          velocityCurveExponent: _keyboardSettings.velocityCurveExponent,
        );
        return EnhancedPianoKeyboard(
          activeNotes: state.activeNotes,
          noteVelocities: state.velocities,
          onKeyPressed: _handleTouchNote,
          onKeyReleased: _handleTouchRelease,
          settings: adjusted,
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
          onSettingsChanged: (newSettings) {
            newSettings.performanceMode = true;
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
    _introController.dispose();
    _bgController.dispose();
    if (_currentSessionId != null && widget.cloudEnabled) {
      final summary = _aiTutor?.getSessionStats();
      _cloudService.endSession(_currentSessionId!, summary: summary);
      if (summary != null) {
        // Fire-and-forget insights generation.
        _cloudService.generateSessionInsights(_currentSessionId!,
            summary: summary);
      }
    }
    super.dispose();
  }
}
