class WebAudioEngine {
  bool get isSupported => false;
  bool get isReady => false;
  bool get isPreloading => false;
  int get preloadCount => 0;
  int get preloadTotal => 0;
  int get bufferCount => 0;
  int get activeSources => 0;
  int get playCount => 0;
  String? get lastError => null;
  double? get lastStartLatencyMs => null;

  Future<void> initialize({
    bool preloadAll = false,
    void Function(String message)? log,
  }) async {}

  Future<void> preloadRange({
    required int start,
    required int end,
    void Function(String message)? log,
  }) async {}

  Future<void> preloadAllNotes({void Function(String message)? log}) async {}

  Future<void> playNote(int midiNote, double volume) async {}
  Future<void> stopNote(int midiNote) async {}
  Future<void> stopAll() async {}
}
