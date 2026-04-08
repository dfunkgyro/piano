import 'package:flutter/material.dart';
import 'dart:async';

class FallingNote {
  final int midiNote;
  final double startTime;
  final String hand;
  double yPosition;
  bool isHit;

  FallingNote({
    required this.midiNote,
    required this.startTime,
    required this.hand,
    this.yPosition = 0.0,
    this.isHit = false,
  });
}

class FallingNotesWidget extends StatefulWidget {
  final List<Map<String, dynamic>> notes;
  final Set<int> activeNotes;
  final Function(int) onNoteHit;
  final Function(int) onNoteMissed;
  final double speed;
  final bool isPlaying;

  const FallingNotesWidget({
    super.key,
    required this.notes,
    required this.activeNotes,
    required this.onNoteHit,
    required this.onNoteMissed,
    this.speed = 0.3,
    this.isPlaying = false,
  });

  @override
  State<FallingNotesWidget> createState() => _FallingNotesWidgetState();
}

class _FallingNotesWidgetState extends State<FallingNotesWidget>
    with SingleTickerProviderStateMixin {
  final List<FallingNote> _fallingNotes = [];
  late Timer _spawnTimer;
  late Timer _updateTimer;
  double _elapsedTime = 0.0;
  int _currentNoteIndex = 0;

  static const int firstMidiNote = 48; // C3
  static const int lastMidiNote = 84; // C6
  static const int visibleKeys = lastMidiNote - firstMidiNote + 1;
  static const double hitLinePosition = 0.85;

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) {
      _startGame();
    }
  }

  @override
  void didUpdateWidget(FallingNotesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startGame();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _stopGame();
    }
  }

  @override
  void dispose() {
    _stopGame();
    super.dispose();
  }

  void _startGame() {
    _elapsedTime = 0.0;
    _currentNoteIndex = 0;
    _fallingNotes.clear();

    // Spawn notes
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _spawnNextNote();
    });

    // Update positions
    _updateTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      setState(() {
        _updateNotes();
      });
    });
  }

  void _stopGame() {
    _spawnTimer.cancel();
    _updateTimer.cancel();
  }

  // In the _spawnNextNote method, update the property access:
  void _spawnNextNote() {
    if (_currentNoteIndex >= widget.notes.length) {
      _spawnTimer.cancel();
      return;
    }

    final noteData = widget.notes[_currentNoteIndex];
    final noteTime = noteData['time'] as double? ?? 0.0;

    // Check if it's time to spawn this note
    if (_elapsedTime >= noteTime - 2.0) {
      _fallingNotes.add(FallingNote(
        midiNote: noteData['note'] as int, // This should now work correctly
        startTime: _elapsedTime,
        hand: noteData['hand'] as String? ?? 'R',
      ));
      _currentNoteIndex++;
    }
  }

  void _updateNotes() {
    _elapsedTime += 0.016; // 16ms per frame

    // Update positions
    for (var note in _fallingNotes) {
      final timeSinceSpawn = _elapsedTime - note.startTime;
      note.yPosition = timeSinceSpawn * widget.speed;

      // Check if note reached hit line
      if (!note.isHit &&
          note.yPosition >= hitLinePosition - 0.05 &&
          note.yPosition <= hitLinePosition + 0.05) {
        if (widget.activeNotes.contains(note.midiNote)) {
          note.isHit = true;
          widget.onNoteHit(note.midiNote);
        }
      }

      // Check if note was missed
      if (!note.isHit && note.yPosition > hitLinePosition + 0.1) {
        note.isHit = true; // Mark as processed
        widget.onNoteMissed(note.midiNote);
      }
    }

    // Remove notes that have passed
    _fallingNotes.removeWhere((note) => note.yPosition > 1.2);
  }

  Color _getNoteColor(FallingNote note) {
    if (note.isHit) {
      return Colors.green;
    }

    if (note.hand == 'L') {
      return Colors.blue.withOpacity(0.8);
    } else if (note.hand == 'R') {
      return Colors.red.withOpacity(0.8);
    }

    return Colors.purple.withOpacity(0.8);
  }

  double _getNoteXPosition(int midiNote, double width) {
    final keyIndex = midiNote - firstMidiNote;
    final keyWidth = width / visibleKeys;
    return keyIndex * keyWidth;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.9),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Falling notes
              ..._fallingNotes.map((note) {
                final xPos = _getNoteXPosition(note.midiNote, width);
                final yPos = note.yPosition * height;
                final noteWidth = width / visibleKeys;

                return Positioned(
                  left: xPos,
                  top: yPos,
                  child: Container(
                    width: noteWidth - 2,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getNoteColor(note),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getNoteColor(note).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              // Hit line
              Positioned(
                left: 0,
                right: 0,
                top: hitLinePosition * height,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.green.withOpacity(0.8),
                        Colors.green,
                        Colors.green.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // Keyboard guide at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                  child: Row(
                    children: List.generate(visibleKeys, (index) {
                      final midiNote = firstMidiNote + index;
                      final isActive = widget.activeNotes.contains(midiNote);

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withOpacity(0.6)
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
