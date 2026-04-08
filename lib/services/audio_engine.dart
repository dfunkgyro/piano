import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioEngine {
  AudioEngine._();
  static final AudioEngine instance = AudioEngine._();

  double _volume = 0.8;
  bool _performanceMode = true;
  int _maxPolyphony = 24;
  bool _poolReady = false;
  final List<_Voice> _voices = [];
  int _roundRobin = 0;
  bool _warmupStarted = false;
  Duration _lateThreshold = const Duration(milliseconds: 150);

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
  }

  bool get performanceMode => _performanceMode;

  void setPerformanceMode(bool enabled) {
    _performanceMode = enabled;
  }

  Future<void> warmup() async {
    if (_warmupStarted) return;
    _warmupStarted = true;
    await _ensurePool();
    await _preloadAssets();
  }

  Future<void> playNote(
    int midiNote, {
    double velocity = 1.0,
    DateTime? eventTime,
  }) async {
    if (midiNote < 21 || midiNote > 108) return;
    if (eventTime != null &&
        DateTime.now().difference(eventTime) > _lateThreshold &&
        _performanceMode) {
      return;
    }
    await _ensurePool();
    final voice = _acquireVoice();
    if (voice == null) {
      return;
    }
    final asset = _noteToAsset(midiNote);
    await voice.player.stop();
    await voice.player.setReleaseMode(ReleaseMode.stop);
    await voice.player.setVolume((_volume * velocity).clamp(0.0, 1.0));
    await voice.player.play(AssetSource(asset));
  }

  String _noteToAsset(int midiNote) {
    const names = [
      'C',
      'Cs',
      'D',
      'Ds',
      'E',
      'F',
      'Fs',
      'G',
      'Gs',
      'A',
      'As',
      'B',
    ];
    final name = names[midiNote % 12];
    final octave = (midiNote ~/ 12) - 1;
    final padded = midiNote.toString().padLeft(3, '0');
    return 'sounds/note_${padded}_${name}${octave}.wav';
  }

  Future<void> _ensurePool() async {
    if (_poolReady) return;
    for (int i = 0; i < _maxPolyphony; i++) {
      final player = AudioPlayer();
      final voice = _Voice(player);
      voice.sub = player.onPlayerComplete.listen((_) {
        voice.busy = false;
      });
      _voices.add(voice);
    }
    _poolReady = true;
  }

  _Voice? _acquireVoice() {
    for (final voice in _voices) {
      if (!voice.busy) {
        voice.busy = true;
        return voice;
      }
    }
    if (_performanceMode) {
      return null;
    }
    final voice = _voices[_roundRobin % _voices.length];
    _roundRobin++;
    voice.busy = true;
    return voice;
  }

  Future<void> _preloadAssets() async {
    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final data = json.decode(manifest) as Map<String, dynamic>;
      final assets = data.keys
          .where((key) => key.startsWith('assets/sounds/'))
          .toList();
      for (final asset in assets) {
        await rootBundle.load(asset);
      }
    } catch (_) {}
  }
}

class _Voice {
  final AudioPlayer player;
  bool busy = false;
  StreamSubscription<void>? sub;
  _Voice(this.player);
}
