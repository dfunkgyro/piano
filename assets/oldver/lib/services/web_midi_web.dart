// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'package:js/js.dart';

class WebMidiAdapter {
  dynamic _access;
  final Set<String> _listeningIds = {};
  List<Map<String, String>> _inputs = [];

  void Function(List<int> data)? _onData;
  void Function()? _onStateChanged;

  bool get isSupported =>
      js_util.getProperty(html.window.navigator, 'requestMIDIAccess') != null;

  List<Map<String, String>> get inputs => List.from(_inputs);

  void setOnData(void Function(List<int> data)? handler) {
    _onData = handler;
  }

  void setOnStateChanged(void Function()? handler) {
    _onStateChanged = handler;
  }

  Future<void> requestAccess({Function(String message)? log}) async {
    final request =
        js_util.getProperty(html.window.navigator, 'requestMIDIAccess');
    if (request == null) {
      log?.call('Web MIDI not supported in this browser');
      return;
    }

    try {
      _access = await js_util
          .promiseToFuture(js_util.callMethod(
            html.window.navigator,
            'requestMIDIAccess',
            [],
          ))
          .timeout(const Duration(seconds: 5));
      _refreshInputs(log: log);
      js_util.setProperty(
        _access,
        'onstatechange',
        allowInterop((_) {
          _refreshInputs(log: log);
          _onStateChanged?.call();
        }),
      );
    } catch (e) {
      log?.call('Web MIDI access error: $e');
    }
  }

  void _refreshInputs({Function(String message)? log}) {
    if (_access == null) return;
    final inputsMap = js_util.getProperty(_access, 'inputs');
    if (inputsMap == null) return;

    final nextInputs = <Map<String, String>>[];

    js_util.callMethod(inputsMap, 'forEach', [
      allowInterop((input, key, map) {
        final id = js_util.getProperty(input, 'id')?.toString() ?? '';
        final name = js_util.getProperty(input, 'name')?.toString() ?? 'MIDI';
        if (id.isNotEmpty) {
          nextInputs.add({'id': id, 'name': name});
        }

        if (!_listeningIds.contains(id)) {
          _listeningIds.add(id);
          js_util.setProperty(
            input,
            'onmidimessage',
            allowInterop((event) {
              final data = js_util.getProperty(event, 'data');
              if (data == null) return;
              final length = js_util.getProperty(data, 'length') ?? 0;
              final bytes = <int>[];
              for (var i = 0; i < length; i++) {
                bytes.add(js_util.getProperty(data, i) as int);
              }
              _onData?.call(bytes);
            }),
          );
        }
      }),
    ]);

    _inputs = nextInputs;
    log?.call('Web MIDI inputs: ${_inputs.length}');
  }
}
