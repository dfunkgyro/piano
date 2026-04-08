import '../models/lesson_note.dart';
import '../models/song.dart';

class LessonGenerator {
  static List<LessonNote> generate(Song song) {
    final tonic = _parseTonic(song.keySignature);
    final baseMidi = 60 + tonic; // C4 + tonic
    final scale = _majorScale(baseMidi);
    final bpm = song.bpm.clamp(30, 180);
    final secondsPerBeat = 60.0 / bpm;
    final notes = <LessonNote>[];
    double time = 0.0;

    if (song.lessonType == LessonType.chord) {
      final intervals = song.chordIntervals ?? [0, 4, 7, 11];
      if (song.arpeggio) {
        for (int i = 0; i < 32; i++) {
          final interval = intervals[i % intervals.length];
          notes.add(LessonNote(
            midiNote: baseMidi + interval,
            time: time,
            duration: secondsPerBeat * 0.5,
          ));
          time += secondsPerBeat * 0.5;
        }
      } else {
        const beatsPerChord = 2;
        for (int beat = 0; beat < 16; beat += beatsPerChord) {
          time = beat * secondsPerBeat;
          for (final interval in intervals) {
            notes.add(LessonNote(
              midiNote: baseMidi + interval,
              time: time,
              duration: secondsPerBeat * 1.8,
            ));
          }
        }
      }
      return notes;
    }

    // 4 bars of 4/4 = 16 beats, using 8th notes = 32 notes
    for (int i = 0; i < 32; i++) {
      final note = scale[i % scale.length];
      notes.add(LessonNote(
        midiNote: note,
        time: time,
        duration: secondsPerBeat * 0.5,
      ));
      time += secondsPerBeat * 0.5;
    }

    return notes;
  }

  static int _parseTonic(String key) {
    if (key.isEmpty) return 0;
    final raw = key.split(' ').first.trim();
    final normalized = raw.replaceAll('♭', 'b').replaceAll('♯', '#');
    final base = normalized[0].toUpperCase();
    final map = <String, int>{
      'C': 0,
      'D': 2,
      'E': 4,
      'F': 5,
      'G': 7,
      'A': 9,
      'B': 11,
    };
    int semitone = map[base] ?? 0;
    if (normalized.length > 1) {
      final acc = normalized[1];
      if (acc == '#') semitone += 1;
      if (acc == 'b' || acc == 'B') semitone -= 1;
    }
    semitone %= 12;
    if (semitone < 0) semitone += 12;
    return semitone;
  }

  static List<int> _majorScale(int root) {
    const steps = [0, 2, 4, 5, 7, 9, 11, 12];
    return steps.map((s) => root + s).toList();
  }
}
