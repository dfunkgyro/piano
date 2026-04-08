// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:js/js_util.dart' as js;

class WebMidiInputInfo {
  final String id;
  final String name;

  const WebMidiInputInfo({
    required this.id,
    required this.name,
  });
}

class WebMidiHost {
  dynamic _midiAccess;
  dynamic _connectedInput;
  dynamic _messageHandler;
  void Function(List<int> data)? _onMidi;
  void Function(String message)? _onStatus;

  bool get isSupported =>
      js_util.hasProperty(html.window.navigator, 'requestMIDIAccess');
  bool get isConnected => _connectedInput != null;
  String? get connectedInputId =>
      _connectedInput == null ? null : js_util.getProperty(_connectedInput, 'id') as String?;
  String? get connectedInputName => _connectedInput == null
      ? null
      : (js_util.getProperty(_connectedInput, 'name') as String?) ?? 'Web MIDI Input';

  void setOnMidi(void Function(List<int> data)? handler) {
    _onMidi = handler;
  }

  void setOnStatus(void Function(String message)? handler) {
    _onStatus = handler;
  }

  Future<void> _ensureAccess() async {
    if (_midiAccess != null || !isSupported) return;
    final promise = js_util.callMethod(
      html.window.navigator,
      'requestMIDIAccess',
      const [],
    );
    _midiAccess = await js_util.promiseToFuture<Object?>(promise);
  }

  Future<List<WebMidiInputInfo>> listInputs() async {
    if (!isSupported) return const [];
    await _ensureAccess();
    final inputs = js_util.getProperty(_midiAccess, 'inputs');
    final values = js_util.callMethod(inputs, 'values', const []);
    final results = <WebMidiInputInfo>[];
    while (true) {
      final next = js_util.callMethod(values, 'next', const []);
      final done = js_util.getProperty(next, 'done') as bool? ?? true;
      if (done) break;
      final input = js_util.getProperty(next, 'value');
      final id = (js_util.getProperty(input, 'id') as String?) ?? '';
      final name = (js_util.getProperty(input, 'name') as String?) ?? 'Web MIDI Input';
      if (id.isNotEmpty) {
        results.add(WebMidiInputInfo(id: id, name: name));
      }
    }
    return results;
  }

  Future<bool> connect(String inputId) async {
    if (!isSupported) {
      _onStatus?.call('Web MIDI not supported in this browser');
      return false;
    }
    await _ensureAccess();
    final inputs = await listInputs();
    final target = inputs.where((input) => input.id == inputId).toList();
    if (target.isEmpty) {
      _onStatus?.call('Web MIDI input not found');
      return false;
    }

    await disconnect();

    final inputMap = js_util.getProperty(_midiAccess, 'inputs');
    _connectedInput = js_util.callMethod(inputMap, 'get', [inputId]);
    if (_connectedInput == null) {
      _onStatus?.call('Web MIDI input not available');
      return false;
    }

    _messageHandler = js.allowInterop((event) {
      final data = js_util.getProperty(event, 'data');
      final length = js_util.getProperty(data, 'length') as int? ?? 0;
      final bytes = <int>[];
      for (var i = 0; i < length; i++) {
        bytes.add((js_util.getProperty(data, i) as num).toInt());
      }
      if (bytes.isNotEmpty) {
        _onMidi?.call(bytes);
      }
    });

    js_util.setProperty(_connectedInput, 'onmidimessage', _messageHandler);
    _onStatus?.call('Web MIDI connected: ${target.first.name}');
    return true;
  }

  Future<void> disconnect() async {
    if (_connectedInput != null) {
      js_util.setProperty(_connectedInput, 'onmidimessage', null);
    }
    _connectedInput = null;
    _messageHandler = null;
  }
}
