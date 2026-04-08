import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class QwertyMidiController {
  QwertyMidiController({
    this.baseNote = 60,
  });

  int baseNote;
  int octaveOffset = 0;
  bool enabled = false;

  final Map<LogicalKeyboardKey, int> _activeNotes = {};

  static final Map<LogicalKeyboardKey, int> _noteMap = {
    LogicalKeyboardKey.keyA: 0, // C
    LogicalKeyboardKey.keyW: 1, // C#
    LogicalKeyboardKey.keyS: 2, // D
    LogicalKeyboardKey.keyE: 3, // D#
    LogicalKeyboardKey.keyD: 4, // E
    LogicalKeyboardKey.keyF: 5, // F
    LogicalKeyboardKey.keyT: 6, // F#
    LogicalKeyboardKey.keyG: 7, // G
    LogicalKeyboardKey.keyY: 8, // G#
    LogicalKeyboardKey.keyH: 9, // A
    LogicalKeyboardKey.keyU: 10, // A#
    LogicalKeyboardKey.keyJ: 11, // B
    LogicalKeyboardKey.keyK: 12, // C
    LogicalKeyboardKey.keyO: 13, // C#
    LogicalKeyboardKey.keyL: 14, // D
    LogicalKeyboardKey.keyP: 15, // D#
    LogicalKeyboardKey.semicolon: 16, // E
  };

  KeyEventResult handleEvent(
    KeyEvent event, {
    required void Function(int note, double velocity) onNoteOn,
    required void Function(int note) onNoteOff,
  }) {
    if (!enabled) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (event is KeyDownEvent) {
      if (_handleOctaveShift(key)) {
        return KeyEventResult.handled;
      }

      if (_noteMap.containsKey(key)) {
        if (_activeNotes.containsKey(key)) {
          return KeyEventResult.handled;
        }
        final note = _resolveNote(_noteMap[key]!);
        if (note == null) return KeyEventResult.handled;
        _activeNotes[key] = note;
        final velocity = _resolveVelocity();
        onNoteOn(note, velocity);
        return KeyEventResult.handled;
      }
    }

    if (event is KeyUpEvent) {
      if (_noteMap.containsKey(key)) {
        final note = _activeNotes.remove(key);
        if (note != null) {
          onNoteOff(note);
        }
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  bool _handleOctaveShift(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.keyZ) {
      octaveOffset = (octaveOffset - 1).clamp(-3, 3);
      return true;
    }
    if (key == LogicalKeyboardKey.keyX) {
      octaveOffset = (octaveOffset + 1).clamp(-3, 3);
      return true;
    }
    return false;
  }

  int? _resolveNote(int semitoneOffset) {
    final note = baseNote + (octaveOffset * 12) + semitoneOffset;
    if (note < 21 || note > 108) return null;
    return note;
  }

  double _resolveVelocity() {
    if (HardwareKeyboard.instance.isShiftPressed) {
      return 1.0;
    }
    if (HardwareKeyboard.instance.isAltPressed) {
      return 0.5;
    }
    return 0.8;
  }
}
