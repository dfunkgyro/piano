export 'local_midi_bridge_stub.dart'
    if (dart.library.io) 'local_midi_bridge_io.dart'
    if (dart.library.html) 'local_midi_bridge_web.dart';
