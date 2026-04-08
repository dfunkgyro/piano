import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BasicPianoKeyboard extends StatefulWidget {
  final int minNote;
  final int maxNote;
  final bool fitToWidth;
  final bool allowPinchZoom;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double>? onZoomChanged;
  final Set<int> activeNotes;
  final bool showNoteLabels;
  final ValueChanged<int> onNoteOn;
  final ValueChanged<int> onNoteOff;

  const BasicPianoKeyboard({
    super.key,
    this.minNote = 21,
    this.maxNote = 108,
    this.fitToWidth = false,
    this.allowPinchZoom = false,
    this.zoom = 1.0,
    this.minZoom = 0.7,
    this.maxZoom = 2.0,
    this.onZoomChanged,
    required this.activeNotes,
    required this.showNoteLabels,
    required this.onNoteOn,
    required this.onNoteOff,
  });

  @override
  State<BasicPianoKeyboard> createState() => _BasicPianoKeyboardState();
}

class _BasicPianoKeyboardState extends State<BasicPianoKeyboard> {
  final Map<int, int> _pointerToNote = {};
  final Set<int> _activePointers = <int>{};
  bool _scaling = false;
  double _scaleStart = 1.0;

  bool _isBlack(int note) {
    final n = note % 12;
    return n == 1 || n == 3 || n == 6 || n == 8 || n == 10;
  }

  String _noteName(int note) {
    const names = [
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
    final octave = (note ~/ 12) - 1;
    return '${names[note % 12]}$octave';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final whiteNotes = <int>[];
        final blackNotes = <int>[];
        final blackLeftIndex = <int, int>{};
        var whiteIndex = 0;
        for (int note = widget.minNote; note <= widget.maxNote; note++) {
          if (_isBlack(note)) {
            blackNotes.add(note);
            blackLeftIndex[note] = whiteIndex - 1;
          } else {
            whiteNotes.add(note);
            whiteIndex++;
          }
        }

        final computedWhiteWidth =
            constraints.maxWidth / math.max(1, whiteNotes.length);
        final baseWhiteWidth = widget.fitToWidth ? computedWhiteWidth : 28.0;
        final whiteKeyWidth = (baseWhiteWidth * widget.zoom)
            .clamp(10.0, 200.0)
            .toDouble();
        final keyboardWidth = whiteNotes.length * whiteKeyWidth;
        final blackKeyWidth = whiteKeyWidth * 0.6;
        final blackKeyHeight = constraints.maxHeight * 0.6;

        Widget keyboard = SizedBox(
          width: keyboardWidth,
          height: constraints.maxHeight,
          child: Listener(
            onPointerDown: (event) =>
                _handlePointerDown(event.pointer, event.localPosition,
                    whiteNotes, blackNotes, blackLeftIndex, whiteKeyWidth,
                    blackKeyWidth, blackKeyHeight),
            onPointerHover: (event) =>
                _handleDesktopHover(event.pointer, event.localPosition,
                    event.buttons, whiteNotes, blackNotes, blackLeftIndex,
                    whiteKeyWidth, blackKeyWidth, blackKeyHeight),
            onPointerMove: (event) =>
                _handlePointerMove(event.pointer, event.localPosition,
                    whiteNotes, blackNotes, blackLeftIndex, whiteKeyWidth,
                    blackKeyWidth, blackKeyHeight),
            onPointerUp: (event) => _handlePointerUp(event.pointer),
            onPointerCancel: (event) => _handlePointerUp(event.pointer),
            child: CustomPaint(
              painter: _KeyboardPainter(
                whiteNotes: whiteNotes,
                blackNotes: blackNotes,
                blackLeftIndex: blackLeftIndex,
                whiteKeyWidth: whiteKeyWidth,
                blackKeyWidth: blackKeyWidth,
                blackKeyHeight: blackKeyHeight,
                activeNotes: widget.activeNotes,
                showLabels: widget.showNoteLabels,
                noteName: _noteName,
              ),
            ),
          ),
        );

        if (widget.allowPinchZoom && widget.onZoomChanged != null) {
          keyboard = GestureDetector(
            behavior: HitTestBehavior.translucent,
            onScaleStart: (details) {
              _releaseTrackedPointers();
              _scaling = true;
              _scaleStart = widget.zoom;
            },
            onScaleUpdate: (details) {
              if (!_scaling || _activePointers.length < 2) return;
              final next = (_scaleStart * details.scale)
                  .clamp(widget.minZoom, widget.maxZoom)
                  .toDouble();
              widget.onZoomChanged?.call(next);
            },
            onScaleEnd: (_) {
              _scaling = false;
            },
            child: keyboard,
          );
        }

        if (widget.fitToWidth) {
          return keyboard;
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: keyboard,
        );
      },
    );
  }

  void _handlePointerDown(
    int pointer,
    Offset position,
    List<int> whiteNotes,
    List<int> blackNotes,
    Map<int, int> blackLeftIndex,
    double whiteKeyWidth,
    double blackKeyWidth,
    double blackKeyHeight,
  ) {
    _activePointers.add(pointer);
    if (widget.allowPinchZoom && _activePointers.length > 1) {
      _releaseTrackedPointers();
      _scaling = true;
      return;
    }
    if (_scaling && widget.allowPinchZoom) return;
    final note = _hitTest(position, whiteNotes, blackNotes, blackLeftIndex,
        whiteKeyWidth, blackKeyWidth, blackKeyHeight);
    if (note == null) return;
    _pointerToNote[pointer] = note;
    widget.onNoteOn(note);
  }

  void _handlePointerMove(
    int pointer,
    Offset position,
    List<int> whiteNotes,
    List<int> blackNotes,
    Map<int, int> blackLeftIndex,
    double whiteKeyWidth,
    double blackKeyWidth,
    double blackKeyHeight,
  ) {
    if (widget.allowPinchZoom && _activePointers.length > 1) {
      _releaseTrackedPointers();
      _scaling = true;
      return;
    }
    if (_scaling && widget.allowPinchZoom) return;
    final current = _pointerToNote[pointer];
    final next = _hitTest(position, whiteNotes, blackNotes, blackLeftIndex,
        whiteKeyWidth, blackKeyWidth, blackKeyHeight);
    if (current == next) return;
    if (current != null) {
      widget.onNoteOff(current);
      _pointerToNote.remove(pointer);
    }
    if (next != null) {
      _pointerToNote[pointer] = next;
      widget.onNoteOn(next);
    }
  }

  void _handleDesktopHover(
    int pointer,
    Offset position,
    int buttons,
    List<int> whiteNotes,
    List<int> blackNotes,
    Map<int, int> blackLeftIndex,
    double whiteKeyWidth,
    double blackKeyWidth,
    double blackKeyHeight,
  ) {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.macOS &&
        defaultTargetPlatform != TargetPlatform.windows &&
        defaultTargetPlatform != TargetPlatform.linux) {
      return;
    }
    if (buttons == 0) return;
    if (_pointerToNote.containsKey(pointer)) {
      _handlePointerMove(
        pointer,
        position,
        whiteNotes,
        blackNotes,
        blackLeftIndex,
        whiteKeyWidth,
        blackKeyWidth,
        blackKeyHeight,
      );
      return;
    }
    _handlePointerDown(
      pointer,
      position,
      whiteNotes,
      blackNotes,
      blackLeftIndex,
      whiteKeyWidth,
      blackKeyWidth,
      blackKeyHeight,
    );
  }

  void _handlePointerUp(int pointer) {
    _activePointers.remove(pointer);
    if (_activePointers.length < 2) {
      _scaling = false;
    }
    final note = _pointerToNote.remove(pointer);
    if (note != null) {
      widget.onNoteOff(note);
    }
  }

  void _releaseTrackedPointers() {
    for (final note in _pointerToNote.values.toSet()) {
      widget.onNoteOff(note);
    }
    _pointerToNote.clear();
  }

  int? _hitTest(
    Offset position,
    List<int> whiteNotes,
    List<int> blackNotes,
    Map<int, int> blackLeftIndex,
    double whiteKeyWidth,
    double blackKeyWidth,
    double blackKeyHeight,
  ) {
    if (position.dy <= blackKeyHeight) {
      for (final note in blackNotes) {
        final leftIndex = blackLeftIndex[note];
        if (leftIndex == null || leftIndex < 0) continue;
        final left =
            (leftIndex + 1) * whiteKeyWidth - (blackKeyWidth / 2);
        final rect = Rect.fromLTWH(left, 0, blackKeyWidth, blackKeyHeight);
        if (rect.contains(position)) return note;
      }
    }
    final idx =
        (position.dx / whiteKeyWidth).floor().clamp(0, whiteNotes.length - 1);
    return whiteNotes[idx];
  }
}

class _KeyboardPainter extends CustomPainter {
  final List<int> whiteNotes;
  final List<int> blackNotes;
  final Map<int, int> blackLeftIndex;
  final double whiteKeyWidth;
  final double blackKeyWidth;
  final double blackKeyHeight;
  final Set<int> activeNotes;
  final bool showLabels;
  final String Function(int) noteName;

  _KeyboardPainter({
    required this.whiteNotes,
    required this.blackNotes,
    required this.blackLeftIndex,
    required this.whiteKeyWidth,
    required this.blackKeyWidth,
    required this.blackKeyHeight,
    required this.activeNotes,
    required this.showLabels,
    required this.noteName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()..color = const Color(0xFFF7F6F2);
    final whiteActive = Paint()..color = const Color(0xFFB3E5FC);
    final blackPaint = Paint()..color = const Color(0xFF0F1115);
    final blackActive = Paint()..color = const Color(0xFF4FC3F7);
    final borderPaint = Paint()
      ..color = const Color(0x33000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < whiteNotes.length; i++) {
      final note = whiteNotes[i];
      final left = i * whiteKeyWidth;
      final rect = Rect.fromLTWH(left, 0, whiteKeyWidth, size.height);
      canvas.drawRect(rect, activeNotes.contains(note) ? whiteActive : whitePaint);
      canvas.drawRect(rect, borderPaint);

      if (showLabels) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: noteName(note),
            style: const TextStyle(
              color: Color(0xAA000000),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: whiteKeyWidth);
        textPainter.paint(
          canvas,
          Offset(left + 2, size.height - 16),
        );
      }
    }

    for (final note in blackNotes) {
      final leftIndex = blackLeftIndex[note];
      if (leftIndex == null || leftIndex < 0) continue;
      final left =
          (leftIndex + 1) * whiteKeyWidth - (blackKeyWidth / 2);
      final rect = Rect.fromLTWH(left, 0, blackKeyWidth, blackKeyHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        activeNotes.contains(note) ? blackActive : blackPaint,
      );
      if (showLabels) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: noteName(note),
            style: const TextStyle(
              color: Color(0xE6FFFFFF),
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: blackKeyWidth - 4);
        textPainter.paint(
          canvas,
          Offset(
            left + ((blackKeyWidth - textPainter.width) / 2),
            blackKeyHeight - 16,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KeyboardPainter oldDelegate) {
    return !setEquals(oldDelegate.activeNotes, activeNotes) ||
        oldDelegate.showLabels != showLabels;
  }
}
