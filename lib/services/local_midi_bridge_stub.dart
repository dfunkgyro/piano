class LocalMidiBridgeClient {
  bool get isConnected => false;
  String? get lastError => null;

  void setOnMidi(void Function(List<int> data)? handler) {}
  void setOnStatus(void Function(String message)? handler) {}
  Future<bool> probe({String url = 'ws://127.0.0.1:8765/midi'}) async => false;
  Future<void> connect({String url = 'ws://127.0.0.1:8765/midi'}) async {}
  Future<void> disconnect() async {}
}
