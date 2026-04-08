// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';

class LocalMidiBridgeClient {
  html.WebSocket? _socket;
  void Function(List<int> data)? _onMidi;
  void Function(String message)? _onStatus;
  bool _isConnected = false;
  String? _lastError;
  StreamSubscription<html.Event>? _openSub;
  StreamSubscription<html.Event>? _closeSub;
  StreamSubscription<html.Event>? _errorSub;
  StreamSubscription<html.MessageEvent>? _msgSub;

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
      final response = await html.HttpRequest.request(
        _statusUrlFromSocket(url),
        method: 'GET',
      ).timeout(const Duration(seconds: 2));
      return response.status == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> connect({String url = 'ws://127.0.0.1:8765/midi'}) async {
    await disconnect();
    _lastError = null;
    try {
      _socket = html.WebSocket(_normalizeSocketUrl(url));
      _openSub = _socket!.onOpen.listen((_) {
        _isConnected = true;
        _onStatus?.call('Bridge connected');
      });
      _closeSub = _socket!.onClose.listen((_) {
        _isConnected = false;
        _onStatus?.call('Bridge disconnected');
      });
      _errorSub = _socket!.onError.listen((_) {
        _lastError = 'WebSocket error';
        _isConnected = false;
        _onStatus?.call('Bridge error');
      });
      _msgSub = _socket!.onMessage.listen((event) {
        try {
          final data = jsonDecode(event.data as String);
          if (data is Map && data['type'] == 'midi') {
            final list = data['data'];
            if (list is List) {
              _onMidi?.call(List<int>.from(list));
            }
          }
        } catch (e) {
          _lastError = 'Bridge parse error: $e';
          _onStatus?.call('Bridge parse error');
        }
      });
    } catch (e) {
      _lastError = 'Bridge connect error: $e';
      _isConnected = false;
      _onStatus?.call('Bridge connect error');
    }
  }

  Future<void> disconnect() async {
    await _openSub?.cancel();
    await _closeSub?.cancel();
    await _errorSub?.cancel();
    await _msgSub?.cancel();
    _openSub = null;
    _closeSub = null;
    _errorSub = null;
    _msgSub = null;
    _socket?.close();
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
