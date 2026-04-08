class WebAudioEngine {
  WebAudioEngine._();
  static final WebAudioEngine instance = WebAudioEngine._();

  bool get isSupported => false;
  int get bufferCount => 0;
  int get activeSources => 0;
  int get playCount => 0;
  int get preloadCount => 0;
  int get preloadTotal => 0;
  bool get isPreloading => false;
  bool get isReady => false;
  String? get lastError => null;
  double? get lastStartLatencyMs => null;

  void setVolume(double value) {}

  Future<void> initialize({
    bool preloadAll = false,
    void Function(String message)? log,
  }) async {}

  Future<void> warmup() async {}
  Future<void> unlock() async {}
  Future<bool> testSound() async => false;

  Future<void> preloadRange({
    required int start,
    required int end,
    void Function(int loaded, int total)? onProgress,
  }) async {}

  Future<void> preloadAllNotes({void Function(String message)? log}) async {}

  Future<void> playNote(int midiNote, {double velocity = 1.0}) async {}
  Future<void> stopNote(int midiNote) async {}
  Future<void> stopAll() async {}
}
