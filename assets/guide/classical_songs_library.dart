import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'audio_player_service.dart';
import 'proactive_ai_tutor_service.dart';
import 'piano_keyboard_widget.dart';

class Song {
  final String title;
  final String composer;
  final String difficulty;
  final int tempo; // BPM
  final List<SongNote> notes;
  final String description;
  final Color color;

  const Song({
    required this.title,
    required this.composer,
    required this.difficulty,
    required this.tempo,
    required this.notes,
    required this.description,
    required this.color,
  });
}

class SongNote {
  final List<int> midiNotes; // Can be multiple for chords
  final int duration; // in milliseconds
  final String? annotation;

  const SongNote({
    required this.midiNotes,
    required this.duration,
    this.annotation,
  });
}

class ClassicalSongsLibrary {
  static final List<Song> songs = [
    // 1. Beethoven - Ode to Joy (simplified)
    Song(
      title: 'Ode to Joy',
      composer: 'Ludwig van Beethoven',
      difficulty: 'Beginner',
      tempo: 120,
      description:
          'Famous melody from Beethoven\'s 9th Symphony. Simple and recognizable!',
      color: CupertinoColors.systemPurple,
      notes: [
        SongNote(midiNotes: [64], duration: 500), // E
        SongNote(midiNotes: [64], duration: 500), // E
        SongNote(midiNotes: [65], duration: 500), // F
        SongNote(midiNotes: [67], duration: 500), // G
        SongNote(midiNotes: [67], duration: 500), // G
        SongNote(midiNotes: [65], duration: 500), // F
        SongNote(midiNotes: [64], duration: 500), // E
        SongNote(midiNotes: [62], duration: 500), // D
        SongNote(midiNotes: [60], duration: 500), // C
        SongNote(midiNotes: [60], duration: 500), // C
        SongNote(midiNotes: [62], duration: 500), // D
        SongNote(midiNotes: [64], duration: 500), // E
        SongNote(midiNotes: [64], duration: 750), // E
        SongNote(midiNotes: [62], duration: 250), // D
        SongNote(midiNotes: [62], duration: 1000), // D
      ],
    ),

    // 2. Mozart - Eine Kleine Nachtmusik
    Song(
      title: 'Eine Kleine Nachtmusik',
      composer: 'Wolfgang Amadeus Mozart',
      difficulty: 'Beginner',
      tempo: 140,
      description:
          'Opening of Mozart\'s famous serenade. Elegant and cheerful!',
      color: CupertinoColors.systemBlue,
      notes: [
        SongNote(midiNotes: [67], duration: 250), // G
        SongNote(midiNotes: [62], duration: 500), // D
        SongNote(midiNotes: [67], duration: 250), // G
        SongNote(midiNotes: [62], duration: 500), // D
        SongNote(midiNotes: [67], duration: 250), // G
        SongNote(midiNotes: [62], duration: 250), // D
        SongNote(midiNotes: [67], duration: 250), // G
        SongNote(midiNotes: [71], duration: 500), // B
        SongNote(midiNotes: [69], duration: 250), // A
        SongNote(midiNotes: [67], duration: 250), // G
        SongNote(midiNotes: [65], duration: 250), // F
        SongNote(midiNotes: [67], duration: 750), // G
      ],
    ),

    // 3. Bach - Minuet in G Major
    Song(
      title: 'Minuet in G Major',
      composer: 'Johann Sebastian Bach',
      difficulty: 'Intermediate',
      tempo: 100,
      description: 'Graceful baroque dance. Practice smooth transitions!',
      color: CupertinoColors.systemGreen,
      notes: [
        SongNote(midiNotes: [62], duration: 500), // D
        SongNote(midiNotes: [67, 71], duration: 500), // G, B (chord)
        SongNote(midiNotes: [69], duration: 500), // A
        SongNote(midiNotes: [71], duration: 500), // B
        SongNote(midiNotes: [72], duration: 500), // C
        SongNote(midiNotes: [62], duration: 1000), // D
        SongNote(midiNotes: [67], duration: 500), // G
        SongNote(midiNotes: [62], duration: 500), // D
        SongNote(midiNotes: [67], duration: 500), // G
        SongNote(midiNotes: [71], duration: 500), // B
        SongNote(midiNotes: [69], duration: 500), // A
        SongNote(midiNotes: [67], duration: 1000), // G
      ],
    ),

    // 4. Chopin - Prelude in E Minor (simplified)
    Song(
      title: 'Prelude in E Minor',
      composer: 'Frédéric Chopin',
      difficulty: 'Intermediate',
      tempo: 90,
      description: 'Melancholic and expressive. Focus on dynamics and feeling.',
      color: CupertinoColors.systemIndigo,
      notes: [
        SongNote(midiNotes: [64, 71], duration: 1000), // E, B
        SongNote(midiNotes: [67, 71], duration: 500), // G, B
        SongNote(midiNotes: [66, 71], duration: 500), // F#, B
        SongNote(midiNotes: [64, 71], duration: 1000), // E, B
        SongNote(midiNotes: [62, 71], duration: 500), // D, B
        SongNote(midiNotes: [64, 71], duration: 500), // E, B
        SongNote(midiNotes: [59, 71], duration: 1000), // B, B
        SongNote(
          midiNotes: [60, 67],
          duration: 2000,
          annotation: 'Hold',
        ), // C, G
      ],
    ),

    // 5. Debussy - Clair de Lune (opening)
    Song(
      title: 'Clair de Lune',
      composer: 'Claude Debussy',
      difficulty: 'Advanced',
      tempo: 70,
      description: 'Impressionist masterpiece. Use soft touch and pedal.',
      color: CupertinoColors.systemTeal,
      notes: [
        SongNote(midiNotes: [65], duration: 750, annotation: 'Soft'), // F
        SongNote(midiNotes: [67], duration: 750), // G
        SongNote(midiNotes: [69], duration: 750), // A
        SongNote(midiNotes: [65], duration: 750), // F
        SongNote(midiNotes: [67], duration: 750), // G
        SongNote(midiNotes: [69], duration: 750), // A
        SongNote(midiNotes: [72], duration: 1500, annotation: 'Sustain'), // C
        SongNote(midiNotes: [69], duration: 750), // A
        SongNote(midiNotes: [67], duration: 750), // G
        SongNote(midiNotes: [65], duration: 1500), // F
      ],
    ),

    // 6. Tchaikovsky - Dance of the Sugar Plum Fairy
    Song(
      title: 'Sugar Plum Fairy',
      composer: 'Pyotr Ilyich Tchaikovsky',
      difficulty: 'Advanced',
      tempo: 110,
      description:
          'Magical and delicate. Precise timing and light touch required.',
      color: CupertinoColors.systemPink,
      notes: [
        SongNote(midiNotes: [76], duration: 200), // E
        SongNote(midiNotes: [76], duration: 200), // E
        SongNote(midiNotes: [76], duration: 200), // E
        SongNote(midiNotes: [77], duration: 400), // F
        SongNote(midiNotes: [76], duration: 200), // E
        SongNote(midiNotes: [74], duration: 200), // D
        SongNote(midiNotes: [72], duration: 400), // C
        SongNote(midiNotes: [76], duration: 200), // E
        SongNote(midiNotes: [77], duration: 200), // F
        SongNote(midiNotes: [79], duration: 400), // G
        SongNote(midiNotes: [81], duration: 800, annotation: 'Sparkle!'), // A
      ],
    ),
  ];
}

class ClassicalSongsScreen extends StatefulWidget {
  final AudioPlayerService audioService;
  final ProactiveAITutorService aiTutor;
  final Set<int> activeNotes;

  const ClassicalSongsScreen({
    super.key,
    required this.audioService,
    required this.aiTutor,
    required this.activeNotes,
  });

  @override
  State<ClassicalSongsScreen> createState() => _ClassicalSongsScreenState();
}

class _ClassicalSongsScreenState extends State<ClassicalSongsScreen> {
  Song? _selectedSong;
  int _currentNoteIndex = 0;
  bool _isPlaying = false;
  bool _isPracticing = false;
  Timer? _playbackTimer;
  Timer? _aiCoachingTimer;

  Set<int> _targetNotes = {};
  Set<int> _correctNotes = {};
  int _mistakes = 0;
  int _perfectNotes = 0;
  String _aiFeedback = '';
  double _accuracy = 0.0;
  DateTime? _noteStartTime;

  @override
  void dispose() {
    _stopPlayback();
    _aiCoachingTimer?.cancel();
    super.dispose();
  }

  void _startPlayback(Song song) {
    setState(() {
      _selectedSong = song;
      _currentNoteIndex = 0;
      _isPlaying = true;
      _isPracticing = false;
      _targetNotes.clear();
    });

    _playNextNote();
  }

  void _playNextNote() {
    if (_selectedSong == null || !_isPlaying) return;

    if (_currentNoteIndex >= _selectedSong!.notes.length) {
      _stopPlayback();
      _showCompletionDialog();
      return;
    }

    final note = _selectedSong!.notes[_currentNoteIndex];

    setState(() {
      _targetNotes = Set.from(note.midiNotes);
    });

    // Play the notes
    for (var midiNote in note.midiNotes) {
      widget.audioService.playNote(midiNote, 0.8, fromMidi: false);
    }

    // Schedule next note
    _playbackTimer = Timer(Duration(milliseconds: note.duration), () {
      for (var midiNote in note.midiNotes) {
        widget.audioService.stopNote(midiNote);
      }

      setState(() {
        _currentNoteIndex++;
      });

      _playNextNote();
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _isPracticing = false;
      _targetNotes.clear();
      _correctNotes.clear();
    });
    widget.audioService.stopAllNotes();
  }

  void _startPractice(Song song) async {
    setState(() {
      _selectedSong = song;
      _currentNoteIndex = 0;
      _isPracticing = true;
      _isPlaying = false;
      _mistakes = 0;
      _perfectNotes = 0;
      _accuracy = 0.0;
      _noteStartTime = DateTime.now();
    });

    _showNextTargetNote();

    final feedback = await widget.aiTutor.getResponse(
      'I\'m starting to practice "${song.title}" by ${song.composer}. Give me a brief encouraging tip to get started (2 sentences max).',
      addToHistory: false,
    );

    setState(() => _aiFeedback = feedback);

    // Start AI coaching
    _startAICoaching();
  }

  void _startAICoaching() {
    _aiCoachingTimer?.cancel();
    _aiCoachingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _provideAIFeedback();
    });
  }

  void _provideAIFeedback() async {
    if (!_isPracticing) return;

    final progress = (_currentNoteIndex / _selectedSong!.notes.length * 100)
        .toInt();

    String feedback;
    if (_perfectNotes > 5 && _mistakes == 0) {
      feedback =
          '🌟 Perfect! You\'re hitting every note! Keep this excellent focus!';
    } else if (_mistakes > _perfectNotes) {
      feedback =
          '💡 Take your time! Focus on accuracy over speed. The notes will light up yellow to guide you.';
    } else if (progress > 50) {
      feedback = 'You\'re over halfway! Stay focused and maintain your tempo.';
    } else {
      feedback =
          'Good progress! Watch the highlighted notes and match the timing.';
    }

    setState(() => _aiFeedback = feedback);
  }

  void _showNextTargetNote() {
    if (_selectedSong == null || !_isPracticing) return;

    if (_currentNoteIndex >= _selectedSong!.notes.length) {
      _completePractice();
      return;
    }

    final note = _selectedSong!.notes[_currentNoteIndex];
    setState(() {
      _targetNotes = Set.from(note.midiNotes);
      _correctNotes.clear();
    });
  }

  void _checkNote(int midiNote) {
    if (!_isPracticing || _targetNotes.isEmpty) return;

    if (_targetNotes.contains(midiNote)) {
      setState(() => _correctNotes.add(midiNote));

      // Check if all notes in chord are correct
      if (_correctNotes.length == _targetNotes.length) {
        _perfectNotes++;
        _advanceToNextNote();
      }
    } else {
      _mistakes++;
      _provideMistakeFeedback(midiNote);
    }

    _updateAccuracy();
  }

  void _advanceToNextNote() {
    setState(() => _currentNoteIndex++);
    _showNextTargetNote();
  }

  void _provideMistakeFeedback(int wrongNote) {
    final wrongNoteName = _getNoteNameFromMidi(wrongNote);
    final expectedNotes = _targetNotes
        .map((n) => _getNoteNameFromMidi(n))
        .join(' + ');

    setState(() {
      _aiFeedback =
          '❌ You played $wrongNoteName, but expected $expectedNotes. Try again!';
    });
  }

  void _updateAccuracy() {
    final total = _perfectNotes + _mistakes;
    if (total > 0) {
      setState(() {
        _accuracy = (_perfectNotes / total * 100).clamp(0, 100);
      });
    }
  }

  void _completePractice() async {
    _aiCoachingTimer?.cancel();

    final duration = DateTime.now().difference(_noteStartTime!);
    final feedback = await widget.aiTutor.getResponse(
      'I just finished practicing "${_selectedSong!.title}". I played ${_perfectNotes} notes perfectly and made $_mistakes mistakes in ${duration.inSeconds} seconds. Give me encouraging feedback and tips for improvement (3 sentences).',
    );

    _showCompletionDialog(feedback: feedback);
  }

  void _showCompletionDialog({String? feedback}) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.star_fill, color: CupertinoColors.systemYellow),
            SizedBox(width: 8),
            Text('Song Complete!'),
            SizedBox(width: 8),
            Icon(CupertinoIcons.star_fill, color: CupertinoColors.systemYellow),
          ],
        ),
        content: Column(
          children: [
            const SizedBox(height: 16),
            if (_isPracticing) ...[
              Text('Perfect Notes: $_perfectNotes'),
              Text('Mistakes: $_mistakes'),
              Text('Accuracy: ${_accuracy.toStringAsFixed(1)}%'),
              const SizedBox(height: 12),
            ],
            if (feedback != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(feedback, style: const TextStyle(fontSize: 13)),
              ),
          ],
        ),
        actions: [
          if (_isPracticing)
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                _startPractice(_selectedSong!);
              },
              child: const Text('Practice Again'),
            ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _stopPlayback();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _getNoteNameFromMidi(int midiNote) {
    const noteNames = [
      'A',
      'A#',
      'B',
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
    ];
    final octave = (midiNote - 12) ~/ 12;
    final noteIndex = (midiNote - 21) % 12;
    return '${noteNames[noteIndex]}$octave';
  }

  @override
  Widget build(BuildContext context) {
    // Check user notes and provide feedback
    for (var note in widget.activeNotes) {
      if (_isPracticing) {
        _checkNote(note);
      }
    }

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF2C2C2E),
        middle: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.music_albums, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text('Classical Library', style: TextStyle(color: Colors.white)),
          ],
        ),
        trailing: _isPlaying || _isPracticing
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _stopPlayback,
                child: const Icon(
                  CupertinoIcons.stop_circle_fill,
                  color: CupertinoColors.systemRed,
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // AI Feedback Banner
            if (_aiFeedback.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CupertinoColors.systemPurple.withOpacity(0.3),
                      CupertinoColors.systemBlue.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.sparkles,
                      color: CupertinoColors.systemPurple,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _aiFeedback,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Progress indicator
            if (_isPracticing || _isPlaying)
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF2C2C2E),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Note ${_currentNoteIndex + 1}/${_selectedSong?.notes.length ?? 0}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        if (_isPracticing)
                          Text(
                            'Accuracy: ${_accuracy.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: _accuracy >= 80
                                  ? CupertinoColors.systemGreen
                                  : CupertinoColors.systemOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_selectedSong?.notes.length ?? 1) > 0
                            ? _currentNoteIndex / _selectedSong!.notes.length
                            : 0,
                        backgroundColor: CupertinoColors.systemGrey,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _selectedSong?.color ?? CupertinoColors.systemBlue,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

            // Keyboard
            PianoKeyboardWidget(
              activeNotes: widget.activeNotes,
              highlightNotes: _targetNotes,
              height: 220,
            ),

            // Song List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ClassicalSongsLibrary.songs.length,
                itemBuilder: (context, index) {
                  final song = ClassicalSongsLibrary.songs[index];
                  final isSelected = _selectedSong == song;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            song.color.withOpacity(0.2),
                            song.color.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? song.color
                              : song.color.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: song.color.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        CupertinoIcons.music_note_2,
                                        color: song.color,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            song.title,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            song.composer,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getDifficultyColor(
                                          song.difficulty,
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getDifficultyColor(
                                            song.difficulty,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        song.difficulty,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _getDifficultyColor(
                                            song.difficulty,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  song.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white60,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.metronome,
                                      size: 14,
                                      color: Colors.white54,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${song.tempo} BPM',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white54,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      CupertinoIcons.music_note_list,
                                      size: 14,
                                      color: Colors.white54,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${song.notes.length} notes',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  color: song.color.withOpacity(0.3),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  onPressed: () => _startPlayback(song),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(CupertinoIcons.play_fill, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'Listen',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: song.color,
                              ),
                              Expanded(
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  color: song.color.withOpacity(0.3),
                                  borderRadius: const BorderRadius.only(
                                    bottomRight: Radius.circular(12),
                                  ),
                                  onPressed: () => _startPractice(song),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(CupertinoIcons.music_note, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'Practice',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return CupertinoColors.systemGreen;
      case 'Intermediate':
        return CupertinoColors.systemOrange;
      case 'Advanced':
        return CupertinoColors.systemRed;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}
