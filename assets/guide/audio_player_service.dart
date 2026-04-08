import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  // Enhanced pool for true polyphony with natural sustain
  final Map<int, List<AudioPlayer>> _playerPools = {};
  final Map<int, int> _currentPlayerIndex = {};
  final Map<int, DateTime> _noteStartTimes = {};
  final Map<int, double> _noteVelocities = {};

  // Advanced audio settings
  bool _sustainEnabled = false;
  double _reverbLevel = 0.3;
  double _currentLatency = 0.0;
  double _playbackRate = 1.0;
  double _masterVolume = 1.0;

  // Natural piano decay settings
  static const Duration shortTapThreshold = Duration(milliseconds: 150);
  static const Duration naturalDecay = Duration(milliseconds: 800);
  static const Duration sustainedDecay = Duration(seconds: 3);

  // Performance settings
  static const int minMidiNote = 21; // A0
  static const int maxMidiNote = 108; // C8
  static const int playersPerNote = 6; // Increased for rapid playing

  bool _isInitialized = false;
  final Set<int> _activeNotes = {};
  final Map<int, Timer?> _releaseTimers = {};
  final Map<int, AudioPlayer?> _currentPlayers = {};

  AudioPlayerService();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🎹 Initializing enhanced piano audio engine...');

      // Pre-create player pools for all 88 notes
      for (int note = minMidiNote; note <= maxMidiNote; note++) {
        _playerPools[note] = [];
        _currentPlayerIndex[note] = 0;

        // Create multiple players per note for polyphony
        for (int i = 0; i < playersPerNote; i++) {
          final player = AudioPlayer();
          await player.setReleaseMode(ReleaseMode.release);
          await player.setVolume(1.0);
          _playerPools[note]!.add(player);
        }
      }

      _isInitialized = true;
      debugPrint(
          '✅ Piano audio engine initialized: 88 notes × $playersPerNote players = ${88 * playersPerNote} total players');
    } catch (e) {
      debugPrint('❌ Error initializing audio player service: $e');
    }
  }

  AudioPlayer? _getNextAvailablePlayer(int note) {
    if (!_playerPools.containsKey(note)) return null;

    final pool = _playerPools[note]!;
    final currentIndex = _currentPlayerIndex[note]!;

    // Round-robin selection
    final player = pool[currentIndex];
    _currentPlayerIndex[note] = (currentIndex + 1) % pool.length;

    return player;
  }

  Future<void> playNote(int midiNote, double velocity,
      {bool fromMidi = true}) async {
    if (!_isInitialized) await initialize();

    if (midiNote < minMidiNote || midiNote > maxMidiNote) {
      debugPrint(
          '⚠️ Invalid MIDI note: $midiNote (valid range: $minMidiNote-$maxMidiNote)');
      return;
    }

    try {
      // Cancel any pending release for this note
      _releaseTimers[midiNote]?.cancel();
      _releaseTimers[midiNote] = null;

      // Get next available player
      final player = _getNextAvailablePlayer(midiNote);
      if (player == null) {
        debugPrint('⚠️ No player available for note $midiNote');
        return;
      }

      // Store player reference for this note
      _currentPlayers[midiNote] = player;

      // Apply latency adjustment
      final latencyDelay = _calculateLatencyDelay();
      if (latencyDelay > 0) {
        await Future.delayed(Duration(milliseconds: latencyDelay.toInt()));
      }

      await _playNoteImmediately(player, midiNote, velocity);

      // Track active notes with metadata
      _activeNotes.add(midiNote);
      _noteStartTimes[midiNote] = DateTime.now();
      _noteVelocities[midiNote] = velocity;
    } catch (e) {
      debugPrint('❌ Error playing note $midiNote: $e');
    }
  }

  Future<void> _playNoteImmediately(
      AudioPlayer player, int midiNote, double velocity) async {
    try {
      // Map MIDI note to note name
      final noteName = _getNoteNameFromMidi(midiNote);
      final assetPath =
          'sounds/note_${midiNote.toString().padLeft(3, '0')}_$noteName.wav';

      // Apply velocity curve for natural dynamics
      final dynamicVolume = _applyVelocityCurve(velocity);

      // Apply reverb simulation (volume modulation)
      final reverbAdjustedVolume = dynamicVolume * (1.0 + (_reverbLevel * 0.3));

      // Apply master volume
      final finalVolume =
          (reverbAdjustedVolume * _masterVolume).clamp(0.0, 2.0);
      await player.setVolume(finalVolume);

      // Apply playback rate for latency compensation
      await player.setPlaybackRate(_playbackRate);

      // Set release mode for natural piano decay
      await player.setReleaseMode(ReleaseMode.release);

      // Play the note
      await player.play(AssetSource(assetPath));

      debugPrint(
          '🎵 Playing: $noteName (MIDI $midiNote) at ${(velocity * 100).toInt()}% velocity, volume: ${(finalVolume * 100).toInt()}%');
    } catch (e) {
      debugPrint('❌ Error in _playNoteImmediately: $e');
    }
  }

  double _applyVelocityCurve(double velocity) {
    // Advanced piano-like velocity curve
    // Soft notes (0-0.3): More linear response for control
    // Medium notes (0.3-0.7): Slightly compressed for natural feel
    // Hard notes (0.7-1.0): More dynamic for fortissimo

    if (velocity < 0.3) {
      return velocity * 0.5 + 0.1; // Range: 0.1 - 0.25
    } else if (velocity < 0.7) {
      final normalized = (velocity - 0.3) / 0.4;
      return 0.25 + (normalized * normalized * 0.45); // Range: 0.25 - 0.70
    } else {
      final normalized = (velocity - 0.7) / 0.3;
      return 0.70 + (normalized * 0.3); // Range: 0.70 - 1.0
    }
  }

  Future<void> stopNote(int midiNote, {bool immediate = false}) async {
    try {
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
      debugPrint('❌ Error stopping note $midiNote: $e');
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
      debugPrint('⚠️ Error releasing note $midiNote: $e');
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
        debugPrint('⚠️ Error stopping note immediately: $e');
      }
    }

    _noteStartTimes.remove(midiNote);
    _noteVelocities.remove(midiNote);
    _currentPlayers.remove(midiNote);
  }

  Future<void> stopAllNotes({bool immediate = false}) async {
    try {
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
      debugPrint('❌ Error stopping all notes: $e');
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
    debugPrint('🎚️ Latency set to: ${_currentLatency.toStringAsFixed(1)}ms');
  }

  double _calculateLatencyDelay() {
    return _currentLatency > 0 ? _currentLatency : 0.0;
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

    debugPrint(
        '🎵 Playback rate adjusted to: ${_playbackRate.toStringAsFixed(3)}');
  }

  void setSustain(bool enabled) {
    _sustainEnabled = enabled;
    debugPrint('🎹 Sustain pedal: ${enabled ? "ON" : "OFF"}');

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
    debugPrint('📊 Reverb level: ${(_reverbLevel * 100).toInt()}%');
  }

  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 2.0);
    debugPrint(
        '📊 Master volume: ${(_masterVolume * 100).toInt()}%${_masterVolume > 1.0 ? " BOOST" : ""}');
  }

  Map<String, dynamic> getPerformanceStats() {
    return {
      'activeNotes': _activeNotes.length,
      'totalPlayers': 88 * playersPerNote,
      'sustainEnabled': _sustainEnabled,
      'reverbLevel': _reverbLevel,
      'masterVolume': _masterVolume,
      'latency': _currentLatency,
      'playbackRate': _playbackRate,
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

  void dispose() {
    for (var timer in _releaseTimers.values) {
      timer?.cancel();
    }
    _releaseTimers.clear();

    for (var pool in _playerPools.values) {
      for (var player in pool) {
        player.dispose();
      }
    }

    _playerPools.clear();
    _activeNotes.clear();
    _noteStartTimes.clear();
    _noteVelocities.clear();
    _currentPlayers.clear();
    _isInitialized = false;
  }
}
