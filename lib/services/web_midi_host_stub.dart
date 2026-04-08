class WebMidiInputInfo {
  final String id;
  final String name;

  const WebMidiInputInfo({
    required this.id,
    required this.name,
  });
}

class WebMidiHost {
  void Function(List<int> data)? _onMidi;
  void Function(String message)? _onStatus;

  bool get isSupported => false;
  bool get isConnected => false;
  String? get connectedInputId => null;
  String? get connectedInputName => null;

  void setOnMidi(void Function(List<int> data)? handler) {
    _onMidi = handler;
  }

  void setOnStatus(void Function(String message)? handler) {
    _onStatus = handler;
  }

  Future<List<WebMidiInputInfo>> listInputs() async => const [];

  Future<bool> connect(String inputId) async {
    _onStatus?.call('Web MIDI is not supported on this platform');
    return false;
  }

  Future<void> disconnect() async {}
}
