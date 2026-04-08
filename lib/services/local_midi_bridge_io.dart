import 'dart:async';
import 'dart:convert';
import 'dart:io';

class LocalMidiBridgeClient {
  WebSocket? _socket;
  void Function(List<int> data)? _onMidi;
  void Function(String message)? _onStatus;
  bool _isConnected = false;
  String? _lastError;
  StreamSubscription? _sub;

  bool get isConnected => _isConnected;
  String? get lastError => _lastError;

  void setOnMidi(void Function(List<int> data)? handler) {
    _onMidi = handler;
  }

  void setOnStatus(void Function(String message)? handler) {
    _onStatus = handler;
  }

  Future<bool> probe({String url = 'ws://127.0.0.1:8765/midi'}) async {
    try {
      final request = await HttpClient()
          .getUrl(Uri.parse(_statusUrlFromSocket(url)))
          .timeout(const Duration(seconds: 2));
      final response = await request.close().timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> connect({String url = 'ws://127.0.0.1:8765/midi'}) async {
    await disconnect();
    _lastError = null;
    try {
      _socket = await WebSocket.connect(_normalizeSocketUrl(url));
      _isConnected = true;
      _onStatus?.call('Bridge connected');
      _sub = _socket!.listen(
        (event) {
          try {
            final data = jsonDecode(event as String);
            if (data is Map && data['type'] == 'midi' && data['data'] is List) {
              _onMidi?.call(List<int>.from(data['data'] as List));
            }
          } catch (e) {
            _lastError = 'Bridge parse error: $e';
            _onStatus?.call(_lastError!);
          }
        },
        onDone: () {
          _isConnected = false;
          _onStatus?.call('Bridge disconnected');
        },
        onError: (Object error) {
          _lastError = 'Bridge socket error: $error';
          _isConnected = false;
          _onStatus?.call(_lastError!);
        },
        cancelOnError: true,
      );
    } catch (e) {
      _lastError = 'Bridge connect error: $e';
      _isConnected = false;
      _onStatus?.call(_lastError!);
    }
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    await _socket?.close();
    _socket = null;
    _isConnected = false;
  }

  String _normalizeSocketUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return 'ws://127.0.0.1:8765/midi';
    return trimmed.endsWith('/midi') ? trimmed : '$trimmed/midi';
  }

  String _statusUrlFromSocket(String url) {
    final socketUrl = _normalizeSocketUrl(url);
    return socketUrl.replaceFirst('ws://', 'http://').replaceFirst('/midi', '/status');
  }
}
