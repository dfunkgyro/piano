import '../models/complete_songs_library.dart';

class TimingResult {
  final bool correctNote;
  final bool inWindow;
  final bool accepted;
  final double deltaMs;
  final int expectedNote;
  final int playedNote;

  TimingResult({
    required this.correctNote,
    required this.inWindow,
    required this.accepted,
    required this.deltaMs,
    required this.expectedNote,
    required this.playedNote,
  });
}

class SectionResult {
  final bool passed;
  final double accuracy;
  final int correct;
  final int total;

  SectionResult({
    required this.passed,
    required this.accuracy,
    required this.correct,
    required this.total,
  });
}

class PracticeEngine {
  final List<SongNote> notes;
  final int sectionSize;
  final double timingWindowMs;
  final double graceWindowMs;

  int _sectionStartIndex = 0;
  int _currentIndex = 0;
  int _correctInSection = 0;
  int _totalInSection = 0;
  double _tempoMultiplier = 1.0;
  double _sectionStartElapsedMs = 0.0;

  PracticeEngine({
    required this.notes,
    this.sectionSize = 16,
    this.timingWindowMs = 150.0,
    this.graceWindowMs = 420.0,
  });

  int get currentIndex => _currentIndex;
  int get sectionStartIndex => _sectionStartIndex;
  int get sectionEndIndex =>
      (_sectionStartIndex + sectionSize).clamp(0, notes.length);
  double get tempoMultiplier => _tempoMultiplier;
  double get sectionStartElapsedMs => _sectionStartElapsedMs;
  double get sectionBaseTime =>
      notes.isEmpty ? 0.0 : notes[_sectionStartIndex].time;

  double get sectionProgress {
    if (sectionEndIndex == sectionStartIndex) return 0.0;
    return (_currentIndex - sectionStartIndex) /
        (sectionEndIndex - sectionStartIndex);
  }

  int? get expectedNote {
    if (_currentIndex >= sectionEndIndex) return null;
    return notes[_currentIndex].note;
  }

  void startSection({
    required double elapsedMs,
    required double tempoMultiplier,
  }) {
    _tempoMultiplier = tempoMultiplier.clamp(0.1, 3.0);
    _sectionStartElapsedMs = elapsedMs;
    _currentIndex = _sectionStartIndex;
    _correctInSection = 0;
    _totalInSection = 0;
  }

  void setTempo(double tempoMultiplier) {
    _tempoMultiplier = tempoMultiplier.clamp(0.1, 3.0);
  }

  bool seekToTime(double songTimeSeconds) {
    if (notes.isEmpty) return false;
    int index = notes.indexWhere((n) => n.time >= songTimeSeconds);
    if (index < 0) index = notes.length - 1;
    final half = sectionSize ~/ 2;
    _sectionStartIndex = (index - half).clamp(0, notes.length - 1);
    _currentIndex = _sectionStartIndex;
    _correctInSection = 0;
    _totalInSection = 0;
    return true;
  }

  TimingResult? registerNote({
    required int note,
    required double elapsedMs,
  }) {
    if (_currentIndex >= sectionEndIndex) return null;

    final expected = notes[_currentIndex];
    final sectionBaseTime = notes[_sectionStartIndex].time;
    final expectedMs =
        ((expected.time - sectionBaseTime) * 1000) / _tempoMultiplier;
    final actualMs = elapsedMs - _sectionStartElapsedMs;
    final deltaMs = actualMs - expectedMs;
    final inWindow = deltaMs.abs() <= timingWindowMs;
    final withinGrace = deltaMs.abs() <= graceWindowMs;

    bool correctNote = note == expected.note;
    _totalInSection++;
    if (correctNote && withinGrace) {
      _correctInSection++;
      _currentIndex++;
    }

    return TimingResult(
      correctNote: correctNote,
      inWindow: inWindow,
      accepted: correctNote && withinGrace,
      deltaMs: deltaMs,
      expectedNote: expected.note,
      playedNote: note,
    );
  }

  SectionResult? completeSectionIfNeeded() {
    if (_currentIndex < sectionEndIndex) return null;

    final accuracy =
        _totalInSection == 0 ? 0.0 : _correctInSection / _totalInSection;
    final passed = accuracy >= 0.85;

    if (passed) {
      _sectionStartIndex = sectionEndIndex;
    }

    return SectionResult(
      passed: passed,
      accuracy: accuracy,
      correct: _correctInSection,
      total: _totalInSection,
    );
  }
}
