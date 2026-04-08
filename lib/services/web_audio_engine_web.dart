// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:web_audio' as audio;
import 'dart:typed_data';

class WebAudioEngine {
  WebAudioEngine._();
  static final WebAudioEngine instance = WebAudioEngine._();

  audio.AudioContext? _ctx;
  final Map<int, audio.AudioBuffer> _buffers = {};
  final Map<int, audio.AudioBufferSourceNode> _active = {};
  int _playCount = 0;
  int _preloadCount = 0;
  int _preloadTotal = 0;
  bool _preloading = false;
  bool _ready = false;
  String? _lastError;
  double? _lastStartLatencyMs;
  double _volume = 0.9;

  bool get isSupported => audio.AudioContext.supported;
  int get bufferCount => _buffers.length;
  int get activeSources => _active.length;
  int get playCount => _playCount;
  int get preloadCount => _preloadCount;
  int get preloadTotal => _preloadTotal;
  bool get isPreloading => _preloading;
  bool get isReady => _ready;
  String? get lastError => _lastError;
  double? get lastStartLatencyMs => _lastStartLatencyMs;

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
  }

  Future<void> initialize({
    bool preloadAll = false,
    void Function(String message)? log,
  }) async {
    if (!isSupported) {
      log?.call('WebAudio not supported');
      return;
    }
    _ctx ??= audio.AudioContext();
    await _ctx!.resume();
    _ready = true;
    if (preloadAll) {
      await preloadAllNotes(log: log);
    }
  }

  Future<void> warmup() async {
    await initialize(preloadAll: false);
  }

  Future<void> unlock() async {
    await initialize(preloadAll: false);
  }

  Future<bool> testSound() async {
    try {
      await playNote(60, velocity: 0.6);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> preloadRange({
    required int start,
    required int end,
    void Function(int loaded, int total)? onProgress,
  }) async {
    if (!isSupported) return;
    _preloadTotal = (end - start + 1).clamp(0, 88);
    _preloadCount = 0;
    _preloading = true;
    for (var note = start; note <= end; note++) {
      await _loadBuffer(note);
      _preloadCount++;
      onProgress?.call(_preloadCount, _preloadTotal);
    }
    _preloading = false;
  }

  Future<void> preloadAllNotes({void Function(String message)? log}) async {
    if (!isSupported) return;
    if (_preloading) return;
    _preloading = true;
    _preloadTotal = 88;
    _preloadCount = 0;
    log?.call('WebAudio preload all notes...');
    for (var note = 21; note <= 108; note++) {
      await _loadBuffer(note);
      _preloadCount++;
    }
    _preloading = false;
    log?.call('WebAudio preload complete (${_buffers.length} buffers)');
  }

  Future<void> playNote(int midiNote, {double velocity = 1.0}) async {
    if (!isSupported) return;
    if (midiNote < 21 || midiNote > 108) return;
    _ctx ??= audio.AudioContext();
    await _ctx!.resume();
    final start = DateTime.now();
    try {
      final buffer = await _loadBuffer(midiNote);
      final source = _ctx!.createBufferSource();
      source.buffer = buffer;
      final gain = _ctx!.createGain();
      gain.gain?.value = (_volume * velocity).clamp(0.0, 2.0);
      source.connectNode(gain);
      final dest = _ctx!.destination;
      if (dest != null) {
        gain.connectNode(dest);
      }
      source.start(0);
      _active[midiNote]?.stop(0);
      _active[midiNote] = source;
      _playCount++;
      _lastStartLatencyMs =
          DateTime.now().difference(start).inMilliseconds.toDouble();
    } catch (e) {
      _lastError = e.toString();
    }
  }

  Future<void> stopNote(int midiNote) async {
    final source = _active.remove(midiNote);
    try {
      source?.stop(0);
    } catch (_) {}
  }

  Future<void> stopAll() async {
    for (final entry in _active.entries) {
      try {
        entry.value.stop(0);
      } catch (_) {}
    }
    _active.clear();
  }

  Future<audio.AudioBuffer> _loadBuffer(int midiNote) async {
    final existing = _buffers[midiNote];
    if (existing != null) return existing;

    final urls = <String>[
      _buildAssetUrl(midiNote, legacy: true),
      _buildAssetUrl(midiNote, legacy: false),
    ];

    Object? lastErr;
    for (final url in urls) {
      try {
        final req = await html.HttpRequest.request(
          url,
          responseType: 'arraybuffer',
        );
        final data = req.response as ByteBuffer;
        final buffer = await _ctx!.decodeAudioData(data);
        _buffers[midiNote] = buffer;
        return buffer;
      } catch (e) {
        lastErr = e;
      }
    }

    throw lastErr ?? Exception('Failed to load buffer for $midiNote');
  }

  String _buildAssetUrl(int midiNote, {required bool legacy}) {
    final name = _noteName(midiNote);
    final padded = midiNote.toString().padLeft(3, '0');
    if (legacy) {
      // Flutter web assets are served under /assets/assets/...
      return 'assets/assets/sounds/note_${padded}_$name.wav';
    }
    return 'assets/sounds/note_${padded}_$name.wav';
  }

  String _noteName(int midiNote) {
    const noteNames = [
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
      'B'
    ];
    final octave = (midiNote / 12).floor() - 1;
    final noteName = noteNames[midiNote % 12];
    return '$noteName$octave';
  }
}
