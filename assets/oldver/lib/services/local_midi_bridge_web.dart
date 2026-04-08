// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

class LocalMidiBridgeClient {
  html.WebSocket? _socket;
  void Function(List<int> data)? _onMidi;
  bool _isConnected = false;
  String? _lastError;

  bool get isConnected => _isConnected;
  String? get lastError => _lastError;

  void setOnMidi(void Function(List<int> data)? handler) {
    _onMidi = handler;
  }

  Future<void> connect() async {
    _lastError = null;
    try {
      _socket = html.WebSocket('ws://127.0.0.1:8765');
      _socket!.onOpen.listen((_) {
        _isConnected = true;
      });
      _socket!.onClose.listen((_) {
        _isConnected = false;
      });
      _socket!.onError.listen((event) {
        _lastError = 'WebSocket error';
        _isConnected = false;
      });
      _socket!.onMessage.listen((event) {
        try {
          final data = jsonDecode(event.data as String);
          if (data is Map && data['type'] == 'midi') {
            final list = data['data'];
            if (list is List) {
              _onMidi?.call(List<int>.from(list));
            }
          }
        } catch (e) {
          _lastError = 'WebSocket parse error: $e';
        }
      });
    } catch (e) {
      _lastError = 'WebSocket connect error: $e';
      _isConnected = false;
    }
  }

  Future<void> disconnect() async {
    _socket?.close();
    _socket = null;
    _isConnected = false;
  }
}
