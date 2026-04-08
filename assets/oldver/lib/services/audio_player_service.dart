import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'web_audio_engine.dart';
import '../utils/velocity_curve.dart';

class AudioPlayerService {
  // Enhanced pool for true polyphony with natural sustain
  final Map<int, List<AudioPlayer>> _playerPools = {};
  final Map<int, int> _currentPlayerIndex = {};
  final Map<int, DateTime> _noteStartTimes = {};
  final Map<int, double> _noteVelocities = {};
  final Map<int, AssetSource> _noteAssets = {};
  final Map<AudioPlayer, StreamSubscription<PlayerState>>
      _playerStateSubscriptions = {};
  final Map<AudioPlayer, DateTime> _pendingStartTimes = {};

  // Advanced audio settings
  bool _sustainEnabled = false;
  double _reverbLevel = 0.3;
  double _currentLatency = 0.0;
  double _playbackRate = 1.0;
  double _masterVolume = 1.0;
  bool _performanceMode = false;
  bool _debugLogging = false;
  VelocityCurvePreset _velocityCurvePreset = VelocityCurvePreset.linear;
  double _velocityCurveExponent = 1.0;
  int _maxVoices = 48;

  // Natural piano decay settings
  static const Duration shortTapThreshold = Duration(milliseconds: 150);
  static const Duration naturalDecay = Duration(milliseconds: 800);
  static const Duration sustainedDecay = Duration(seconds: 3);

  // Performance settings
  static const int minMidiNote = 21; // A0
  static const int maxMidiNote = 108; // C8
  int _playersPerNote = 6; // Increased for rapid playing

  bool _isInitialized = false;
  final Set<int> _activeNotes = {};
  final Map<int, Timer?> _releaseTimers = {};
  final Map<int, AudioPlayer?> _currentPlayers = {};
  final WebAudioEngine _webAudio = WebAudioEngine();
  int _audioPlayCount = 0;
  int _audioErrorCount = 0;
  int? _lastAudioNote;
  DateTime? _lastAudioNoteAt;
  double? _lastAudioStartLatencyMs;
  String? _lastAudioError;

  AudioPlayerService();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _log('Initializing enhanced piano audio engine...');

      // Pre-create pools for all 88 notes (lazy AudioPlayer creation)
      for (int note = minMidiNote; note <= maxMidiNote; note++) {
        _playerPools[note] = [];
        _currentPlayerIndex[note] = 0;
        _noteAssets[note] = AssetSource(_buildAssetPath(note));
      }

      if (kIsWeb && _webAudio.isSupported) {
        await _webAudio.initialize(
          preloadAll: false,
          log: _log,
        );
        // Preload a core range quickly, then warm the rest in the background.
        await _webAudio.preloadRange(start: 48, end: 72);
        unawaited(_webAudio.preloadAllNotes(log: _log));
        _log('WebAudio engine ready');
      }

      _isInitialized = true;
      _log(
          'Piano audio engine initialized: 88 notes, max $_playersPerNote players per note');
      _warmUp();
    } catch (e) {
      _log('Error initializing audio player service: $e');
    }
  }

  AudioPlayer? _getNextAvailablePlayer(int note) {
    if (!_playerPools.containsKey(note)) return null;

    final pool = _playerPools[note]!;
    if (pool.length < _playersPerNote) {
      final player = AudioPlayer();
      unawaited(player.setReleaseMode(ReleaseMode.release));
      unawaited(player.setVolume(1.0));
      _playerStateSubscriptions[player] =
          player.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.playing) {
          final start = _pendingStartTimes.remove(player);
          if (start != null) {
            _lastAudioStartLatencyMs =
                DateTime.now().difference(start).inMilliseconds.toDouble();
          }
        }
      });
      pool.add(player);
    }

    if (pool.isEmpty) return null;

    final currentIndex = _currentPlayerIndex[note]! % pool.length;

    // Round-robin selection
    final player = pool[currentIndex];
    _currentPlayerIndex[note] = (currentIndex + 1) % pool.length;

    return player;
  }

  Future<void> playNote(int midiNote, double velocity,
      {bool fromMidi = true}) async {
    if (!_isInitialized) await initialize();

    if (midiNote < minMidiNote || midiNote > maxMidiNote) {
      _log(
          'Invalid MIDI note: $midiNote (valid range: $minMidiNote-$maxMidiNote)');
      return;
    }

    try {
      if (!_activeNotes.contains(midiNote) &&
          _activeNotes.length >= _maxVoices) {
        _stealOldestNote();
      }

      // Cancel any pending release for this note
      _releaseTimers[midiNote]?.cancel();
      _releaseTimers[midiNote] = null;

      _audioPlayCount++;
      _lastAudioNote = midiNote;
      _lastAudioNoteAt = DateTime.now();

      if (kIsWeb && _webAudio.isSupported) {
        final dynamicVolume = _applyVelocityCurve(velocity);
        final reverbAdjustedVolume =
            dynamicVolume * (1.0 + (_reverbLevel * 0.3));
        final finalVolume =
            (reverbAdjustedVolume * _masterVolume).clamp(0.0, 2.0);
        await _webAudio.playNote(midiNote, finalVolume);
      } else {
        // Get next available player
        final player = _getNextAvailablePlayer(midiNote);
        if (player == null) {
          _log('No player available for note $midiNote');
          return;
        }

        // Store player reference for this note
        _currentPlayers[midiNote] = player;

        _pendingStartTimes[player] = DateTime.now();
        _scheduleStartTimeout(player, midiNote);

        await _playNoteImmediately(player, midiNote, velocity);
      }

      // Track active notes with metadata
      _activeNotes.add(midiNote);
      _noteStartTimes[midiNote] = DateTime.now();
      _noteVelocities[midiNote] = velocity;
    } catch (e) {
      _audioErrorCount++;
      _lastAudioError = e.toString();
      _log('Error playing note $midiNote: $e');
    }
  }

  void _scheduleStartTimeout(AudioPlayer player, int midiNote) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_pendingStartTimes.containsKey(player)) {
        _audioErrorCount++;
        _lastAudioError =
            'start_timeout note=$midiNote asset=${_noteAssets[midiNote]}';
      }
    });
  }

  Future<void> _playNoteImmediately(
      AudioPlayer player, int midiNote, double velocity) async {
    try {
      final assetSource = _noteAssets[midiNote];
      if (assetSource == null) return;

      // Apply velocity curve for natural dynamics
      final dynamicVolume = _applyVelocityCurve(velocity);

      // Apply reverb simulation (volume modulation)
      final reverbAdjustedVolume = dynamicVolume * (1.0 + (_reverbLevel * 0.3));

      // Apply master volume
      final finalVolume =
          (reverbAdjustedVolume * _masterVolume).clamp(0.0, 2.0);
      unawaited(player.setVolume(finalVolume));

      // Apply playback rate for latency compensation
      if (_playbackRate != 1.0) {
        unawaited(player.setPlaybackRate(_playbackRate));
      }

      // Play the note
      unawaited(player.play(assetSource));
    } catch (e) {
      _audioErrorCount++;
      _lastAudioError = e.toString();
      _log('Error in _playNoteImmediately: $e');
    }
  }

  double _applyVelocityCurve(double velocity) {
    final exponent = velocityCurveExponent(
      _velocityCurvePreset,
      _velocityCurveExponent,
    );
    final clamped = velocity.clamp(0.0, 1.0);
    return math.pow(clamped, exponent).clamp(0.0, 1.0).toDouble();
  }

  Future<void> stopNote(int midiNote, {bool immediate = false}) async {
    try {
      if (kIsWeb && _webAudio.isSupported) {
        await _webAudio.stopNote(midiNote);
        _activeNotes.remove(midiNote);
        return;
      }
      // Check if note was held down (natural sustain)
      final startTime = _noteStartTimes[midiNote];
      final velocity = _noteVelocities[midiNote] ?? 0.8;

      Duration heldDuration = Duration.zero;
      if (startTime != null) {
        heldDuration = DateTime.now().difference(startTime);
      }

      _releaseTimers[midiNote]?.cancel();

      if (immediate) {
        // Immediate stop for staccato
        _stopNoteImmediately(midiNote);
      } else if (heldDuration < shortTapThreshold) {
        // Short tap - quick release
        _releaseTimers[midiNote] = Timer(const Duration(milliseconds: 300), () {
          _releaseNoteNaturally(midiNote, velocity);
        });
      } else if (_sustainEnabled) {
        // Sustain pedal - long release
        _releaseTimers[midiNote] = Timer(sustainedDecay, () {
          _releaseNoteNaturally(midiNote, velocity);
        });
      } else {
        // Natural piano decay based on velocity
        final decayDuration = _calculateNaturalDecay(velocity);
        _releaseTimers[midiNote] = Timer(decayDuration, () {
          _releaseNoteNaturally(midiNote, velocity);
        });
      }

      _activeNotes.remove(midiNote);
    } catch (e) {
      _log('Error stopping note $midiNote: $e');
    }
  }

  Duration _calculateNaturalDecay(double velocity) {
    // Softer notes decay faster, harder notes sustain longer
    final baseDecay = naturalDecay.inMilliseconds;
    final velocityFactor = velocity * 0.5 + 0.5; // Range: 0.5 - 1.0
    final reverbFactor = 1.0 + (_reverbLevel * 0.5);

    return Duration(
        milliseconds: (baseDecay * velocityFactor * reverbFactor).toInt());
  }

  void _releaseNoteNaturally(int midiNote, double velocity) {
    final player = _currentPlayers[midiNote];
    if (player == null) return;

    try {
      // Gradual fade out for natural release
      final fadeDuration = (200 * (1.0 + _reverbLevel)).toInt();

      player.setVolume(0.0);
      Future.delayed(Duration(milliseconds: fadeDuration), () {
        player.stop();
      });
    } catch (e) {
      _log('Error releasing note $midiNote: $e');
    }

    _noteStartTimes.remove(midiNote);
    _noteVelocities.remove(midiNote);
    _currentPlayers.remove(midiNote);
  }

  void _stopNoteImmediately(int midiNote) {
    final player = _currentPlayers[midiNote];
    if (player != null) {
      try {
        player.stop();
      } catch (e) {
        _log('Error stopping note immediately: $e');
      }
    }

    _noteStartTimes.remove(midiNote);
    _noteVelocities.remove(midiNote);
    _currentPlayers.remove(midiNote);
  }

  Future<void> stopAllNotes({bool immediate = false}) async {
    try {
      if (kIsWeb && _webAudio.isSupported) {
        await _webAudio.stopAll();
        _activeNotes.clear();
        return;
      }
      for (var timer in _releaseTimers.values) {
        timer?.cancel();
      }
      _releaseTimers.clear();

      for (var note in List.from(_activeNotes)) {
        if (immediate) {
          _stopNoteImmediately(note);
        } else {
          final velocity = _noteVelocities[note] ?? 0.8;
          _releaseNoteNaturally(note, velocity);
        }
      }

      _activeNotes.clear();
      _noteStartTimes.clear();
      _noteVelocities.clear();
      _currentPlayers.clear();
    } catch (e) {
      _log('Error stopping all notes: $e');
    }
  }

  String _getNoteNameFromMidi(int midiNote) {
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
    final octave = (midiNote / 12).floor() - 1;
    final noteName = noteNames[midiNote % 12];
    return '$noteName$octave';
  }

  void setLatency(double latencyMs) {
    _currentLatency = latencyMs.clamp(-100.0, 200.0);
    _updatePlaybackRate();
    _log('Latency set to: ${_currentLatency.toStringAsFixed(1)}ms');
  }

  void _updatePlaybackRate() {
    if (_currentLatency < 0) {
      final adjustment = (_currentLatency.abs() / 1000) * 0.5;
      _playbackRate = (1.0 + adjustment).clamp(0.95, 1.15);
    } else if (_currentLatency > 0) {
      final adjustment = (_currentLatency / 1000) * 0.5;
      _playbackRate = (1.0 - adjustment).clamp(0.85, 1.05);
    } else {
      _playbackRate = 1.0;
    }

    _log('Playback rate adjusted to: ${_playbackRate.toStringAsFixed(3)}');
  }

  void setSustain(bool enabled) {
    _sustainEnabled = enabled;
    _log('Sustain pedal: ${enabled ? "ON" : "OFF"}');

    // If sustain released, gradually release all held notes
    if (!enabled) {
      for (var note in List.from(_activeNotes)) {
        if (_releaseTimers[note] == null) {
          final velocity = _noteVelocities[note] ?? 0.8;
          _releaseTimers[note] = Timer(const Duration(milliseconds: 500), () {
            _releaseNoteNaturally(note, velocity);
          });
        }
      }
    }
  }

  void setReverbLevel(double level) {
    _reverbLevel = level.clamp(0.0, 1.0);
    _log('Reverb level: ${(_reverbLevel * 100).toInt()}%');
  }

  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 2.0);
    _log(
        'Master volume: ${(_masterVolume * 100).toInt()}%${_masterVolume > 1.0 ? " BOOST" : ""}');
  }

  Map<String, dynamic> getPerformanceStats() {
    return {
      'activeNotes': _activeNotes.length,
      'maxPlayersPerNote': _playersPerNote,
      'sustainEnabled': _sustainEnabled,
      'reverbLevel': _reverbLevel,
      'masterVolume': _masterVolume,
      'latency': _currentLatency,
      'playbackRate': _playbackRate,
      'performanceMode': _performanceMode,
      'audioPlayCount': _audioPlayCount,
      'audioErrorCount': _audioErrorCount,
      'lastAudioNote': _lastAudioNote,
      'lastAudioNoteAt': _lastAudioNoteAt?.toIso8601String(),
      'lastAudioStartLatencyMs': _lastAudioStartLatencyMs,
      'lastAudioError': _lastAudioError,
      'audioEngine': kIsWeb && _webAudio.isSupported ? 'webaudio' : 'audioplayers',
      'webAudioBuffers': _webAudio.bufferCount,
      'webAudioActiveSources': _webAudio.activeSources,
      'webAudioReady': _webAudio.isReady,
      'webAudioPreloading': _webAudio.isPreloading,
      'webAudioPreloadCount': _webAudio.preloadCount,
      'webAudioPreloadTotal': _webAudio.preloadTotal,
      'webAudioLastError': _webAudio.lastError,
      'webAudioLastLatencyMs': _webAudio.lastStartLatencyMs,
    };
  }

  double get currentLatency => _currentLatency;
  double get playbackRate => _playbackRate;
  double get masterVolume => _masterVolume;
  double get reverbLevel => _reverbLevel;
  int get activeNotesCount => _activeNotes.length;
  Set<int> get activeNotes => Set.from(_activeNotes);
  bool get isInitialized => _isInitialized;
  bool get sustainEnabled => _sustainEnabled;
  bool get performanceMode => _performanceMode;

  void dispose() {
    if (kIsWeb && _webAudio.isSupported) {
      _webAudio.stopAll();
    }
    for (var timer in _releaseTimers.values) {
      timer?.cancel();
    }
    _releaseTimers.clear();

    for (var pool in _playerPools.values) {
      for (var player in pool) {
        _playerStateSubscriptions[player]?.cancel();
        player.dispose();
      }
    }
    _playerStateSubscriptions.clear();
    _pendingStartTimes.clear();

    _playerPools.clear();
    _activeNotes.clear();
    _noteStartTimes.clear();
    _noteVelocities.clear();
    _currentPlayers.clear();
    _noteAssets.clear();
    _isInitialized = false;
  }

  void setPerformanceMode(bool enabled) {
    _performanceMode = enabled;
    _playersPerNote = enabled ? 3 : 6;
    _maxVoices = enabled ? 24 : 48;
    if (enabled) {
      _reverbLevel = 0.0;
    } else if (_reverbLevel == 0.0) {
      _reverbLevel = 0.3;
    }
    if (kIsWeb && _webAudio.isSupported) {
      _webAudio.initialize(preloadAll: enabled, log: _log);
    }
  }

  void setVelocityCurve(
      VelocityCurvePreset preset, double customExponent) {
    _velocityCurvePreset = preset;
    _velocityCurveExponent = customExponent.clamp(0.5, 2.0);
  }

  void _stealOldestNote() {
    if (_noteStartTimes.isEmpty) return;

    int? oldestNote;
    DateTime? oldestTime;

    for (final entry in _noteStartTimes.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        oldestNote = entry.key;
      }
    }

    if (oldestNote != null) {
      _releaseTimers[oldestNote]?.cancel();
      _releaseTimers.remove(oldestNote);
      _stopNoteImmediately(oldestNote);
      _activeNotes.remove(oldestNote);
    }
  }

  void setDebugLogging(bool enabled) {
    _debugLogging = enabled;
  }

  void _log(String message) {
    if (_debugLogging) {
      debugPrint(message);
    }
  }

  void _warmUp() {
    if (kIsWeb && _webAudio.isSupported) {
      return;
    }
    final warmUpNotes = [21, 33, 45, 57, 69, 81, 93, 105];
    for (final note in warmUpNotes) {
      final player = _getNextAvailablePlayer(note);
      final assetSource = _noteAssets[note];
      if (player == null || assetSource == null) continue;
      unawaited(player.setVolume(0.0));
      unawaited(player.play(assetSource));
      Future.delayed(const Duration(milliseconds: 20), () {
        player.stop();
      });
    }
  }

  String _buildAssetPath(int midiNote) {
    final noteName = _getNoteNameFromMidi(midiNote);
    final safeNoteName = noteName.replaceAll('#', 's');
    return "sounds/note_${midiNote.toString().padLeft(3, '0')}_$safeNoteName.wav";
  }
}
