import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'proactive_ai_tutor_service.dart';
import 'audio_player_service.dart';
import 'piano_keyboard_widget.dart';

class PianoLessonScreen extends StatefulWidget {
  final ProactiveAITutorService aiTutor;
  final AudioPlayerService audioService;
  final Set<int> activeNotes;

  const PianoLessonScreen({
    super.key,
    required this.aiTutor,
    required this.audioService,
    required this.activeNotes,
  });

  @override
  State<PianoLessonScreen> createState() => _PianoLessonScreenState();
}

class _PianoLessonScreenState extends State<PianoLessonScreen> {
  String _currentLesson = '';
  List<int> _targetNotes = [];
  Set<int> _highlightNotes = {};
  bool _isLoading = false;
  String _lessonType = 'scales';
  int _currentStep = 0;
  Timer? _demonstrationTimer;

  final List<Map<String, dynamic>> _lessons = [
    {
      'name': 'C Major Scale',
      'type': 'scale',
      'notes': [60, 62, 64, 65, 67, 69, 71, 72], // C D E F G A B C
      'description': 'Learn the C Major scale',
      'tempo': 500,
    },
    {
      'name': 'C Major Chord',
      'type': 'chord',
      'notes': [60, 64, 67], // C E G
      'description': 'Play C Major chord',
      'tempo': 0,
    },
    {
      'name': 'Arpeggio C Major',
      'type': 'arpeggio',
      'notes': [60, 64, 67, 72], // C E G C
      'description': 'Fast arpeggio exercise',
      'tempo': 200,
    },
    {
      'name': 'Chromatic Scale',
      'type': 'scale',
      'notes': [60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72],
      'description': 'All 12 notes',
      'tempo': 400,
    },
    {
      'name': 'Tremolo Exercise',
      'type': 'tremolo',
      'notes': [60, 64], // Alternate C and E rapidly
      'description': 'Rapid alternation between two notes',
      'tempo': 150,
    },
    {
      'name': 'Glissando',
      'type': 'glissando',
      'notes': List.generate(25, (i) => 60 + i), // C4 to C6
      'description': 'Slide across white keys',
      'tempo': 50,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialLesson();
  }

  @override
  void dispose() {
    _demonstrationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialLesson() async {
    setState(() => _isLoading = true);

    final message = await widget.aiTutor.getResponse(
      'Give me a brief welcome message for piano lessons and explain what we can learn together. Keep it under 100 words.',
      addToHistory: false,
    );

    setState(() {
      _currentLesson = message;
      _isLoading = false;
    });
  }

  Future<void> _startLesson(Map<String, dynamic> lesson) async {
    setState(() {
      _isLoading = true;
      _currentStep = 0;
      _targetNotes = List<int>.from(lesson['notes']);
    });

    final message = await widget.aiTutor.getResponse(
      'Explain how to play ${lesson['name']}: ${lesson['description']}. Keep it brief and practical.',
    );

    setState(() {
      _currentLesson = message;
      _isLoading = false;
    });

    // Demonstrate the lesson
    _demonstrateLesson(lesson);
  }

  void _demonstrateLesson(Map<String, dynamic> lesson) {
    _demonstrationTimer?.cancel();

    final notes = List<int>.from(lesson['notes']);
    final tempo = lesson['tempo'] as int;
    final type = lesson['type'] as String;

    setState(() {
      _currentStep = 0;
      _highlightNotes.clear();
    });

    if (type == 'chord') {
      // Play all notes simultaneously
      setState(() => _highlightNotes.addAll(notes));
      for (var note in notes) {
        widget.audioService.playNote(note, 0.8, fromMidi: false);
      }

      Future.delayed(const Duration(seconds: 2), () {
        for (var note in notes) {
          widget.audioService.stopNote(note);
        }
        setState(() => _highlightNotes.clear());
      });
    } else if (type == 'tremolo') {
      // Rapid alternation
      int index = 0;
      _demonstrationTimer =
          Timer.periodic(Duration(milliseconds: tempo), (timer) {
        if (index >= 20) {
          // Play 20 times
          timer.cancel();
          setState(() => _highlightNotes.clear());
          return;
        }

        final note = notes[index % notes.length];
        setState(() {
          _highlightNotes.clear();
          _highlightNotes.add(note);
        });

        widget.audioService.playNote(note, 0.7, fromMidi: false);
        Future.delayed(Duration(milliseconds: tempo ~/ 2), () {
          widget.audioService.stopNote(note, immediate: true);
        });

        index++;
      });
    } else {
      // Sequential playing (scale, arpeggio, glissando)
      int index = 0;
      _demonstrationTimer =
          Timer.periodic(Duration(milliseconds: tempo), (timer) {
        if (index >= notes.length) {
          timer.cancel();
          setState(() => _highlightNotes.clear());
          return;
        }

        final note = notes[index];
        setState(() {
          _highlightNotes.clear();
          _highlightNotes.add(note);
          _currentStep = index;
        });

        widget.audioService.playNote(note, 0.8, fromMidi: false);

        Future.delayed(Duration(milliseconds: tempo ~/ 2), () {
          widget.audioService.stopNote(note);
        });

        index++;
      });
    }
  }

  String _getNoteName(int midiNote) {
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

  Future<void> _askAIQuestion(String question) async {
    setState(() => _isLoading = true);

    final response = await widget.aiTutor.getResponse(question);

    setState(() {
      _currentLesson = response;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.book, size: 20),
            SizedBox(width: 8),
            Text('Piano Lessons'),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Keyboard Display with Highlights
            Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CupertinoColors.systemIndigo.withOpacity(0.1),
                    CupertinoColors.systemBackground,
                  ],
                ),
              ),
              child: PianoKeyboardWidget(
                activeNotes: widget.activeNotes.union(_highlightNotes),
                highlightNotes: _highlightNotes,
                onKeyPressed: (note) {
                  widget.audioService.playNote(note, 0.8, fromMidi: false);
                },
                onKeyReleased: (note) {
                  widget.audioService.stopNote(note);
                },
              ),
            ),

            // Lesson Progress
            if (_targetNotes.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemGroupedBackground,
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.systemGrey5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.music_note_list,
                      size: 16,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Target notes: ${_targetNotes.map((n) => _getNoteName(n)).join(' → ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                    if (_currentStep > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_currentStep/${_targetNotes.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.systemGreen,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Lesson Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // AI Tutor Message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CupertinoColors.systemPurple.withOpacity(0.1),
                          CupertinoColors.systemBlue.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              CupertinoIcons.sparkles,
                              color: CupertinoColors.systemPurple,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'AI Piano Tutor',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CupertinoActivityIndicator(),
                            ),
                          )
                        else
                          Text(
                            _currentLesson,
                            style: const TextStyle(fontSize: 14),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Lesson Categories
                  const Text(
                    'Choose a Lesson',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Lesson Cards
                  ..._lessons.map((lesson) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _startLesson(lesson),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: CupertinoColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: CupertinoColors.systemGrey5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.systemGrey
                                      .withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _getLessonColor(lesson['type'])
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getLessonIcon(lesson['type']),
                                    color: _getLessonColor(lesson['type']),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lesson['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: CupertinoColors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lesson['description'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: CupertinoColors.systemGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  CupertinoIcons.play_circle_fill,
                                  color: CupertinoColors.systemBlue,
                                  size: 32,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),

                  const SizedBox(height: 20),

                  // Quick Questions
                  const Text(
                    'Quick Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickQuestionChip(
                        label: 'How to play faster?',
                        onTap: () => _askAIQuestion(
                          'Give me tips on how to play piano faster, including allegro tempo and rapid arpeggios.',
                        ),
                      ),
                      _QuickQuestionChip(
                        label: 'What is a glissando?',
                        onTap: () => _askAIQuestion(
                          'Explain what a glissando is and how to perform it on piano.',
                        ),
                      ),
                      _QuickQuestionChip(
                        label: 'Teach me chords',
                        onTap: () => _askAIQuestion(
                          'Teach me about piano chords and how to play them together.',
                        ),
                      ),
                      _QuickQuestionChip(
                        label: 'Tremolo technique',
                        onTap: () => _askAIQuestion(
                          'How do I perform tremolo on piano? Give me practical tips.',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLessonColor(String type) {
    switch (type) {
      case 'scale':
        return CupertinoColors.systemBlue;
      case 'chord':
        return CupertinoColors.systemGreen;
      case 'arpeggio':
        return CupertinoColors.systemPurple;
      case 'tremolo':
        return CupertinoColors.systemOrange;
      case 'glissando':
        return CupertinoColors.systemPink;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  IconData _getLessonIcon(String type) {
    switch (type) {
      case 'scale':
        return CupertinoIcons.arrow_up_right;
      case 'chord':
        return CupertinoIcons.layers_alt_fill;
      case 'arpeggio':
        return CupertinoIcons.waveform;
      case 'tremolo':
        return CupertinoIcons.bolt_fill;
      case 'glissando':
        return CupertinoIcons.arrow_right;
      default:
        return CupertinoIcons.music_note;
    }
  }
}

class _QuickQuestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickQuestionChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: CupertinoColors.systemGrey6,
      borderRadius: BorderRadius.circular(20),
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.chat_bubble,
            size: 14,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
