import 'package:flutter/material.dart';
import 'dart:async';

class FallingNote {
  final int midiNote;
  final double startTime;
  final String hand;
  double yPosition;
  bool isHit;
  bool isMissed;

  FallingNote({
    required this.midiNote,
    required this.startTime,
    required this.hand,
    this.yPosition = 0.0,
    this.isHit = false,
    this.isMissed = false,
  });
}

class FallingNotesWidget extends StatefulWidget {
  final List<Map<String, dynamic>> notes;
  final Set<int> activeNotes;
  final Function(int) onNoteHit;
  final Function(int) onNoteMissed;
  final double speed;
  final bool isPlaying;
  final int startMidiNote;
  final int endMidiNote;
  final bool showGuide;
  final double hitLinePosition;
  final String? backgroundAsset;
  final double backgroundOpacity;
  final double blackKeyWidthFactor;
  final double keySpacing;
  final int loopId;

  const FallingNotesWidget({
    super.key,
    required this.notes,
    required this.activeNotes,
    required this.onNoteHit,
    required this.onNoteMissed,
    this.speed = 0.3,
    this.isPlaying = false,
    this.startMidiNote = 21,
    this.endMidiNote = 108,
    this.showGuide = false,
    this.hitLinePosition = 0.9,
    this.backgroundAsset,
    this.backgroundOpacity = 0.18,
    this.blackKeyWidthFactor = 0.6,
    this.keySpacing = 0.0,
    this.loopId = 0,
  });

  @override
  State<FallingNotesWidget> createState() => _FallingNotesWidgetState();
}

class _FallingNotesWidgetState extends State<FallingNotesWidget>
    with SingleTickerProviderStateMixin {
  final List<FallingNote> _fallingNotes = [];
  Timer? _spawnTimer;
  Timer? _updateTimer;
  double _elapsedTime = 0.0;
  int _currentNoteIndex = 0;
  int _lastNotesHash = 0;

  final List<int> _whiteNotes = [];
  final List<int> _blackNotes = [];
  final Map<int, int> _blackLeftWhiteIndex = {};

  @override
  void initState() {
    super.initState();
    _buildKeyMaps();
    if (widget.isPlaying) {
      _startGame();
    }
  }

  @override
  void didUpdateWidget(FallingNotesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startMidiNote != oldWidget.startMidiNote ||
        widget.endMidiNote != oldWidget.endMidiNote) {
      _buildKeyMaps();
    }
    final notesHash = _computeNotesHash(widget.notes);
    final notesChanged =
        notesHash != _lastNotesHash || widget.loopId != oldWidget.loopId;
    _lastNotesHash = notesHash;

    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startGame();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _stopGame();
    } else if (widget.isPlaying && notesChanged) {
      // Restart spawn loop when a new section/loop arrives while still playing.
      _startGame();
    }
  }

  @override
  void dispose() {
    _stopGame();
    super.dispose();
  }

  void _startGame() {
    _stopGame();
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
    _spawnTimer?.cancel();
    _updateTimer?.cancel();
    _spawnTimer = null;
    _updateTimer = null;
  }

  bool _isBlackKey(int midiNote) {
    final noteInOctave = midiNote % 12;
    return noteInOctave == 1 ||
        noteInOctave == 3 ||
        noteInOctave == 6 ||
        noteInOctave == 8 ||
        noteInOctave == 10;
  }

  void _buildKeyMaps() {
    _whiteNotes.clear();
    _blackNotes.clear();
    _blackLeftWhiteIndex.clear();
    int whiteIndex = 0;
    for (int note = widget.startMidiNote;
        note <= widget.endMidiNote;
        note++) {
      if (_isBlackKey(note)) {
        _blackNotes.add(note);
        _blackLeftWhiteIndex[note] = whiteIndex - 1;
      } else {
        _whiteNotes.add(note);
        whiteIndex++;
      }
    }
  }

  // In the _spawnNextNote method, update the property access:
  void _spawnNextNote() {
    if (_currentNoteIndex >= widget.notes.length) {
      _spawnTimer?.cancel();
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
          note.yPosition >= widget.hitLinePosition - 0.05 &&
          note.yPosition <= widget.hitLinePosition + 0.05) {
        if (widget.activeNotes.contains(note.midiNote)) {
          note.isHit = true;
          widget.onNoteHit(note.midiNote);
        }
      }

      // Check if note was missed
      if (!note.isHit && note.yPosition > widget.hitLinePosition + 0.1) {
        note.isHit = true; // Mark as processed
        note.isMissed = true;
        widget.onNoteMissed(note.midiNote);
      }
    }

    // Remove notes that have passed
    _fallingNotes.removeWhere((note) => note.yPosition > 1.2);
  }

  Color _getNoteColor(FallingNote note) {
    if (note.isHit) {
      return note.isMissed ? Colors.grey : Colors.green;
    }

    if (note.hand == 'L') {
      return Colors.blue.withOpacity(0.8);
    } else if (note.hand == 'R') {
      return Colors.red.withOpacity(0.8);
    }

    return Colors.purple.withOpacity(0.8);
  }

  double _getNoteXPosition(int midiNote, double width) {
    if (_whiteNotes.isEmpty) return 0;
    final whiteKeyWidth = width / _whiteNotes.length;
    if (!_isBlackKey(midiNote)) {
      final whiteIndex = _whiteNotes.indexOf(midiNote);
      return whiteIndex * whiteKeyWidth;
    }
    final leftWhite = _blackLeftWhiteIndex[midiNote] ?? 0;
    final blackKeyWidth = whiteKeyWidth * widget.blackKeyWidthFactor;
    return (leftWhite + 1) * whiteKeyWidth - (blackKeyWidth / 2);
  }

  @override
  Widget build(BuildContext context) {
    _lastNotesHash = _computeNotesHash(widget.notes);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final whiteKeyWidth =
            _whiteNotes.isEmpty ? width : width / _whiteNotes.length;
        final blackKeyWidth = whiteKeyWidth * widget.blackKeyWidthFactor;
        final noteHeight = (height * 0.12).clamp(24.0, 60.0);

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
              if (widget.backgroundAsset != null)
                Positioned.fill(
                  child: Opacity(
                    opacity: widget.backgroundOpacity,
                    child: Image.asset(
                      widget.backgroundAsset!,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              // Falling notes
              ..._fallingNotes.map((note) {
                final xPos = _getNoteXPosition(note.midiNote, width);
                final yPos = note.yPosition * height;
                final rawWidth =
                    _isBlackKey(note.midiNote) ? blackKeyWidth : whiteKeyWidth;
                final noteWidth = (rawWidth - widget.keySpacing).clamp(6.0, rawWidth);
                final distanceToHit =
                    (note.yPosition - widget.hitLinePosition).abs();
                final isNearHit = distanceToHit < 0.08;
                final scale = note.isHit ? 1.06 : 1.0;
                final glowStrength = isNearHit ? 0.7 : 0.3;

                return Positioned(
                  left: xPos,
                  top: yPos,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: noteWidth - 2,
                      height: noteHeight,
                      decoration: BoxDecoration(
                        color: _getNoteColor(note),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getNoteColor(note)
                                .withOpacity(glowStrength),
                            blurRadius: isNearHit ? 14 : 8,
                            spreadRadius: isNearHit ? 4 : 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

              // Hit line
              Positioned(
                left: 0,
                right: 0,
                top: widget.hitLinePosition * height,
                child: Container(
                  height: 5,
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

              if (widget.showGuide)
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
                      children: List.generate(_whiteNotes.length, (index) {
                        final midiNote = _whiteNotes[index];
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

  int _computeNotesHash(List<Map<String, dynamic>> notes) {
    if (notes.isEmpty) return 0;
    final first = notes.first;
    final last = notes.last;
    return Object.hash(
      notes.length,
      first['note'],
      first['time'],
      last['note'],
      last['time'],
    );
  }
}
