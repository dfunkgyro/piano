// ==============================================================================
// IMPROVED lesson_screen.dart - WITH TEMPO CONTROL & VISIBLE KEYBOARD
// ==============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/complete_songs_library.dart';
import '../services/enhanced_ai_tutor_service.dart';
import '../services/audio_player_service.dart';
import '../services/aws_service.dart';
import '../utils/theme_service.dart' as theme_service;
import '../widgets/enhanced_piano_keyboard.dart';
import '../widgets/ai_chat_widget.dart';
import '../utils/note_state_controller.dart';
import '../utils/velocity_curve.dart';
import '../widgets/falling_notes_widget.dart';
import '../services/midi_service.dart';
import '../utils/practice_engine.dart';

class ImprovedLessonScreen extends StatefulWidget {
  final CompleteSong song;

  const ImprovedLessonScreen({
    super.key,
    required this.song,
  });

  @override
  State<ImprovedLessonScreen> createState() => _ImprovedLessonScreenState();
}

class _ImprovedLessonScreenState extends State<ImprovedLessonScreen>
    with TickerProviderStateMixin {
  final EnhancedAITutorService _aiTutor = EnhancedAITutorService();
  final AudioPlayerService _audioService = AudioPlayerService();
  final AwsService _cloudService = AwsService.instance;
  final MidiService _midiService = MidiService();

  // Practice state
  final NoteStateController _noteState = NoteStateController();
  final Set<int> _wrongNotes = {}; // NEW: Track wrong notes for RED feedback
  final Set<int> _expectedNotes = {}; // NEW: Track what notes should be playing
  final List<Map<String, dynamic>> _sectionNotes = [];
  PracticeEngine? _practiceEngine;
  DateTime? _practiceStartTime;
  String _timingFeedback = '';
  Color _timingColor = CupertinoColors.systemGrey;
  double _sectionProgress = 0.0;
  String _sectionStatus = '';
  bool _autoTempo = true;

  bool _isPlaying = false;
  bool _isPracticing = false;
  int _currentNoteIndex = 0;
  int _correctNotes = 0;
  int _mistakes = 0;
  int _streak = 0;
  int _bestStreak = 0;
  double _scoreMultiplier = 1.0;
  String _rankLabel = 'Bronze';
  Color _rankColor = const Color(0xFFCD7F32);
  bool _strictMode = true;
  bool _autoPauseOnMiss = false;
  bool _autoSlowOnMiss = true;
  int _songMinNote = 21;
  int _songMaxNote = 108;
  String _pauseReason = '';
  final Map<int, int> _missCounts = {};
  final Map<int, double> _missHeatmap = {};
  final Set<int> _guideNotes = {};
  final Map<int, String> _guideHands = {};
  bool _showLoopPrompt = false;
  bool _autoRestart = true;
  DateTime? _loopStartTime;
  int _loopCount = 0;
  bool _focusRange = true;
  int _sectionFailCount = 0;
  int _lastSectionStartIndex = 0;
  bool _compactHud = true;
  double _keyboardZoom = 1.0;
  double _keyboardZoomStart = 1.0;
  int _keyboardRangeStart = 21;
  int _keyboardRangeEnd = 108;
  int _loopId = 0;
  bool _metronomeOn = false;
  Timer? _metronomeTimer;
  int _metronomeMidi = 60;
  bool _isPreviewing = false;
  Timer? _previewTimer;
  bool _showAI = false;
  String? _sessionId;
  double _progress = 0.0;

  // NEW: Tempo control
  double _tempoMultiplier =
      0.35; // 1.0 = normal speed, 0.5 = half speed, 2.0 = double
  Timer? _playbackTimer;
  DateTime? _songStartTime;
  bool _showCelebration = false;
  String _celebrationMessage = '';
  late final AnimationController _confettiController;
  final List<_ConfettiParticle> _confettiParticles = [];

  // Keyboard settings
  KeyboardSettings _keyboardSettings = KeyboardSettings(
    height: 180,
    showNoteNames: true,
  );

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _buildConfetti();
    _metronomeMidi = _resolveMetronomeNote();
    _computeSongRange();
    _updateKeyboardRange();
    _initializeLesson();
  }

  Future<void> _initializeLesson() async {
    final settings = await _loadKeyboardSettings();
    _audioService.setPerformanceMode(settings.performanceMode);
    await _audioService.initialize();
    await _setupMidiService();
    if (_cloudService.isInitialized) {
      _sessionId = await _cloudService.startSession();
      final savedProgress =
          await _cloudService.getSongProgress(widget.song.id);
      setState(() => _progress = savedProgress);
    }
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
    setState(() => _keyboardSettings = settings);
    _audioService.setVelocityCurve(
        settings.velocityCurvePreset, settings.velocityCurveExponent);
    return settings;
  }

  Future<void> _setupMidiService() async {
    _midiService.onMidiDataReceived = (data) {
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
          _handleNotePlay(note, velocity: velocity / 127.0);
        } else if (messageType == 0x80 ||
            (messageType == 0x90 && velocity == 0)) {
          _handleNoteRelease(note);
        }
      }
    };
  }

  // NEW: Start practice with falling notes
  void _startPracticeWithFallingNotes({bool fromLoop = false}) {
    if (widget.song.notes.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('No Notes Found'),
          content: const Text('This song does not contain any notes.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }
    setState(() {
      _isPracticing = true;
      _isPlaying = true;
      _currentNoteIndex = 0;
      _correctNotes = 0;
      _mistakes = 0;
      _streak = 0;
      _bestStreak = 0;
      _scoreMultiplier = 1.0;
      _rankLabel = 'Bronze';
      _rankColor = const Color(0xFFCD7F32);
      _wrongNotes.clear();
      _expectedNotes.clear();
      _missCounts.clear();
      _missHeatmap.clear();
      _guideNotes.clear();
      _guideHands.clear();
      _songStartTime = DateTime.now();
      _timingFeedback = '';
      _sectionStatus = '';
      _pauseReason = '';
      _showLoopPrompt = false;
      if (!fromLoop) {
        _loopCount = 0;
        _loopStartTime = DateTime.now();
      } else {
        _loopStartTime ??= DateTime.now();
      }
      _compactHud = true;
      _loopId++;
    });
    if (_metronomeOn) {
      _startMetronome();
    }

    _noteState.clear();
    _practiceStartTime = DateTime.now();
    _practiceEngine = PracticeEngine(
      notes: widget.song.notes,
      sectionSize: math.max(1, widget.song.notes.length),
      timingWindowMs: 260,
      graceWindowMs: 520,
    );
    _startSection();
  }

  void _startSection() {
    _playbackTimer?.cancel();
    final engine = _practiceEngine;
    if (engine == null || _practiceStartTime == null) return;

    if (_lastSectionStartIndex != engine.sectionStartIndex) {
      _sectionFailCount = 0;
      _lastSectionStartIndex = engine.sectionStartIndex;
    }

    engine.startSection(
      elapsedMs: _elapsedMs(),
      tempoMultiplier: _tempoMultiplier,
    );
    setState(() {
      _sectionProgress = 0.0;
      _guideNotes.clear();
      _guideHands.clear();
    });

    _buildSectionNotes();
    _refreshExpectedNote();
    _scheduleExpectedNotes();
  }

  void _scheduleExpectedNotes() {
    _playbackTimer?.cancel();
    final engine = _practiceEngine;
    if (engine == null) return;

    int localIndex = engine.sectionStartIndex;
    final sectionEnd = engine.sectionEndIndex;
    if (localIndex >= sectionEnd) return;

    double previousTime = widget.song.notes[localIndex].time;

    void scheduleNext() {
      if (!_isPlaying || localIndex >= sectionEnd) return;

      final note = widget.song.notes[localIndex];
      final deltaTimeMs =
          ((note.time - previousTime) * 1000 / _tempoMultiplier).round();

      _playbackTimer = Timer(Duration(milliseconds: deltaTimeMs), () {
        if (_isPlaying) {
          setState(() {
            _expectedNotes.add(note.note);
            _currentNoteIndex = localIndex;
            _updateGuideNotes(note.note, note.hand);
          });

          Future.delayed(
              Duration(
                  milliseconds:
                      (note.duration * 1000 / _tempoMultiplier).round()), () {
            setState(() {
              _expectedNotes.remove(note.note);
              _clearGuideNote(note.note);
            });
          });

          previousTime = note.time;
          localIndex++;
          scheduleNext();
        }
      });
    }

    scheduleNext();
  }

  void _stopPractice() {
    setState(() {
      _isPracticing = false;
      _isPlaying = false;
      _expectedNotes.clear();
      _wrongNotes.clear();
      _streak = 0;
      _scoreMultiplier = 1.0;
      _pauseReason = '';
      _showLoopPrompt = false;
    });
    _stopMetronome();
    _playbackTimer?.cancel();
    _audioService.stopAllNotes();
    _noteState.clear();
    _sectionNotes.clear();
    _practiceEngine = null;
  }

  double _elapsedMs() {
    if (_practiceStartTime == null) return 0.0;
    return DateTime.now().difference(_practiceStartTime!).inMilliseconds
        .toDouble();
  }

  void _buildSectionNotes() {
    final engine = _practiceEngine;
    if (engine == null) return;

    final start = engine.sectionStartIndex;
    final end = engine.sectionEndIndex;
    if (start >= end) return;

    final baseTime = widget.song.notes[start].time;
    setState(() {
      _sectionNotes.clear();
      for (int i = start; i < end; i++) {
        final note = widget.song.notes[i];
        _sectionNotes.add({
          'note': note.note,
          'time': (note.time - baseTime) / _tempoMultiplier,
          'duration': note.duration / _tempoMultiplier,
          'hand': note.hand,
        });
      }
    });
  }

  void _refreshExpectedNote() {
    final expected = _practiceEngine?.expectedNote;
    setState(() {
      _expectedNotes.clear();
      if (expected != null) {
        _expectedNotes.add(expected);
      }
    });
  }

  void _handleSectionResult(SectionResult result) {
    setState(() {
      _sectionStatus = result.passed
          ? 'Section passed (${(result.accuracy * 100).toStringAsFixed(0)}%)'
          : 'Repeat section (${(result.accuracy * 100).toStringAsFixed(0)}%)';
    });

    if (result.passed && _autoTempo) {
      setState(() {
        _tempoMultiplier = (_tempoMultiplier + 0.1).clamp(0.5, 2.0);
      });
    }

    if (result.passed && (_practiceEngine?.sectionStartIndex ?? 0) >=
        widget.song.notes.length) {
      _completeSong();
    } else {
      if (!result.passed) {
        _sectionFailCount++;
        if (_autoSlowOnMiss && _sectionFailCount >= 2) {
          _decreaseTempoByBpm(5);
        }
        if (_sectionFailCount >= 3) {
          if (_focusHardestSpotInSection()) {
            _sectionFailCount = 0;
            _startSection();
            return;
          }
        }
      }
      _startSection();
    }
  }

  String _formatTiming(double deltaMs) {
    if (deltaMs.abs() < 1) return 'Perfect';
    final label = deltaMs < 0 ? 'Early' : 'Late';
    return '$label ${deltaMs.abs().toStringAsFixed(0)}ms';
  }

  Color _timingColorFor(double deltaMs) {
    final abs = deltaMs.abs();
    if (abs <= 30) return Colors.green;
    if (abs <= 80) return Colors.orange;
    return Colors.red;
  }

  // NEW: Handle note press with wrong note detection
  void _handleNotePlay(int note, {double velocity = 0.8}) {
    if (!_isPracticing) return;

    _noteState.noteOn(note, velocity);

    _audioService.playNote(note, velocity);

    final engine = _practiceEngine;
    if (engine != null && _practiceStartTime != null) {
      final result = engine.registerNote(
        note: note,
        elapsedMs: _elapsedMs(),
      );

      if (result != null) {
        setState(() {
          if (result.accepted) {
            _correctNotes++;
            _timingFeedback = _formatTiming(result.deltaMs);
            _timingColor = result.inWindow
                ? _timingColorFor(result.deltaMs)
                : Colors.orangeAccent;
            _wrongNotes.remove(note);
            _incrementStreak();
          } else {
              if (_strictMode) {
                _mistakes++;
                _wrongNotes.add(note);
                _resetStreak();
                _registerMiss(note);
                _timingFeedback = result.correctNote
                    ? _formatTiming(result.deltaMs)
                    : 'Wrong note';
              _timingColor = result.correctNote
                  ? _timingColorFor(result.deltaMs)
                  : Colors.red;
              Future.delayed(const Duration(seconds: 5), () {
                setState(() => _wrongNotes.remove(note));
              });
            } else {
              _timingFeedback = result.correctNote
                  ? _formatTiming(result.deltaMs)
                  : 'Free play';
              _timingColor = theme_service.ThemeService.theme.primaryColor;
            }
          }
          _sectionProgress = engine.sectionProgress;
        });
        _refreshExpectedNote();

        final sectionResult = engine.completeSectionIfNeeded();
        if (sectionResult != null) {
          _handleSectionResult(sectionResult);
        }
      }
    }

    _aiTutor.trackNotePlay(note, velocity);
  }

  void _handleNoteRelease(int note) {
    _noteState.noteOff(note);
    _audioService.stopNote(note);
  }

  void _startMetronome() {
    _metronomeTimer?.cancel();
    _metronomeMidi = _resolveMetronomeNote();
    final bpm = _currentBpm().clamp(30, 300);
    final intervalMs = (60000 / bpm).round();
    _metronomeTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) {
        if (!_metronomeOn) return;
        _audioService.playNote(_metronomeMidi, 0.35);
        Future.delayed(const Duration(milliseconds: 90), () {
          _audioService.stopNote(_metronomeMidi);
        });
      },
    );
  }

  int _resolveMetronomeNote() {
    final key = widget.song.key.trim();
    if (key.isEmpty) return 60;
    final tonic = key.split(' ').first;
    final semitone = _parseTonicToSemitone(tonic);
    if (semitone == null) return 60;
    final baseC4 = 60; // C4
    final midi = baseC4 + semitone;
    return midi.clamp(48, 84);
  }

  int? _parseTonicToSemitone(String tonic) {
    if (tonic.isEmpty) return null;
    final normalized =
        tonic.replaceAll('♭', 'b').replaceAll('♯', '#').trim();
    final letter = normalized[0].toUpperCase();
    final baseMap = <String, int>{
      'C': 0,
      'D': 2,
      'E': 4,
      'F': 5,
      'G': 7,
      'A': 9,
      'B': 11,
    };
    final base = baseMap[letter];
    if (base == null) return null;
    int offset = 0;
    if (normalized.length > 1) {
      final accidental = normalized[1];
      if (accidental == '#') offset = 1;
      if (accidental == 'b' || accidental == 'B') offset = -1;
    }
    final semitone = (base + offset) % 12;
    return semitone < 0 ? semitone + 12 : semitone;
  }

  void _stopMetronome() {
    _metronomeTimer?.cancel();
    _metronomeTimer = null;
  }

  void _toggleMetronome(bool value) {
    setState(() => _metronomeOn = value);
    if (value) {
      _startMetronome();
    } else {
      _stopMetronome();
    }
  }

  void _startPreview() {
    if (_isPreviewing) return;
    _previewTimer?.cancel();
    setState(() => _isPreviewing = true);
    int idx = 0;
    double previousTime = 0.0;

    void scheduleNext() {
      if (idx >= widget.song.notes.length) {
        setState(() => _isPreviewing = false);
        return;
      }
      final note = widget.song.notes[idx];
      final delta = ((note.time - previousTime) * 1000).round();
      _previewTimer = Timer(Duration(milliseconds: delta), () {
        if (!_isPreviewing) return;
        _audioService.playNote(note.note, 0.8);
        Future.delayed(
            Duration(milliseconds: (note.duration * 1000).round()), () {
          _audioService.stopNote(note.note);
        });
        previousTime = note.time;
        idx++;
        scheduleNext();
      });
    }

    scheduleNext();
  }

  void _stopPreview() {
    _previewTimer?.cancel();
    _previewTimer = null;
    setState(() => _isPreviewing = false);
    _audioService.stopAllNotes();
  }

  void _handleNoteMissed(int note) {
    if (!_isPracticing) return;
    if (!_strictMode) return;

    setState(() {
      _mistakes++;
      _timingFeedback = 'Missed';
      _timingColor = Colors.redAccent;
      _resetStreak();
    });
    _registerMiss(note);

    if (_autoSlowOnMiss) {
      _decreaseTempoByBpm(5);
    }
  }

  Future<void> _completeSong() async {
    final total = _correctNotes + _mistakes;
    final accuracy = total == 0 ? 0.0 : _correctNotes / total;
    final isPerfect = accuracy >= 0.999;

    if (_cloudService.isInitialized) {
      await _cloudService.saveSongProgress(widget.song.id, 1.0);
    }

    if (isPerfect) {
      _showLoopCelebration('Perfect run! +5 BPM');
      _playRewardSound();
      _fireConfetti();
      _increaseTempoByBpm(5);
    }

    _loopCount++;
    if (_autoRestart) {
      _stopPractice();
      Future.delayed(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        _startPracticeWithFallingNotes(fromLoop: true);
      });
      return;
    }
    setState(() {
      _isPlaying = false;
    });
  }

  double _currentBpm() {
    return widget.song.bpm * _tempoMultiplier;
  }

  void _increaseTempoByBpm(int bpmIncrease) {
    final nextBpm = _currentBpm() + bpmIncrease;
    final nextMultiplier =
        (nextBpm / widget.song.bpm).clamp(0.1, 3.0).toDouble();
    setState(() => _tempoMultiplier = nextMultiplier);
    _practiceEngine?.setTempo(_tempoMultiplier);
  }

  void _decreaseTempoByBpm(int bpmDecrease) {
    final nextBpm = (_currentBpm() - bpmDecrease).clamp(20, 999).toDouble();
    final nextMultiplier =
        (nextBpm / widget.song.bpm).clamp(0.1, 3.0).toDouble();
    setState(() => _tempoMultiplier = nextMultiplier);
    _practiceEngine?.setTempo(_tempoMultiplier);
  }

  void _showLoopCelebration(String message) {
    setState(() {
      _celebrationMessage = message;
      _showCelebration = true;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _showCelebration = false);
    });
  }

  void _buildConfetti() {
    _confettiParticles.clear();
    final rng = math.Random(42);
    final colors = [
      Colors.pinkAccent,
      Colors.amberAccent,
      Colors.lightBlueAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
    ];
    for (int i = 0; i < 120; i++) {
      _confettiParticles.add(_ConfettiParticle(
        x: rng.nextDouble(),
        size: 4 + rng.nextDouble() * 6,
        color: colors[rng.nextInt(colors.length)],
        speed: 0.6 + rng.nextDouble() * 0.8,
        drift: (rng.nextDouble() - 0.5) * 0.4,
      ));
    }
  }

  void _fireConfetti() {
    _confettiController.forward(from: 0);
  }

  void _incrementStreak() {
    _streak++;
    if (_streak > _bestStreak) {
      _bestStreak = _streak;
    }
    if (_streak == 10 || _streak == 20 || _streak == 40) {
      _showLoopCelebration('Streak $_streak!');
      _fireConfetti();
    }
    _updateMultiplierAndRank();
  }

  void _resetStreak() {
    _streak = 0;
    _updateMultiplierAndRank();
  }

  void _updateMultiplierAndRank() {
    double multiplier = 1.0;
    String rank = 'Bronze';
    Color rankColor = const Color(0xFFCD7F32);

    if (_streak >= 40) {
      multiplier = 3.0;
      rank = 'Platinum';
      rankColor = const Color(0xFFE5E4E2);
    } else if (_streak >= 25) {
      multiplier = 2.5;
      rank = 'Gold';
      rankColor = const Color(0xFFFFD700);
    } else if (_streak >= 15) {
      multiplier = 2.0;
      rank = 'Silver';
      rankColor = const Color(0xFFC0C0C0);
    } else if (_streak >= 8) {
      multiplier = 1.5;
      rank = 'Bronze+';
      rankColor = const Color(0xFFCD7F32);
    }

    _scoreMultiplier = multiplier;
    _rankLabel = rank;
    _rankColor = rankColor;
  }

  void _playRewardSound() {
    _audioService.playNote(72, 0.8); // C5
    _audioService.playNote(76, 0.8); // E5
    _audioService.playNote(79, 0.8); // G5
    Future.delayed(const Duration(milliseconds: 280), () {
      _audioService.stopNote(72);
      _audioService.stopNote(76);
      _audioService.stopNote(79);
    });
  }

  void _registerMiss(int note) {
    _missCounts[note] = (_missCounts[note] ?? 0) + 1;
    final maxMiss = _missCounts.values.fold<int>(1, (a, b) => math.max(a, b));
    _missHeatmap.clear();
    _missCounts.forEach((key, value) {
      _missHeatmap[key] = (value / maxMiss).clamp(0.0, 1.0);
    });
  }

  void _pausePractice(String reason) {
    setState(() {
      _pauseReason = reason;
      _isPlaying = false;
    });
  }

  void _resumePractice() {
    setState(() {
      _pauseReason = '';
      _isPlaying = true;
    });
    _startSection();
  }

  void _confirmLoopContinue(bool keepGoing) {
    setState(() {
      _showLoopPrompt = false;
    });
    if (keepGoing) {
      _loopStartTime = DateTime.now();
      _loopCount = 0;
      _startPracticeWithFallingNotes(fromLoop: true);
    } else {
      _stopPractice();
    }
  }

  void _computeSongRange() {
    if (widget.song.notes.isEmpty) return;
    int minNote = 108;
    int maxNote = 21;
    for (final note in widget.song.notes) {
      if (note.note < minNote) minNote = note.note;
      if (note.note > maxNote) maxNote = note.note;
    }
    final paddedMin = (minNote - 2).clamp(21, 108);
    final paddedMax = (maxNote + 2).clamp(21, 108);
      _songMinNote = paddedMin;
      _songMaxNote = paddedMax;
    _updateKeyboardRange();
  }

  void _updateKeyboardRange() {
    final baseRange = math
        .max(24, _songMaxNote - _songMinNote + 1)
        .clamp(24, 88);
    final center = ((_songMinNote + _songMaxNote) / 2).round();
    final effectiveRange =
        (baseRange / _keyboardZoom).clamp(14, 88).round();
    int start = center - (effectiveRange ~/ 2);
    int end = start + effectiveRange - 1;
    if (start < 21) {
      end += (21 - start);
      start = 21;
    }
    if (end > 108) {
      start -= (end - 108);
      end = 108;
      if (start < 21) start = 21;
    }
    _keyboardRangeStart = start;
    _keyboardRangeEnd = end;
  }

  bool _focusHardestSpotInSection() {
    final engine = _practiceEngine;
    if (engine == null) return false;
    final start = engine.sectionStartIndex;
    final end = engine.sectionEndIndex;
    if (start >= end) return false;
    int? targetIndex;
    int maxMiss = 0;
    for (int i = start; i < end; i++) {
      final note = widget.song.notes[i].note;
      final miss = _missCounts[note] ?? 0;
      if (miss > maxMiss) {
        maxMiss = miss;
        targetIndex = i;
      }
    }
    if (targetIndex == null || maxMiss == 0) return false;
    final targetTime = widget.song.notes[targetIndex].time;
    return engine.seekToTime(targetTime);
  }

  void _updateGuideNotes(int note, String hand) {
    _guideNotes.add(note);
    _guideHands[note] = hand;
  }

  void _clearGuideNote(int note) {
    _guideNotes.remove(note);
    _guideHands.remove(note);
  }

  void _rewindSeconds(double seconds) {
    final engine = _practiceEngine;
    if (engine == null) return;
    final elapsedMs = _elapsedMs();
    final songTime = engine.sectionBaseTime +
        ((elapsedMs - engine.sectionStartElapsedMs) / 1000.0) *
            engine.tempoMultiplier;
    final target = math.max(0.0, songTime - seconds);
    engine.seekToTime(target);
    _startSection();
  }

  @override
  Widget build(BuildContext context) {
    final theme = theme_service.ThemeService.theme;

    return CupertinoPageScaffold(
      backgroundColor: theme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.surfaceColor,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Icon(CupertinoIcons.back, color: theme.textColor),
        ),
        middle: Text(
          widget.song.title,
          style: TextStyle(color: theme.textColor),
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isPhone = constraints.maxWidth < 600;
            final isNarrow = constraints.maxWidth < 420;
            final isShort = constraints.maxHeight < 700;
            final targetKeyboardHeight = constraints.maxHeight *
                (isShort ? 0.24 : (isPhone ? 0.28 : 0.3));
            final keyboardHeight = math
                .min(
                  math.max(_keyboardSettings.height, targetKeyboardHeight),
                  isShort ? 200.0 : 260.0,
                )
                .clamp(150.0, 260.0);

            return Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      ValueListenableBuilder<NoteState>(
                        valueListenable: _noteState.notifier,
                        builder: (context, state, child) {
                          return FallingNotesWidget(
                            notes: _sectionNotes,
                            activeNotes: state.activeNotes,
                            onNoteHit: (_) {},
                            onNoteMissed: _handleNoteMissed,
                            speed: 0.5,
                            isPlaying: _isPlaying,
                          startMidiNote:
                              _focusRange ? _keyboardRangeStart : 21,
                          endMidiNote: _focusRange ? _keyboardRangeEnd : 108,
                          showGuide: _isPracticing,
                          hitLinePosition: isPhone ? 0.92 : 0.93,
                          backgroundAsset: 'assets/images/gyroc5.png',
                          backgroundOpacity: isNarrow ? 0.08 : 0.12,
                          blackKeyWidthFactor: 0.6,
                          keySpacing: 0.0,
                          loopId: _loopId,
                        );
                        },
                      ),
                      Positioned(
                        top: 6,
                        left: 8,
                        right: 8,
                        child: isNarrow
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLessonTopBar(
                                    theme,
                                    isNarrow: true,
                                    isShort: isShort,
                                  ),
                                  const SizedBox(height: 8),
                                  if (_isPracticing)
                                    _buildLessonStatsRow(theme),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: math.min(
                                        520, constraints.maxWidth - 16),
                                    child: _buildLessonTopBar(
                                      theme,
                                      isNarrow: false,
                                      isShort: isShort,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  if (_isPracticing)
                                    _buildLessonStatsRow(theme),
                                ],
                              ),
                      ),
                      if (_isPracticing)
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: _buildLessonTimingRow(theme),
                        ),
                      if (_showCelebration)
                        Center(
                          child: AnimatedOpacity(
                            opacity: _showCelebration ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 250),
                            child: AnimatedScale(
                              scale: _showCelebration ? 1.0 : 0.9,
                              duration: const Duration(milliseconds: 250),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.35),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _celebrationMessage,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_pauseReason.isNotEmpty)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.45),
                            child: Center(
                              child: _buildFloatingPanel(
                                theme: theme,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _pauseReason,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    CupertinoButton(
                                      color: theme.primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 8),
                                      onPressed: _resumePractice,
                                      child: const Text('Resume'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_showLoopPrompt)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.55),
                            child: Center(
                              child: _buildFloatingPanel(
                                theme: theme,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 18),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Keep looping?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'You have been practicing for a while.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.textColor.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CupertinoButton(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          color: theme.primaryColor,
                                          onPressed: () =>
                                              _confirmLoopContinue(true),
                                          child: const Text('Keep going'),
                                        ),
                                        const SizedBox(width: 10),
                                        CupertinoButton(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          color: CupertinoColors.systemGrey
                                              .withOpacity(0.4),
                                          onPressed: () =>
                                              _confirmLoopContinue(false),
                                          child: const Text('Stop'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _confettiController,
                            builder: (context, child) {
                              if (!_confettiController.isAnimating) {
                                return const SizedBox.shrink();
                              }
                              return CustomPaint(
                                painter: _ConfettiPainter(
                                  progress: _confettiController.value,
                                  particles: _confettiParticles,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: keyboardHeight,
                  child: GestureDetector(
                    onScaleStart: (_) => _keyboardZoomStart = _keyboardZoom,
                    onScaleUpdate: (details) {
                      if (details.scale == 1.0) return;
                      setState(() {
                        _keyboardZoom =
                            (_keyboardZoomStart * details.scale)
                                .clamp(0.6, 2.5);
                        _updateKeyboardRange();
                      });
                    },
                    child: ValueListenableBuilder<NoteState>(
                      valueListenable: _noteState.notifier,
                      builder: (context, state, child) {
                        final adjusted = KeyboardSettings(
                          height: keyboardHeight,
                          theme: _keyboardSettings.theme,
                          animation: _keyboardSettings.animation,
                          showNoteNames: _keyboardSettings.showNoteNames,
                          showOctaveNumbers: _keyboardSettings.showOctaveNumbers,
                          enableVelocityColors:
                              _keyboardSettings.enableVelocityColors,
                          enableShadows: _keyboardSettings.enableShadows,
                          keySpacing: 0,
                          cornerRadius: _keyboardSettings.cornerRadius,
                          keyWidthScale: 1.0,
                          blackKeyWidthFactor: 0.6,
                          blackKeyHeightFactor: 0.6,
                          performanceMode: _keyboardSettings.performanceMode,
                          pedalInstalled: _keyboardSettings.pedalInstalled,
                          velocityCurvePreset:
                              _keyboardSettings.velocityCurvePreset,
                          velocityCurveExponent:
                              _keyboardSettings.velocityCurveExponent,
                        );
                        return EnhancedPianoKeyboard(
                          activeNotes: state.activeNotes,
                          wrongNotes: _wrongNotes,
                          onKeyPressed: _handleNotePlay,
                          onKeyReleased: _handleNoteRelease,
                          heatmap: _missHeatmap,
                          guideNotes: _guideNotes,
                          guideHands: _guideHands,
                          minNote: _focusRange ? _keyboardRangeStart : 21,
                          maxNote: _focusRange ? _keyboardRangeEnd : 108,
                          settings: adjusted,
                        );
                      },
                    ),
                  ),
                ),
                if (_showAI)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: theme.cardGradient,
                      border: Border(
                        top: BorderSide(
                          color: theme.textColor.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: AIChatWidget(
                      aiTutor: _aiTutor,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLessonTopBar(
    theme_service.ThemeData theme, {
    required bool isNarrow,
    required bool isShort,
  }) {
    final isCompact = _compactHud;
    final compactPadding = isNarrow || isShort;
    return _buildFloatingPanel(
      theme: theme,
      padding: isCompact || compactPadding
          ? const EdgeInsets.fromLTRB(10, 8, 10, 8)
          : const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.music_note_2,
                  color: theme.primaryColor,
                  size: isNarrow ? 16 : 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.song.composer,
                      style: TextStyle(
                        fontSize: isNarrow ? 10 : 11,
                        color: theme.textColor.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '${widget.song.difficulty} · ${_currentBpm().round()} BPM',
                      style: TextStyle(
                        fontSize: isNarrow ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: _isPracticing
                    ? CupertinoColors.systemRed
                    : theme.primaryColor,
                borderRadius: BorderRadius.circular(10),
                onPressed: _isPracticing
                    ? _stopPractice
                    : _startPracticeWithFallingNotes,
                child: Row(
                  children: [
                    Icon(
                      _isPracticing
                          ? CupertinoIcons.stop_fill
                          : CupertinoIcons.play_fill,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isPracticing ? 'Stop' : 'Start',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: _autoRestart
                    ? theme.secondaryColor.withOpacity(0.25)
                    : theme.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                onPressed: () =>
                    setState(() => _autoRestart = !_autoRestart),
                child: Row(
                  children: [
                    Icon(
                      _autoRestart
                          ? CupertinoIcons.repeat
                          : CupertinoIcons.pause_circle,
                      color: _autoRestart
                          ? theme.primaryColor
                          : theme.textColor,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _autoRestart ? 'Auto Loop' : 'Stop End',
                      style: TextStyle(
                        color: _autoRestart
                            ? theme.primaryColor
                            : theme.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: _isPreviewing
                    ? CupertinoColors.systemOrange
                    : theme.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                onPressed: _isPreviewing ? _stopPreview : _startPreview,
                child: Row(
                  children: [
                    Icon(
                      _isPreviewing
                          ? CupertinoIcons.stop_fill
                          : CupertinoIcons.music_note_2,
                      color: _isPreviewing
                          ? Colors.white
                          : theme.textColor,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isPreviewing ? 'Stop' : 'Preview',
                      style: TextStyle(
                        color: _isPreviewing
                            ? Colors.white
                            : theme.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: const EdgeInsets.all(6),
                color: theme.secondaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                onPressed: () => setState(() => _showAI = !_showAI),
                child: Icon(
                  _showAI
                      ? CupertinoIcons.chat_bubble_2_fill
                      : CupertinoIcons.chat_bubble_2,
                  color: theme.primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              CupertinoButton(
                padding: const EdgeInsets.all(6),
                color: theme.surfaceColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
                onPressed: () => setState(() => _compactHud = !_compactHud),
                child: Icon(
                  _compactHud
                      ? CupertinoIcons.arrow_down_right_arrow_up_left
                      : CupertinoIcons.arrow_up_left_arrow_down_right,
                  color: theme.textColor.withOpacity(0.7),
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Tempo',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoSlider(
                  value: _tempoMultiplier,
                  min: 0.1,
                  max: 2.5,
                  divisions: 12,
                  onChanged: (value) {
                    setState(() => _tempoMultiplier = value);
                    _practiceEngine?.setTempo(value);
                    if (_isPracticing) {
                      _startSection();
                    }
                  },
                  activeColor: theme.primaryColor,
                ),
              ),
              Text(
                '${(_tempoMultiplier * 100).round()}%',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildQuickTempoButton('0.25x', 0.25, theme),
              const SizedBox(width: 6),
              _buildQuickTempoButton('0.5x', 0.5, theme),
              const SizedBox(width: 6),
              _buildQuickTempoButton('1.0x', 1.0, theme),
              const Spacer(),
              Text(
                'Auto',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 6),
              CupertinoSwitch(
                value: _autoTempo,
                onChanged: (value) => setState(() => _autoTempo = value),
              ),
            ],
          ),
          if (!isCompact) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Metronome',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 6),
                CupertinoSwitch(
                  value: _metronomeOn,
                  onChanged: _toggleMetronome,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Mode',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoSegmentedControl<bool>(
                  groupValue: _strictMode,
                  onValueChanged: (value) {
                    setState(() => _strictMode = value);
                  },
                  children: const {
                    true: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text('Follow'),
                    ),
                    false: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text('Free'),
                    ),
                  },
                ),
                const Spacer(),
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  onPressed: _isPracticing ? () => _rewindSeconds(2) : null,
                  child: Text(
                    'Replay 2s',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Auto-pause',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 6),
                CupertinoSwitch(
                  value: _autoPauseOnMiss,
                  onChanged: (value) =>
                      setState(() => _autoPauseOnMiss = value),
                ),
                const SizedBox(width: 12),
                Text(
                  'Auto-slow',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 6),
                CupertinoSwitch(
                  value: _autoSlowOnMiss,
                  onChanged: (value) =>
                      setState(() => _autoSlowOnMiss = value),
                ),
                const SizedBox(width: 12),
              Text(
                'Auto zoom',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textColor.withOpacity(0.6),
                ),
              ),
                const SizedBox(width: 6),
                CupertinoSwitch(
                  value: _focusRange,
                  onChanged: (value) => setState(() => _focusRange = value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: theme.textColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonStatsRow(theme_service.ThemeData theme) {
    return _buildFloatingPanel(
      theme: theme,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatItem('Correct', _correctNotes.toString(),
              CupertinoColors.systemGreen, theme),
          const SizedBox(height: 6),
          _buildStatItem(
              'Wrong', _mistakes.toString(), CupertinoColors.systemRed, theme),
          const SizedBox(height: 6),
          _buildStatItem(
            'Accuracy',
            _correctNotes + _mistakes > 0
                ? '${((_correctNotes / (_correctNotes + _mistakes)) * 100).toStringAsFixed(0)}%'
                : '0%',
            theme.primaryColor,
            theme,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: theme.textColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.textColor.withOpacity(0.12),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Streak $_streak  |  x${_scoreMultiplier.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Best: $_bestStreak',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _rankColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _rankLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _rankColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonTimingRow(theme_service.ThemeData theme) {
    return _buildFloatingPanel(
      theme: theme,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _timingFeedback.isEmpty
                  ? 'Timing: --'
                  : 'Timing: $_timingFeedback',
              style: TextStyle(
                fontSize: 12,
                color: _timingFeedback.isEmpty
                    ? theme.textColor.withOpacity(0.6)
                    : _timingColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _sectionStatus.isEmpty
                      ? 'Section in progress'
                      : _sectionStatus,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _sectionProgress.clamp(0.0, 1.0),
                  backgroundColor: theme.textColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  minHeight: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
Widget _buildQuickTempoButton(
      String label, double tempo, theme_service.ThemeData theme) {
    final isSelected = (_tempoMultiplier - tempo).abs() < 0.01;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: isSelected ? theme.primaryColor : theme.surfaceColor,
      borderRadius: BorderRadius.circular(8),
      onPressed: () {
        setState(() => _tempoMultiplier = tempo);
        _practiceEngine?.setTempo(tempo);
        if (_isPracticing) {
          _startSection();
        }
      },
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.white : theme.textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, Color color, theme_service.ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: theme.textColor.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingPanel({
    required theme_service.ThemeData theme,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(12),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: theme.surfaceColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.textColor.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  String _getNoteName(int midiNote) {
    const noteNames = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B'
    ];
    final noteIndex = midiNote % 12;
    final octave = (midiNote / 12).floor() - 1;
    return '${noteNames[noteIndex]}$octave';
  }

  @override
  void dispose() {
    _stopPractice();
    _confettiController.dispose();
    _stopMetronome();
    _stopPreview();
    _playbackTimer?.cancel();
    _audioService.dispose();
    _noteState.dispose();
    _midiService.dispose();
    if (_sessionId != null && _cloudService.isInitialized) {
      final summary = _aiTutor.getSessionStats();
      _cloudService.endSession(_sessionId!, summary: summary);
      _cloudService.generateSessionInsights(_sessionId!, summary: summary);
    }
    super.dispose();
  }
}

class _ConfettiParticle {
  final double x;
  final double size;
  final Color color;
  final double speed;
  final double drift;

  _ConfettiParticle({
    required this.x,
    required this.size,
    required this.color,
    required this.speed,
    required this.drift,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final y = (-0.2 + progress * 1.4 * p.speed) * size.height;
      final x = (p.x + progress * p.drift) * size.width;
      if (y < -20 || y > size.height + 20) continue;
      paint.color = p.color.withOpacity(1.0 - progress);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.particles != particles;
  }
}


