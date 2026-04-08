import 'package:flutter/foundation.dart';
import '../utils/note_state_controller.dart';

class LiveMidiNoteService {
  LiveMidiNoteService._();
  static final LiveMidiNoteService instance = LiveMidiNoteService._();

  final NoteStateController _controller = NoteStateController();

  ValueNotifier<NoteState> get notifier => _controller.notifier;

  void noteOn(int note, double velocity) {
    _controller.noteOn(note, velocity);
  }

  void noteOff(int note) {
    _controller.noteOff(note);
  }

  void clear() {
    _controller.clear();
  }
}
