class WebMidiAdapter {
  bool get isSupported => false;

  List<Map<String, String>> get inputs => const [];

  Future<void> requestAccess({Function(String message)? log}) async {
    log?.call('Web MIDI not supported on this platform');
  }

  void setOnData(void Function(List<int> data)? handler) {}
  void setOnStateChanged(void Function()? handler) {}
}
