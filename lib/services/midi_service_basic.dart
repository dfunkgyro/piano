import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';

class MidiEvent {
  final int status;
  final int note;
  final int velocity;
  MidiEvent(this.status, this.note, this.velocity);
}

class MidiServiceBasic {
  MidiServiceBasic._();
  static final MidiServiceBasic instance = MidiServiceBasic._();

  final MidiCommand _midi = MidiCommand();
  StreamSubscription<MidiPacket>? _sub;
  final StreamController<MidiEvent> _controller =
      StreamController<MidiEvent>.broadcast();

  Stream<MidiEvent> get events => _controller.stream;

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await _midi.startScanningForBluetoothDevices();
      _sub = _midi.onMidiDataReceived?.listen((packet) {
        if (packet.data.length < 3) return;
        final status = packet.data[0];
        final note = packet.data[1];
        final velocity = packet.data[2];
        _controller.add(MidiEvent(status, note, velocity));
      });
    } catch (_) {}
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
