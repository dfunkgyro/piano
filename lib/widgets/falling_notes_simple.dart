import 'dart:async';
import 'package:flutter/material.dart';
import '../models/lesson_note.dart';

class FallingNote {
  final LessonNote note;
  double y;
  bool hit;
  FallingNote({required this.note, this.y = -0.2, this.hit = false});
}

class FallingNotesSimple extends StatefulWidget {
  final List<LessonNote> notes;
  final Set<int> activeNotes;
  final int minNote;
  final int maxNote;
  final double speed;
  final double hitLine;
  final bool isPlaying;
  final VoidCallback onComplete;
  final void Function(int note) onNoteMissed;

  const FallingNotesSimple({
    super.key,
    required this.notes,
    required this.activeNotes,
    required this.minNote,
    required this.maxNote,
    required this.speed,
    required this.hitLine,
    required this.isPlaying,
    required this.onComplete,
    required this.onNoteMissed,
  });

  @override
  State<FallingNotesSimple> createState() => _FallingNotesSimpleState();
}

class _FallingNotesSimpleState extends State<FallingNotesSimple> {
  final List<FallingNote> _falling = [];
  Timer? _spawnTimer;
  Timer? _tick;
  Stopwatch? _stopwatch;
  int _index = 0;

  @override
  void didUpdateWidget(covariant FallingNotesSimple oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _start();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _stop();
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _start() {
    _stop();
    _stopwatch = Stopwatch()..start();
    _index = 0;
    _falling.clear();
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      _spawnNext();
    });
    _tick = Timer.periodic(const Duration(milliseconds: 16), (_) {
      setState(_advance);
    });
  }

  void _stop() {
    _spawnTimer?.cancel();
    _tick?.cancel();
    _spawnTimer = null;
    _tick = null;
    _stopwatch?.stop();
    _stopwatch = null;
  }

  void _spawnNext() {
    if (_index >= widget.notes.length) {
      return;
    }
    final elapsed = (_stopwatch?.elapsedMilliseconds ?? 0) / 1000.0;
    final leadTime = (2.0 / widget.speed).clamp(0.8, 3.5);
    final note = widget.notes[_index];
    if (elapsed >= note.time - leadTime) {
      _falling.add(FallingNote(note: note));
      _index++;
    }
  }

  void _advance() {
    final elapsed = (_stopwatch?.elapsedMilliseconds ?? 0) / 1000.0;
    final leadTime = (2.0 / widget.speed).clamp(0.8, 3.5);
    for (final item in _falling) {
      final t0 = item.note.time - leadTime;
      final progress = (elapsed - t0) / leadTime;
      item.y = progress * widget.hitLine;
      if (!item.hit && elapsed > item.note.time + 0.35) {
        item.hit = true;
        widget.onNoteMissed(item.note.midiNote);
      }
    }
    _falling.removeWhere((f) => f.y > 1.4);
    if (_index >= widget.notes.length && _falling.isEmpty) {
      widget.onComplete();
    }
  }

  bool _isBlack(int note) {
    final n = note % 12;
    return n == 1 || n == 3 || n == 6 || n == 8 || n == 10;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      final whiteNotes = <int>[];
      final blackLeftIndex = <int, int>{};
      final noteToWhiteIndex = <int, int>{};
      var whiteIndex = 0;
      for (int note = widget.minNote; note <= widget.maxNote; note++) {
        if (_isBlack(note)) {
          blackLeftIndex[note] = whiteIndex - 1;
        } else {
          whiteNotes.add(note);
          noteToWhiteIndex[note] = whiteIndex;
          whiteIndex++;
        }
      }

      final whiteKeyWidth = width / whiteNotes.length.clamp(1, 999);
      final blackKeyWidth = whiteKeyWidth * 0.6;
      final noteHeight = (height * 0.12).clamp(18.0, 56.0);

      return Stack(
        children: [
          ..._falling.map((f) {
            final isBlack = _isBlack(f.note.midiNote);
            final note = f.note.midiNote;
            if (note < widget.minNote || note > widget.maxNote) {
              return const SizedBox.shrink();
            }
            double? x;
            double w;
            if (isBlack) {
              final leftIndex = blackLeftIndex[note];
              if (leftIndex == null || leftIndex < 0) {
                return const SizedBox.shrink();
              }
              x = (leftIndex + 1) * whiteKeyWidth - (blackKeyWidth / 2);
              w = blackKeyWidth;
            } else {
              final idx = noteToWhiteIndex[note];
              if (idx == null) {
                return const SizedBox.shrink();
              }
              x = idx * whiteKeyWidth;
              w = whiteKeyWidth;
            }
            return Positioned(
              left: x,
              top: f.y * height,
              child: Container(
                width: w - 2,
                height: noteHeight,
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
              ),
            );
          }),
          Positioned(
            left: 0,
            right: 0,
            top: widget.hitLine * height,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orangeAccent.withOpacity(0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}
