import 'dart:async';
import 'package:flutter/foundation.dart';
import 'aws_service.dart';

class EnhancedAITutorService {
  final List<Map<String, String>> _conversationHistory = [];

  // Performance tracking
  final List<int> _playedNotes = [];
  final Map<int, int> _noteFrequency = {};
  final Map<int, List<int>> _noteMistakes =
      {}; // Note -> list of wrong notes played
  DateTime? _sessionStartTime;
  int _totalNotesPlayed = 0;
  int _consecutiveCorrectNotes = 0;
  String _lastSuggestionType = '';
  Timer? _proactiveTimer;

  // Song teaching
  String? _currentSongId;
  List<int> _currentSongNotes = [];
  int _currentNoteIndex = 0;
  final Map<String, double> _songMastery = {};

  // Callbacks
  Function(String)? onProactiveSuggestion;
  Function(String)? onEncouragement;
  Function(String)? onTechniqueAdvice;

  EnhancedAITutorService() {
    _conversationHistory.add({
      'role': 'system',
      'content': '''You are an expert piano teacher with deep knowledge of:
- Classical music repertoire (Mozart, Beethoven, Bach, Chopin, etc.)
- Jazz, pop, film, and contemporary piano styles
- Piano technique and fingering
- Music theory and sight-reading
- Practice strategies and motivation
- MIDI technology and setup

Teaching approach:
- Break complex pieces into learnable sections
- Provide specific, actionable feedback
- Adapt to student's skill level
- Use positive reinforcement
- Explain musical concepts clearly
- Give measure-by-measure guidance when teaching songs
 - Emphasize classical phrasing, articulation, and dynamics when relevant

When teaching a song:
- Start with hand position and fingering
- Break into 4-8 measure sections
- Explain the musical structure
- Provide practice tips for difficult passages
- Suggest tempo and dynamics
- Track progress through the piece'''
    });

    _sessionStartTime = DateTime.now();
    _startProactiveMonitoring();
  }

  void _startProactiveMonitoring() {
    _proactiveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _evaluateTeachingOpportunity();
    });
  }

  Future<void> _evaluateTeachingOpportunity() async {
    if (_totalNotesPlayed < 10) return;

    final sessionDuration = DateTime.now().difference(_sessionStartTime!);

    // Analyze patterns and provide suggestions
    if (_noteMistakes.isNotEmpty && _lastSuggestionType != 'mistakes') {
      _provideMistakeAnalysis();
      _lastSuggestionType = 'mistakes';
    } else if (sessionDuration.inMinutes > 5 &&
        _lastSuggestionType != 'break') {
      _provideTip('🎯 Time for a quick break! Shake your hands and stretch.');
      _lastSuggestionType = 'break';
    } else if (_consecutiveCorrectNotes > 20 &&
        _lastSuggestionType != 'praise') {
      _provideEncouragement(
          '🌟 Excellent! ${_consecutiveCorrectNotes} notes in a row!');
      _lastSuggestionType = 'praise';
    }
  }

  void _provideMistakeAnalysis() {
    final mostMissedNote = _noteMistakes.entries
        .reduce((a, b) => a.value.length > b.value.length ? a : b);

    final noteName = _getNoteNameFromMidi(mostMissedNote.key);
    _provideTip(
        '💡 You\'re having trouble with $noteName. Try practicing it slowly in isolation.');
  }

  void trackNotePlay(int midiNote, double velocity) {
    _playedNotes.add(midiNote);
    _noteFrequency[midiNote] = (_noteFrequency[midiNote] ?? 0) + 1;
    _totalNotesPlayed++;
    _consecutiveCorrectNotes++;

    // Check if this is the expected note in current song
    if (_currentSongNotes.isNotEmpty &&
        _currentNoteIndex < _currentSongNotes.length) {
      final expectedNote = _currentSongNotes[_currentNoteIndex];
      if (midiNote == expectedNote) {
        _currentNoteIndex++;
      } else {
        _noteMistakes[expectedNote] = [
          ...(_noteMistakes[expectedNote] ?? []),
          midiNote
        ];
        _consecutiveCorrectNotes = 0;
      }
    }

    // Milestones
    if (_totalNotesPlayed == 100) {
      _provideEncouragement('🎉 100 notes! You\'re warming up nicely!');
    } else if (_totalNotesPlayed == 500) {
      _provideEncouragement('🎵 500 notes! Your dedication is impressive!');
    }
  }

  void trackMistake(int expectedNote, int playedNote) {
    _noteMistakes[expectedNote] = [
      ...(_noteMistakes[expectedNote] ?? []),
      playedNote
    ];
    _consecutiveCorrectNotes = 0;
  }

  // ============================================
  // SONG TEACHING
  // ============================================

  Future<String> startTeachingSong(
    String songId,
    String title,
    String composer,
    List<int> notes,
  ) async {
    _currentSongId = songId;
    _currentSongNotes = notes;
    _currentNoteIndex = 0;

    final message = await getResponse(
      '''I want to learn "$title" by $composer. The piece has ${notes.length} notes.
      
Please provide:
1. A brief introduction to this piece
2. Starting hand position
3. Key signature and time signature
4. First section (measures 1-4) breakdown with fingering
5. Practice strategy for this piece

Keep it structured and actionable.''',
      addToHistory: true,
    );

    return message;
  }

  Future<String> getNextSectionGuidance() async {
    if (_currentNoteIndex >= _currentSongNotes.length) {
      return '🎉 You\'ve completed the entire piece! Great job!';
    }

    final progress =
        (_currentNoteIndex / _currentSongNotes.length * 100).toInt();
    final remaining = _currentSongNotes.length - _currentNoteIndex;

    final message = await getResponse(
      '''I'm at note $_currentNoteIndex out of ${_currentSongNotes.length} ($progress% complete).
$remaining notes remaining.

Mistakes made so far: ${_noteMistakes.length} different notes.
${_noteMistakes.isNotEmpty ? 'Most difficult note: ${_getNoteNameFromMidi(_noteMistakes.entries.first.key)}' : ''}

Please give me guidance for the next section:
1. What should I focus on?
2. Any fingering tips?
3. How to practice this section?
4. When to move to the next section?

Keep it brief and specific.''',
      addToHistory: true,
    );

    return message;
  }

  Future<String> analyzeSongPerformance(double accuracy, int mistakes) async {
    final mastery = _calculateMastery(accuracy, mistakes);

    if (_currentSongId != null) {
      _songMastery[_currentSongId!] = mastery;
    }

    final message = await getResponse(
      '''I just finished practicing the song. Here's my performance:
- Accuracy: ${accuracy.toStringAsFixed(1)}%
- Mistakes: $mistakes
- Notes played correctly: ${_currentNoteIndex - mistakes}
- Total notes: ${_currentSongNotes.length}

Most difficult notes: ${_getMostDifficultNotes()}

Please provide:
1. Performance assessment
2. Specific areas to improve
3. Practice exercises for weak spots
4. Should I move to the next song or practice more?
5. Estimated days until mastery at current rate

Be honest but encouraging.''',
      addToHistory: true,
    );

    return message;
  }

  double _calculateMastery(double accuracy, int mistakes) {
    final accuracyScore = accuracy / 100.0;
    final mistakeScore =
        1.0 - (mistakes / _currentSongNotes.length.clamp(1, 999));
    final progressScore =
        _currentNoteIndex / _currentSongNotes.length.clamp(1, 999);

    return (accuracyScore * 0.4 + mistakeScore * 0.3 + progressScore * 0.3) *
        100;
  }

  String _getMostDifficultNotes() {
    if (_noteMistakes.isEmpty) return 'None! Perfect performance!';

    final sorted = _noteMistakes.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return sorted
        .take(3)
        .map((e) => '${_getNoteNameFromMidi(e.key)} (${e.value.length} errors)')
        .join(', ');
  }

  // ============================================
  // TECHNIQUE COACHING
  // ============================================

  Future<String> getTechniqueAdvice(String technique) async {
    final message = await getResponse(
      '''I want to improve my $technique technique on piano.

Please provide:
1. Explanation of proper $technique technique
2. Common mistakes to avoid
3. Step-by-step practice exercises
4. Tips for mastering this technique
5. Timeline for improvement

Make it practical and detailed.''',
      addToHistory: true,
    );

    return message;
  }

  Future<String> getFingeringAdvice(List<int> noteSequence) async {
    final noteNames = noteSequence.map(_getNoteNameFromMidi).toList();

    final message = await getResponse(
      '''What's the best fingering for this note sequence: ${noteNames.join(' → ')}?

Please provide:
1. Recommended finger numbers (1-5)
2. Explanation of why this fingering works
3. Alternative fingerings if applicable
4. Common fingering mistakes to avoid

Be specific and clear.''',
      addToHistory: true,
    );

    return message;
  }

  // ============================================
  // GENERAL AI RESPONSES
  // ============================================

  Future<String> getWelcomeMessage() async {
    return await getResponse(
      '''Give me an enthusiastic welcome message as my piano teacher. 
Mention that you can:
- Teach complete classical pieces note-by-note
- Provide technique coaching
- Analyze my performance
- Give personalized practice strategies
Keep it warm and under 50 words.''',
      addToHistory: false,
    );
  }

  Future<String> getResponse(String userMessage,
      {bool addToHistory = true}) async {
    if (addToHistory) {
      _conversationHistory.add({
        'role': 'user',
        'content': userMessage,
      });
    }

    try {
      final assistantMessage = await AwsService.instance.aiChat(
        messages: _conversationHistory,
      );

      if (assistantMessage == null || assistantMessage.isEmpty) {
        return 'Sorry, I encountered an error. Please try again.';
      }

      if (addToHistory) {
        _conversationHistory.add({
          'role': 'assistant',
          'content': assistantMessage,
        });
      }

      return assistantMessage;
    } catch (e) {
      debugPrint('Error calling AWS AI: $e');
      return 'Sorry, couldn\'t connect to AI service. Check your internet connection.';
    }
  }

  void _provideTip(String tip) {
    onProactiveSuggestion?.call(tip);
  }

  void _provideEncouragement(String encouragement) {
    onEncouragement?.call(encouragement);
  }

  String _getNoteNameFromMidi(int midiNote) {
    const noteNames = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B'
    ];
    final octave = (midiNote / 12).floor() - 1;
    final noteName = noteNames[midiNote % 12];
    return '$noteName$octave';
  }

  Map<String, dynamic> getSessionStats() {
    final duration = DateTime.now().difference(_sessionStartTime!);

    return {
      'duration_minutes': duration.inMinutes,
      'total_notes': _totalNotesPlayed,
      'unique_notes': _noteFrequency.length,
      'notes_per_minute': _totalNotesPlayed / duration.inMinutes.clamp(1, 999),
      'consecutive_correct': _consecutiveCorrectNotes,
      'mistakes': _noteMistakes.length,
      'song_progress': _currentSongNotes.isEmpty
          ? 0
          : (_currentNoteIndex / _currentSongNotes.length * 100).toInt(),
    };
  }

  void resetSession() {
    _playedNotes.clear();
    _noteFrequency.clear();
    _noteMistakes.clear();
    _sessionStartTime = DateTime.now();
    _totalNotesPlayed = 0;
    _consecutiveCorrectNotes = 0;
    _lastSuggestionType = '';
  }

  void resetSongProgress() {
    _currentNoteIndex = 0;
    _noteMistakes.clear();
  }

  int get totalNotesPlayed => _totalNotesPlayed;
  List<Map<String, String>> get conversationHistory => _conversationHistory;

  void dispose() {
    _proactiveTimer?.cancel();
  }
}
