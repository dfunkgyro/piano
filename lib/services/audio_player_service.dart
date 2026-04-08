import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'web_audio_engine.dart';
import '../utils/velocity_curve.dart';

enum UltraPerformanceMode {
  off,
  audioOnly,
  polyphony,
  visuals,
}

UltraPerformanceMode ultraModeFromString(String? value) {
  switch (value) {
    case 'audioOnly':
      return UltraPerformanceMode.audioOnly;
    case 'polyphony':
      return UltraPerformanceMode.polyphony;
    case 'visuals':
      return UltraPerformanceMode.visuals;
    default:
      return UltraPerformanceMode.off;
  }
}

String ultraModeToString(UltraPerformanceMode mode) {
  switch (mode) {
    case UltraPerformanceMode.audioOnly:
      return 'audioOnly';
    case UltraPerformanceMode.polyphony:
      return 'polyphony';
    case UltraPerformanceMode.visuals:
      return 'visuals';
    case UltraPerformanceMode.off:
    default:
      return 'off';
  }
}

class _ActiveVoice {
  final AudioPlayer player;
  final DateTime startedAt;
  final double velocity;

  const _ActiveVoice({
    required this.player,
    required this.startedAt,
    required this.velocity,
  });
}

class AudioPlayerService {
  static final AudioPlayerService _shared = AudioPlayerService._internal();

  factory AudioPlayerService() => _shared;

  // Tracks overlapping voices for repeated strikes of the same note.
  final Map<int, List<_ActiveVoice>> _activeVoices = {};
  final Map<int, DateTime> _legacyNoteStartTimes = {};
  final Map<int, double> _legacyNoteVelocities = {};
  final Map<int, AudioPlayer?> _legacyCurrentPlayers = {};

  // Enhanced pool for true polyphony with natural sustain
  final Map<int, List<AudioPlayer>> _playerPools = {};
  final Map<int, int> _currentPlayerIndex = {};
  final Map<int, AssetSource> _noteAssets = {};
  final Map<AudioPlayer, StreamSubscription<PlayerState>>
      _playerStateSubscriptions = {};
  final Map<AudioPlayer, DateTime> _pendingStartTimes = {};
  final Map<AudioPlayer, double> _playerVolumes = {};

  // Advanced audio settings
  bool _sustainEnabled = false;
  double _reverbLevel = 0.3;
  double _currentLatency = 0.0;
  double _playbackRate = 1.0;
  double _masterVolume = 1.0;
  bool _performanceMode = false;
  UltraPerformanceMode _ultraMode = UltraPerformanceMode.off;
  bool _debugLogging = false;
  VelocityCurvePreset _velocityCurvePreset = VelocityCurvePreset.linear;
  double _velocityCurveExponent = 1.0;
  int _maxVoices = 48;
  late final List<double> _velocityVolumeTable =
      List<double>.generate(128, _buildVelocityVolume);

  // Natural piano decay settings
  static const Duration shortTapThreshold = Duration(milliseconds: 150);
  static const Duration naturalDecay = Duration(milliseconds: 800);
  static const Duration sustainedDecay = Duration(seconds: 3);
  static const Duration externalBurstDecay = Duration(milliseconds: 90);

  // Performance settings
  static const int minMidiNote = 21; // A0
  static const int maxMidiNote = 108; // C8
  int _playersPerNote = 6; // Increased for rapid playing
  bool _externalMidiPerformanceActive = false;
  Timer? _externalMidiPerformanceTimer;
  bool _fullWarmUpStarted = false;

  bool _isInitialized = false;
  final Set<int> _activeNotes = {};
  final Map<AudioPlayer, Timer?> _releaseTimers = {};
  final Map<int, Timer?> _legacyReleaseTimers = {};
  final WebAudioEngine _webAudio = WebAudioEngine.instance;
  int _audioPlayCount = 0;
  int _audioErrorCount = 0;
  int? _lastAudioNote;
  DateTime? _lastAudioNoteAt;
  double? _lastAudioStartLatencyMs;
  String? _lastAudioError;

  AudioPlayerService._internal();

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
      _startFullWarmUp();
    } catch (e) {
      _log('Error initializing audio player service: $e');
    }
  }

  void setExternalMidiPerformanceActive(bool active) {
    if (active) {
      _externalMidiPerformanceActive = true;
      _externalMidiPerformanceTimer?.cancel();
      _externalMidiPerformanceTimer =
          Timer(const Duration(milliseconds: 1200), () {
        _externalMidiPerformanceActive = false;
      });
      return;
    }
    _externalMidiPerformanceTimer?.cancel();
    _externalMidiPerformanceActive = false;
  }

  bool get externalMidiPerformanceActive => _externalMidiPerformanceActive;

  AudioPlayer? _getNextAvailablePlayer(int note) {
    if (!_playerPools.containsKey(note)) return null;

    final pool = _playerPools[note]!;
    if (pool.length < _playersPerNote) {
      final player = AudioPlayer();
      unawaited(player.setReleaseMode(ReleaseMode.stop));
      if (!kIsWeb) {
        unawaited(player.setPlayerMode(PlayerMode.lowLatency));
      }
      unawaited(player.setVolume(1.0));
      _playerVolumes[player] = 1.0;
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

    final activePlayers = _activeVoices[note]?.map((v) => v.player).toSet() ?? {};
    for (int i = 0; i < pool.length; i++) {
      final index = (_currentPlayerIndex[note]! + i) % pool.length;
      final candidate = pool[index];
      if (!activePlayers.contains(candidate) &&
          (_releaseTimers[candidate] == null)) {
        _currentPlayerIndex[note] = (index + 1) % pool.length;
        return candidate;
      }
    }

    final voices = _activeVoices[note];
    if (voices != null && voices.isNotEmpty) {
      final voiceToReuse = voices.removeAt(0);
      _releaseTimers[voiceToReuse.player]?.cancel();
      _releaseTimers.remove(voiceToReuse.player);
      try {
        voiceToReuse.player.stop();
      } catch (_) {}
      _currentPlayerIndex[note] =
          (pool.indexOf(voiceToReuse.player) + 1) % pool.length;
      return voiceToReuse.player;
    }

    final currentIndex = _currentPlayerIndex[note]! % pool.length;
    final player = pool[currentIndex];
    _currentPlayerIndex[note] = (currentIndex + 1) % pool.length;
    return player;
  }

  bool _useLegacyPerformancePath({required bool fromMidi}) {
    return _performanceMode && !kIsWeb && !_externalMidiPerformanceActive && !fromMidi;
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
      if (_useLegacyPerformancePath(fromMidi: fromMidi)) {
        await _playNoteLegacyPerformance(midiNote, velocity);
        return;
      }

      if (!_activeNotes.contains(midiNote) &&
          _activeNotes.length >= _effectiveMaxVoices) {
        _stealOldestNote();
      }

      _audioPlayCount++;
      _lastAudioNote = midiNote;
      _lastAudioNoteAt = DateTime.now();

      final finalVolume = _resolveFinalVolume(velocity);
      if (kIsWeb && _webAudio.isSupported) {
        _webAudio.setVolume(_masterVolume);
        await _webAudio.playNote(midiNote, velocity: finalVolume);
      } else {
        // Get next available player
        final player = _getNextAvailablePlayer(midiNote);
        if (player == null) {
          _log('No player available for note $midiNote');
          return;
        }
        _releaseTimers[player]?.cancel();
        _releaseTimers.remove(player);

        _pendingStartTimes[player] = DateTime.now();
        _scheduleStartTimeout(player, midiNote);

        await _playNoteImmediately(player, midiNote, finalVolume);

        final voice = _ActiveVoice(
          player: player,
          startedAt: DateTime.now(),
          velocity: velocity,
        );
        final voices = _activeVoices.putIfAbsent(midiNote, () => []);
        voices.add(voice);
      }

      // Track active notes with metadata
      _activeNotes.add(midiNote);
    } catch (e) {
      _audioErrorCount++;
      _lastAudioError = e.toString();
      _log('Error playing note $midiNote: $e');
    }
  }

  Future<void> _playNoteLegacyPerformance(int midiNote, double velocity) async {
    if (!_activeNotes.contains(midiNote) && _activeNotes.length >= _maxVoices) {
      _stealOldestNote();
    }

    _legacyReleaseTimers[midiNote]?.cancel();
    _legacyReleaseTimers[midiNote] = null;

    _audioPlayCount++;
    _lastAudioNote = midiNote;
    _lastAudioNoteAt = DateTime.now();

    final player = _getNextAvailablePlayer(midiNote);
    if (player == null) {
      _log('No player available for note $midiNote');
      return;
    }

    _legacyCurrentPlayers[midiNote] = player;
    _pendingStartTimes[player] = DateTime.now();
    _scheduleStartTimeout(player, midiNote);

    final finalVolume = _resolveFinalVolume(velocity);
    await _playNoteImmediately(player, midiNote, finalVolume);

    _activeNotes.add(midiNote);
    _legacyNoteStartTimes[midiNote] = DateTime.now();
    _legacyNoteVelocities[midiNote] = velocity;
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
      AudioPlayer player, int midiNote, double finalVolume) async {
    try {
      final assetSource = _noteAssets[midiNote];
      if (assetSource == null) return;

      final previousVolume = _playerVolumes[player];
      if (previousVolume == null || (previousVolume - finalVolume).abs() > 0.01) {
        _playerVolumes[player] = finalVolume;
        unawaited(player.setVolume(finalVolume));
      }

      // Apply playback rate for latency compensation
      if (_playbackRate != 1.0 &&
          (kIsWeb || defaultTargetPlatform != TargetPlatform.android)) {
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

  double _buildVelocityVolume(int step) {
    final velocity = step / 127.0;
    final dynamicVolume = _applyVelocityCurve(velocity);
    final reverbAdjustedVolume = dynamicVolume * (1.0 + (_reverbLevel * 0.3));
    return (reverbAdjustedVolume * _masterVolume).clamp(0.0, 2.0);
  }

  double _resolveFinalVolume(double velocity) {
    final index = (velocity.clamp(0.0, 1.0) * 127).round().clamp(0, 127);
    return _velocityVolumeTable[index];
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
      if (_useLegacyPerformancePath(fromMidi: false)) {
        await _stopNoteLegacyPerformance(midiNote, immediate: immediate);
        return;
      }
      if (kIsWeb && _webAudio.isSupported) {
        await _webAudio.stopNote(midiNote);
        _activeNotes.remove(midiNote);
        return;
      }
      final voices = _activeVoices[midiNote];
      if (voices == null || voices.isEmpty) {
        _activeNotes.remove(midiNote);
        return;
      }
      final voice = voices.removeAt(0);

      Duration heldDuration = Duration.zero;
      heldDuration = DateTime.now().difference(voice.startedAt);

      _releaseTimers[voice.player]?.cancel();
      _releaseTimers.remove(voice.player);

      if (immediate) {
        _stopVoiceImmediately(midiNote, voice);
      } else if (heldDuration < shortTapThreshold) {
        _releaseTimers[voice.player] =
            Timer(const Duration(milliseconds: 300), () {
          _releaseVoiceNaturally(midiNote, voice);
        });
      } else if (_externalMidiPerformanceActive) {
        _releaseTimers[voice.player] = Timer(externalBurstDecay, () {
          _releaseVoiceNaturally(midiNote, voice);
        });
      } else if (_sustainEnabled) {
        _releaseTimers[voice.player] = Timer(sustainedDecay, () {
          _releaseVoiceNaturally(midiNote, voice);
        });
      } else {
        final decayDuration = _calculateNaturalDecay(voice.velocity);
        _releaseTimers[voice.player] = Timer(decayDuration, () {
          _releaseVoiceNaturally(midiNote, voice);
        });
      }

      if (voices.isEmpty) {
        _activeVoices.remove(midiNote);
        _activeNotes.remove(midiNote);
      }
    } catch (e) {
      _log('Error stopping note $midiNote: $e');
    }
  }

  int get _effectiveMaxVoices => _externalMidiPerformanceActive
      ? math.max(_maxVoices, 72)
      : _maxVoices;

  Future<void> _stopNoteLegacyPerformance(int midiNote, {bool immediate = false}) async {
    final startTime = _legacyNoteStartTimes[midiNote];
    final velocity = _legacyNoteVelocities[midiNote] ?? 0.8;

    Duration heldDuration = Duration.zero;
    if (startTime != null) {
      heldDuration = DateTime.now().difference(startTime);
    }

    _legacyReleaseTimers[midiNote]?.cancel();

    if (immediate) {
      _stopNoteImmediatelyLegacy(midiNote);
    } else if (heldDuration < shortTapThreshold) {
      _legacyReleaseTimers[midiNote] = Timer(const Duration(milliseconds: 180), () {
        _releaseNoteNaturallyLegacy(midiNote);
      });
    } else if (_sustainEnabled) {
      _legacyReleaseTimers[midiNote] = Timer(sustainedDecay, () {
        _releaseNoteNaturallyLegacy(midiNote);
      });
    } else {
      final decayDuration = _calculateNaturalDecay(velocity);
      _legacyReleaseTimers[midiNote] = Timer(decayDuration, () {
        _releaseNoteNaturallyLegacy(midiNote);
      });
    }

    _activeNotes.remove(midiNote);
  }

  void _releaseNoteNaturallyLegacy(int midiNote) {
    final player = _legacyCurrentPlayers[midiNote];
    if (player == null) return;
    try {
      player.setVolume(0.0);
      Future.delayed(const Duration(milliseconds: 60), () {
        player.stop();
      });
    } catch (e) {
      _log('Error releasing note $midiNote: $e');
    }
    _legacyNoteStartTimes.remove(midiNote);
    _legacyNoteVelocities.remove(midiNote);
    _legacyCurrentPlayers.remove(midiNote);
    _legacyReleaseTimers.remove(midiNote);
  }

  void _stopNoteImmediatelyLegacy(int midiNote) {
    final player = _legacyCurrentPlayers[midiNote];
    if (player != null) {
      try {
        player.stop();
      } catch (e) {
        _log('Error stopping legacy note immediately: $e');
      }
    }
    _legacyNoteStartTimes.remove(midiNote);
    _legacyNoteVelocities.remove(midiNote);
    _legacyCurrentPlayers.remove(midiNote);
    _legacyReleaseTimers.remove(midiNote);
  }

  Duration _calculateNaturalDecay(double velocity) {
    // Softer notes decay faster, harder notes sustain longer
    final baseDecay = naturalDecay.inMilliseconds;
    final velocityFactor = velocity * 0.5 + 0.5; // Range: 0.5 - 1.0
    final reverbFactor = 1.0 + (_reverbLevel * 0.5);

    return Duration(
        milliseconds: (baseDecay * velocityFactor * reverbFactor).toInt());
  }

  void _releaseVoiceNaturally(int midiNote, _ActiveVoice voice) {
    try {
      final fadeDuration = _externalMidiPerformanceActive
          ? 24
          : (200 * (1.0 + _reverbLevel)).toInt();
      voice.player.setVolume(0.0);
      Future.delayed(Duration(milliseconds: fadeDuration), () {
        voice.player.stop();
      });
    } catch (e) {
      _log('Error releasing note $midiNote: $e');
    }
    _releaseTimers.remove(voice.player);
  }

  void _stopVoiceImmediately(int midiNote, _ActiveVoice voice) {
    try {
      voice.player.stop();
    } catch (e) {
      _log('Error stopping note immediately: $e');
    }
    _releaseTimers.remove(voice.player);
  }

  Future<void> panic({String reason = 'panic'}) async {
    _log('Audio panic: $reason');
    _sustainEnabled = false;
    await stopAllNotes(immediate: true);
    for (final pool in _playerPools.values) {
      for (final player in pool) {
        _playerVolumes[player] = 1.0;
      }
    }
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
      for (var timer in _legacyReleaseTimers.values) {
        timer?.cancel();
      }
      _legacyReleaseTimers.clear();

      for (final note in _legacyCurrentPlayers.keys.toList()) {
        if (immediate) {
          _stopNoteImmediatelyLegacy(note);
        } else {
          _releaseNoteNaturallyLegacy(note);
        }
      }

      for (final entry in _activeVoices.entries.toList()) {
        final note = entry.key;
        final voices = List<_ActiveVoice>.from(entry.value);
        for (final voice in voices) {
          if (immediate) {
            _stopVoiceImmediately(note, voice);
          } else {
            _releaseVoiceNaturally(note, voice);
          }
        }
      }

      _activeNotes.clear();
      _activeVoices.clear();
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
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _playbackRate = 1.0;
      return;
    }
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
      for (final entry in _activeVoices.entries) {
        final note = entry.key;
        for (final voice in entry.value) {
          if (_releaseTimers[voice.player] == null) {
            _releaseTimers[voice.player] =
                Timer(const Duration(milliseconds: 500), () {
              _releaseVoiceNaturally(note, voice);
            });
          }
        }
      }
    }
  }

  void setReverbLevel(double level) {
    _reverbLevel = level.clamp(0.0, 1.0);
    for (var i = 0; i < 128; i++) {
      _velocityVolumeTable[i] = _buildVelocityVolume(i);
    }
    _log('Reverb level: ${(_reverbLevel * 100).toInt()}%');
  }

  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 2.0);
    for (var i = 0; i < 128; i++) {
      _velocityVolumeTable[i] = _buildVelocityVolume(i);
    }
    _log(
        'Master volume: ${(_masterVolume * 100).toInt()}%${_masterVolume > 1.0 ? " BOOST" : ""}');
    if (kIsWeb && _webAudio.isSupported) {
      _webAudio.setVolume(_masterVolume);
    }
  }

  Map<String, dynamic> getPerformanceStats() {
    return {
      'activeNotes': _activeNotes.length,
      'activeVoices': _activeVoices.values.fold<int>(0, (sum, voices) => sum + voices.length),
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
    for (var timer in _legacyReleaseTimers.values) {
      timer?.cancel();
    }
    _legacyReleaseTimers.clear();

    for (var pool in _playerPools.values) {
      for (var player in pool) {
        _playerStateSubscriptions[player]?.cancel();
        player.dispose();
      }
    }
    _playerStateSubscriptions.clear();
    _pendingStartTimes.clear();
    _playerVolumes.clear();
    _externalMidiPerformanceTimer?.cancel();

    _playerPools.clear();
    _activeNotes.clear();
    _activeVoices.clear();
    _legacyNoteStartTimes.clear();
    _legacyNoteVelocities.clear();
    _legacyCurrentPlayers.clear();
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

  UltraPerformanceMode get ultraMode => _ultraMode;

  void setUltraMode(UltraPerformanceMode mode) {
    _ultraMode = mode;
    if (mode == UltraPerformanceMode.off) {
      // Re-apply the base performance mode settings.
      setPerformanceMode(_performanceMode);
      return;
    }

    // Ultra modes always force the base performance mode ON.
    if (!_performanceMode) {
      setPerformanceMode(true);
    }

    switch (mode) {
      case UltraPerformanceMode.audioOnly:
        _playersPerNote = 8;
        _maxVoices = 64;
        _reverbLevel = 0.0;
        if (kIsWeb && _webAudio.isSupported) {
          _webAudio.initialize(preloadAll: true, log: _log);
        }
        break;
      case UltraPerformanceMode.polyphony:
        _playersPerNote = 10;
        _maxVoices = 96;
        _reverbLevel = 0.0;
        if (kIsWeb && _webAudio.isSupported) {
          _webAudio.initialize(preloadAll: true, log: _log);
        }
        break;
      case UltraPerformanceMode.visuals:
        _playersPerNote = 6;
        _maxVoices = 48;
        _reverbLevel = 0.0;
        if (kIsWeb && _webAudio.isSupported) {
          _webAudio.initialize(preloadAll: false, log: _log);
        }
        break;
      case UltraPerformanceMode.off:
        break;
    }
  }

  void setVelocityCurve(VelocityCurvePreset preset, double customExponent) {
    _velocityCurvePreset = preset;
    _velocityCurveExponent = customExponent.clamp(0.5, 2.0);
  }

  void _stealOldestNote() {
    int? oldestNote;
    _ActiveVoice? oldestVoice;

    for (final entry in _activeVoices.entries) {
      for (final voice in entry.value) {
        if (oldestVoice == null || voice.startedAt.isBefore(oldestVoice.startedAt)) {
          oldestVoice = voice;
          oldestNote = entry.key;
        }
      }
    }

    if (oldestNote != null && oldestVoice != null) {
      _activeVoices[oldestNote]?.remove(oldestVoice);
      if (_activeVoices[oldestNote]?.isEmpty ?? false) {
        _activeVoices.remove(oldestNote);
        _activeNotes.remove(oldestNote);
      }
      _releaseTimers[oldestVoice.player]?.cancel();
      _releaseTimers.remove(oldestVoice.player);
      _stopVoiceImmediately(oldestNote, oldestVoice);
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

  void _startFullWarmUp() {
    if (_fullWarmUpStarted || kIsWeb && _webAudio.isSupported) {
      return;
    }
    _fullWarmUpStarted = true;
    Future(() async {
      for (int note = minMidiNote; note <= maxMidiNote; note++) {
        final player = _getNextAvailablePlayer(note);
        final assetSource = _noteAssets[note];
        if (player == null || assetSource == null) continue;
        try {
          _playerVolumes[player] = 0.0;
          await player.setVolume(0.0);
          await player.play(assetSource);
          await Future.delayed(const Duration(milliseconds: 8));
          await player.stop();
        } catch (_) {}
        if (note % 12 == 0) {
          await Future.delayed(const Duration(milliseconds: 12));
        }
      }
      _log('Full keyboard warm-up completed');
    });
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
