class LocalMidiBridgeClient {
  bool get isConnected => false;
  String? get lastError => null;

  void setOnMidi(void Function(List<int> data)? handler) {}
  Future<void> connect() async {}
  Future<void> disconnect() async {}
}
