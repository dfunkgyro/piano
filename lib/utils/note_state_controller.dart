import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

class NoteState {
  final UnmodifiableSetView<int> activeNotes;
  final UnmodifiableMapView<int, double> velocities;

  const NoteState(this.activeNotes, this.velocities);

  int get activeCount => activeNotes.length;
}

class NoteStateController {
  final Set<int> _activeNotes = {};
  final Map<int, double> _velocities = {};
  final ValueNotifier<NoteState> notifier;

  Timer? _emitTimer;
  bool _dirty = false;

  NoteStateController()
      : notifier = ValueNotifier<NoteState>(
          NoteState(
            UnmodifiableSetView<int>({}),
            UnmodifiableMapView<int, double>({}),
          ),
        );

  void noteOn(int note, double velocity) {
    _activeNotes.add(note);
    _velocities[note] = velocity;
    _scheduleEmit();
  }

  void noteOff(int note) {
    _activeNotes.remove(note);
    _velocities.remove(note);
    _scheduleEmit();
  }

  void clear() {
    if (_activeNotes.isEmpty && _velocities.isEmpty) return;
    _activeNotes.clear();
    _velocities.clear();
    _scheduleEmit();
  }

  void _scheduleEmit() {
    _dirty = true;
    if (_emitTimer != null) return;

    _emitTimer = Timer(const Duration(milliseconds: 16), () {
      _emitTimer = null;
      if (!_dirty) return;
      _dirty = false;

      notifier.value = NoteState(
        UnmodifiableSetView<int>(Set<int>.from(_activeNotes)),
        UnmodifiableMapView<int, double>(Map<int, double>.from(_velocities)),
      );
    });
  }

  void dispose() {
    _emitTimer?.cancel();
    notifier.dispose();
  }
}
