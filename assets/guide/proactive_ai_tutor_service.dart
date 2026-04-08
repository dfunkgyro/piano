import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ProactiveAITutorService {
  static String? _apiKey;
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  final List<Map<String, String>> _conversationHistory = [];

  // Performance tracking for proactive suggestions
  final List<int> _playedNotes = [];
  final Map<int, int> _noteFrequency = {};
  DateTime? _sessionStartTime;
  int _totalNotesPlayed = 0;
  int _consecutiveCorrectNotes = 0;
  String _lastSuggestionType = '';
  Timer? _proactiveTimer;

  // Callbacks for proactive teaching
  Function(String)? onProactiveSuggestion;
  Function(String)? onEncouragement;
  Function(String)? onTechniqueAdvice;

  static void initialize(String apiKey) {
    _apiKey = apiKey;
  }

  ProactiveAITutorService() {
    _conversationHistory.add({
      'role': 'system',
      'content':
          '''You are an expert piano teacher and MIDI technology specialist with a proactive teaching style.

Your role is to:
- Monitor student performance and provide timely, encouraging feedback
- Identify playing patterns and suggest relevant techniques
- Offer bite-sized tips at appropriate moments
- Celebrate progress and achievements
- Provide practical, actionable advice

Teaching style:
- Be warm, encouraging, and supportive
- Keep responses concise (2-3 sentences for quick tips)
- Use positive reinforcement
- Offer specific, actionable suggestions
- Adapt difficulty to student's level
- Recognize improvement and celebrate milestones

Focus areas:
- Piano techniques and theory
- MIDI setup optimization
- Practice strategies
- Musical expression
- Troubleshooting issues'''
    });

    _sessionStartTime = DateTime.now();
    _startProactiveMonitoring();
  }

  void _startProactiveMonitoring() {
    // Check every 30 seconds for proactive teaching opportunities
    _proactiveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _evaluateTeachingOpportunity();
    });
  }

  Future<void> _evaluateTeachingOpportunity() async {
    if (_totalNotesPlayed < 10) return; // Wait for some activity

    // Determine what type of proactive suggestion to make
    final sessionDuration = DateTime.now().difference(_sessionStartTime!);

    if (sessionDuration.inMinutes > 5 && _lastSuggestionType != 'break') {
      _provideTip(
          'Remember to take breaks! Your hands will thank you. Try the 20-20-20 rule: every 20 minutes, take a 20-second break.');
      _lastSuggestionType = 'break';
    } else if (_noteFrequency.length > 20 && _lastSuggestionType != 'range') {
      final range = _analyzeNoteRange();
      if (range['span']! < 12) {
        _provideTip(
            'I notice you\'re playing in a narrow range. Try exploring different octaves to build familiarity with the full keyboard!');
        _lastSuggestionType = 'range';
      }
    } else if (_consecutiveCorrectNotes > 15 &&
        _lastSuggestionType != 'tempo') {
      _provideTip(
          'Great consistency! Now try gradually increasing your tempo while maintaining accuracy.');
      _lastSuggestionType = 'tempo';
    }
  }

  Map<String, int> _analyzeNoteRange() {
    if (_noteFrequency.isEmpty) {
      return {'lowest': 60, 'highest': 60, 'span': 0};
    }

    final notes = _noteFrequency.keys.toList();
    notes.sort();

    return {
      'lowest': notes.first,
      'highest': notes.last,
      'span': notes.last - notes.first,
    };
  }

  void trackNotePlay(int midiNote, double velocity) {
    _playedNotes.add(midiNote);
    _noteFrequency[midiNote] = (_noteFrequency[midiNote] ?? 0) + 1;
    _totalNotesPlayed++;
    _consecutiveCorrectNotes++;

    // Milestone celebrations
    if (_totalNotesPlayed == 50) {
      _provideEncouragement(
          '🎉 You\'ve played 50 notes! You\'re getting warmed up!');
    } else if (_totalNotesPlayed == 200) {
      _provideEncouragement(
          '🎵 Amazing! 200 notes played. You\'re really getting into the groove!');
    } else if (_totalNotesPlayed == 500) {
      _provideEncouragement(
          '🌟 Incredible! 500 notes! Your dedication is inspiring!');
    }
  }

  void trackMistake() {
    _consecutiveCorrectNotes = 0;
  }

  Future<String> getWelcomeMessage() async {
    return await getResponse(
      'Give me a warm, brief welcome message as a piano tutor. Mention that I can help with playing techniques, MIDI setup, and I\'ll provide proactive tips during practice.',
      addToHistory: false,
    );
  }

  Future<String> getResponse(String userMessage,
      {bool addToHistory = true}) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return 'AI Tutor is not configured. Please add your OpenAI API key to the .env file.';
    }

    if (addToHistory) {
      _conversationHistory.add({
        'role': 'user',
        'content': userMessage,
      });
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': _conversationHistory,
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantMessage =
            data['choices'][0]['message']['content'] as String;

        if (addToHistory) {
          _conversationHistory.add({
            'role': 'assistant',
            'content': assistantMessage,
          });
        }

        return assistantMessage;
      } else {
        debugPrint(
            'OpenAI API Error: ${response.statusCode} - ${response.body}');
        return 'Sorry, I encountered an error. Please check your API key and internet connection.';
      }
    } catch (e) {
      debugPrint('Error calling OpenAI API: $e');
      return 'Sorry, I couldn\'t connect to the AI service. Please check your internet connection.';
    }
  }

  void _provideTip(String tip) {
    onProactiveSuggestion?.call(tip);
  }

  void _provideEncouragement(String encouragement) {
    onEncouragement?.call(encouragement);
  }

  Future<String> getProactiveAdvice() async {
    final range = _analyzeNoteRange();
    final sessionDuration =
        DateTime.now().difference(_sessionStartTime!).inMinutes;

    final context = '''Based on my practice session:
- Session duration: $sessionDuration minutes
- Total notes played: $_totalNotesPlayed
- Note range: ${range['span']} semitones (lowest: ${range['lowest']}, highest: ${range['highest']})
- Most played notes: ${_getTopNotes(3)}

Give me one specific, actionable tip to improve my practice right now. Keep it brief (2-3 sentences).''';

    return await getResponse(context);
  }

  String _getTopNotes(int count) {
    final sorted = _noteFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(count)
        .map((e) => _getNoteNameFromMidi(e.key))
        .join(', ');
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

  Future<String> getLatencyAdvice(
      double currentLatency, String deviceType) async {
    final message =
        '''I'm using a $deviceType MIDI device with current latency set to ${currentLatency}ms. 
Can you give me specific advice on whether this latency is optimal for my setup and how to adjust it?''';
    return await getResponse(message);
  }

  Future<String> getConnectionHelp(String issue) async {
    final message =
        'I\'m having trouble with my MIDI connection: $issue. Can you help me troubleshoot?';
    return await getResponse(message);
  }

  Future<String> getPracticeSuggestion(String skillLevel) async {
    final sessionContext = _totalNotesPlayed > 0
        ? 'I\'ve played $_totalNotesPlayed notes so far in this session.'
        : '';

    final message = '''I\'m a $skillLevel piano player. $sessionContext
What should I practice next with my MIDI keyboard? Give me 2-3 specific suggestions.''';

    return await getResponse(message);
  }

  Future<String> explainBLEMIDI() async {
    final message = '''Can you explain BLE-MIDI technology in simple terms? 
Why is there latency, and why is it different on different devices?''';
    return await getResponse(message);
  }

  Future<String> getTechniqueHelp(String technique) async {
    final message =
        'Can you help me improve my $technique technique on piano? Give me practical, step-by-step tips.';
    return await getResponse(message);
  }

  Future<String> analyzePracticeSession() async {
    final duration = DateTime.now().difference(_sessionStartTime!);
    final message = '''Analyze my practice session:
- Duration: ${duration.inMinutes} minutes
- Notes played: $_totalNotesPlayed
- Unique notes: ${_noteFrequency.length}
- Average notes per minute: ${(_totalNotesPlayed / duration.inMinutes).toStringAsFixed(1)}

Give me feedback and suggestions for my next session.''';

    return await getResponse(message);
  }

  void clearHistory() {
    _conversationHistory.clear();
    _conversationHistory.add({
      'role': 'system',
      'content':
          '''You are an expert piano teacher with a proactive teaching style.'''
    });
  }

  void resetSession() {
    _playedNotes.clear();
    _noteFrequency.clear();
    _sessionStartTime = DateTime.now();
    _totalNotesPlayed = 0;
    _consecutiveCorrectNotes = 0;
    _lastSuggestionType = '';
  }

  Map<String, dynamic> getSessionStats() {
    final duration = DateTime.now().difference(_sessionStartTime!);
    final range = _analyzeNoteRange();

    return {
      'duration': duration.inMinutes,
      'totalNotes': _totalNotesPlayed,
      'uniqueNotes': _noteFrequency.length,
      'notesPerMinute': _totalNotesPlayed / duration.inMinutes.clamp(1, 999),
      'noteRange': range['span'],
      'topNotes': _getTopNotes(5),
    };
  }

  List<Map<String, String>> get conversationHistory => _conversationHistory;
  int get totalNotesPlayed => _totalNotesPlayed;

  void dispose() {
    _proactiveTimer?.cancel();
  }
}
