import 'package:flutter/material.dart';

enum ScoreLayoutMode { scroll, page }

class ScoreNote {
  final int midiNote;
  final double time;
  final double duration;
  final String hand;
  final int velocity;

  ScoreNote({
    required this.midiNote,
    required this.time,
    required this.duration,
    required this.hand,
    this.velocity = 100,
  });
}

class SheetMusicView extends StatelessWidget {
  final List<ScoreNote> notes;
  final Set<int> activeNotes;
  final double currentTime;
  final double bpm;
  final double windowSeconds;
  final double playheadFraction;
  final double futureWindowFraction;
  final String keySignature;
  final String timeSignature;
  final ScoreLayoutMode layoutMode;
  final int? pageIndex;
  final double? pageSeconds;
  final bool showMeasureNumbers;
  final bool showSectionMarkers;
  final int sectionEveryMeasures;
  final Color backgroundColor;
  final Color staffColor;
  final Color noteColor;
  final Color activeColor;
  final Color playheadColor;
  final double staffScale;

  const SheetMusicView({
    super.key,
    required this.notes,
    required this.activeNotes,
    required this.currentTime,
    required this.bpm,
    this.windowSeconds = 8.0,
    this.playheadFraction = 0.25,
    this.futureWindowFraction = 0.8,
    this.keySignature = 'C Major',
    this.timeSignature = '4/4',
    this.layoutMode = ScoreLayoutMode.scroll,
    this.pageIndex,
    this.pageSeconds,
    this.showMeasureNumbers = true,
    this.showSectionMarkers = true,
    this.sectionEveryMeasures = 8,
    required this.backgroundColor,
    required this.staffColor,
    required this.noteColor,
    required this.activeColor,
    required this.playheadColor,
    this.staffScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SheetMusicPainter(
        notes: notes,
        activeNotes: activeNotes,
        currentTime: currentTime,
        bpm: bpm,
        windowSeconds: windowSeconds,
        playheadFraction: playheadFraction,
        futureWindowFraction: futureWindowFraction,
        keySignature: keySignature,
        timeSignature: timeSignature,
        layoutMode: layoutMode,
        pageIndex: pageIndex,
        pageSeconds: pageSeconds,
        showMeasureNumbers: showMeasureNumbers,
        showSectionMarkers: showSectionMarkers,
        sectionEveryMeasures: sectionEveryMeasures,
        backgroundColor: backgroundColor,
        staffColor: staffColor,
        noteColor: noteColor,
        activeColor: activeColor,
        playheadColor: playheadColor,
        staffScale: staffScale,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SheetMusicPainter extends CustomPainter {
  static const double _topPadding = 24.0;
  static const double _staffGap = 26.0;
  final List<ScoreNote> notes;
  final Set<int> activeNotes;
  final double currentTime;
  final double bpm;
  final double windowSeconds;
  final double playheadFraction;
  final double futureWindowFraction;
  final String keySignature;
  final String timeSignature;
  final ScoreLayoutMode layoutMode;
  final int? pageIndex;
  final double? pageSeconds;
  final bool showMeasureNumbers;
  final bool showSectionMarkers;
  final int sectionEveryMeasures;
  final Color backgroundColor;
  final Color staffColor;
  final Color noteColor;
  final Color activeColor;
  final Color playheadColor;
  final double staffScale;

  _SheetMusicPainter({
    required this.notes,
    required this.activeNotes,
    required this.currentTime,
    required this.bpm,
    required this.windowSeconds,
    required this.playheadFraction,
    required this.futureWindowFraction,
    required this.keySignature,
    required this.timeSignature,
    required this.layoutMode,
    required this.pageIndex,
    required this.pageSeconds,
    required this.showMeasureNumbers,
    required this.showSectionMarkers,
    required this.sectionEveryMeasures,
    required this.backgroundColor,
    required this.staffColor,
    required this.noteColor,
    required this.activeColor,
    required this.playheadColor,
    this.staffScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    canvas.drawRect(
      Offset.zero & size,
      paint..color = backgroundColor,
    );

    final staffLine = Paint()
      ..color = staffColor.withOpacity(0.6)
      ..strokeWidth = 1.0;

    final lineSpacing = (10.0 * staffScale.clamp(0.7, 1.4)).toDouble();
    final staffHeight = lineSpacing * 4;

    final trebleTop = _topPadding;
    final trebleBottom = trebleTop + staffHeight;
    final bassTop = trebleBottom + _staffGap;
    final bassBottom = bassTop + staffHeight;

    _drawStaff(canvas, staffLine, trebleTop, lineSpacing, size.width);
    _drawStaff(canvas, staffLine, bassTop, lineSpacing, size.width);

    final playheadX = layoutMode == ScoreLayoutMode.scroll
        ? size.width * playheadFraction.clamp(0.05, 0.95)
        : 16.0;
    final pxPerSecond = size.width / windowSeconds;
    final postSeconds = windowSeconds * futureWindowFraction.clamp(0.0, 1.0);
    final preSeconds = windowSeconds - postSeconds;
    final measureSeconds = _measureSeconds();

    final resolvedPageSeconds = layoutMode == ScoreLayoutMode.page
        ? (pageSeconds ?? (measureSeconds * 4)
            .clamp(measureSeconds * 2, measureSeconds * 8))
        : windowSeconds;
    final pageStart =
        layoutMode == ScoreLayoutMode.page && measureSeconds > 0.0
            ? ((pageIndex ?? (currentTime / resolvedPageSeconds).floor()) *
                resolvedPageSeconds)
            : 0.0;

    _drawMeasureLines(
      canvas,
      staffLine,
      size,
      playheadX,
      pxPerSecond,
      trebleTop,
      bassBottom,
      measureSeconds,
      pageStart,
      resolvedPageSeconds,
    );

    _drawPlayhead(canvas, playheadX, trebleTop, bassBottom);
    _drawClefs(canvas, trebleTop, bassTop);
    _drawTimeSignature(canvas, trebleTop, bassTop);
    _drawKeySignature(canvas, trebleTop, bassTop, lineSpacing);

    final visibleStart = layoutMode == ScoreLayoutMode.page
        ? pageStart
        : currentTime - preSeconds;
    final visibleEnd = layoutMode == ScoreLayoutMode.page
        ? pageStart + resolvedPageSeconds
        : currentTime + windowSeconds;

    for (final note in notes) {
      if (note.time < visibleStart || note.time > visibleEnd) continue;
      final anchorTime =
          layoutMode == ScoreLayoutMode.page ? pageStart : currentTime;
      final x = playheadX + (note.time - anchorTime) * pxPerSecond;
      if (x < -20 || x > size.width + 20) continue;

      final isBass = _isBass(note);
      final staffBottom = isBass ? bassBottom : trebleBottom;
      final refNote = isBass ? 43 : 64; // G2 or E4
      final refIndex = _diatonicIndex(refNote);
      final noteIndex = _diatonicIndex(note.midiNote);
      final step = (noteIndex - refIndex).toDouble();
      final y = staffBottom - step * (lineSpacing / 2);

      _drawLedgerLines(
        canvas,
        staffLine,
        x,
        y,
        isBass ? bassTop : trebleTop,
        staffBottom,
        lineSpacing,
      );

      final isActive = activeNotes.contains(note.midiNote);
      final color = isActive ? activeColor : noteColor;

      final stemUp = _stemUp(isBass, noteIndex, refIndex);
      _drawNoteHead(
        canvas,
        Offset(x, y),
        note,
        color,
        lineSpacing,
        stemUp,
      );

      _drawAccidental(canvas, note, Offset(x, y), color);
    }

    _drawBeams(
      canvas,
      size,
      trebleTop,
      bassTop,
      trebleBottom,
      bassBottom,
      lineSpacing,
      playheadX,
      pxPerSecond,
      visibleStart,
      visibleEnd,
      anchorTime: layoutMode == ScoreLayoutMode.page ? pageStart : currentTime,
    );
    _drawTies(
      canvas,
      playheadX,
      pxPerSecond,
      visibleStart,
      visibleEnd,
      lineSpacing,
      anchorTime: layoutMode == ScoreLayoutMode.page ? pageStart : currentTime,
    );
    _drawSlurs(
      canvas,
      playheadX,
      pxPerSecond,
      visibleStart,
      visibleEnd,
      lineSpacing,
      anchorTime: layoutMode == ScoreLayoutMode.page ? pageStart : currentTime,
    );
    _drawArticulation(
      canvas,
      playheadX,
      pxPerSecond,
      visibleStart,
      visibleEnd,
      lineSpacing,
      anchorTime: layoutMode == ScoreLayoutMode.page ? pageStart : currentTime,
    );
    _drawDynamics(
      canvas,
      trebleTop,
      bassBottom,
      playheadX,
      pxPerSecond,
      visibleStart,
      visibleEnd,
      anchorTime: layoutMode == ScoreLayoutMode.page ? pageStart : currentTime,
    );
  }

  void _drawStaff(
    Canvas canvas,
    Paint paint,
    double top,
    double lineSpacing,
    double width,
  ) {
    for (int i = 0; i < 5; i++) {
      final y = top + i * lineSpacing;
      canvas.drawLine(Offset(0, y), Offset(width, y), paint);
    }
  }

  void _drawPlayhead(
    Canvas canvas,
    double x,
    double top,
    double bottom,
  ) {
    final paint = Paint()
      ..color = playheadColor
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(x, top - 8), Offset(x, bottom + 8), paint);
  }

  void _drawMeasureLines(
    Canvas canvas,
    Paint staffLine,
    Size size,
    double playheadX,
    double pxPerSecond,
    double top,
    double bottom,
    double measureSeconds,
    double pageStart,
    double pageSeconds,
  ) {
    if (measureSeconds <= 0) return;
    final startTime = layoutMode == ScoreLayoutMode.page
        ? pageStart
        : currentTime - windowSeconds;
    final endTime = layoutMode == ScoreLayoutMode.page
        ? pageStart + pageSeconds
        : currentTime + windowSeconds;
    final startMeasure = (startTime / measureSeconds).floor();
    final endMeasure = (endTime / measureSeconds).ceil();
    for (int i = startMeasure; i <= endMeasure; i++) {
      final t = i * measureSeconds;
      final anchorTime =
          layoutMode == ScoreLayoutMode.page ? pageStart : currentTime;
      final x = playheadX + (t - anchorTime) * pxPerSecond;
      if (x < 0 || x > size.width) continue;
      canvas.drawLine(
        Offset(x, top - 6),
        Offset(x, bottom + 6),
        staffLine,
      );
      if (showMeasureNumbers) {
        _drawMeasureNumber(canvas, i + 1, x + 2, top - 20);
      }
      if (showSectionMarkers &&
          sectionEveryMeasures > 0 &&
          ((i + 1) % sectionEveryMeasures == 1)) {
        _drawSectionMarker(canvas, i + 1, x + 2, top - 36);
      }
    }
  }

  void _drawNoteHead(
    Canvas canvas,
    Offset center,
    ScoreNote note,
    Color color,
    double lineSpacing,
    bool stemUp,
  ) {
    final beatSeconds = 60.0 / bpm.clamp(30, 240);
    final beats = (note.duration / beatSeconds).clamp(0.1, 8.0);

    final radiusX = lineSpacing * 0.55;
    final radiusY = lineSpacing * 0.38;
    final rect = Rect.fromCenter(
      center: center,
      width: radiusX * 2,
      height: radiusY * 2,
    );

    final isHollow = beats >= 2.0;
    final paint = Paint()
      ..color = color
      ..style = isHollow ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = 1.6;
    canvas.drawOval(rect, paint);

    _drawStemAndFlags(canvas, center, beats, color, lineSpacing, stemUp);
  }

  void _drawStemAndFlags(
    Canvas canvas,
    Offset center,
    double beats,
    Color color,
    double lineSpacing,
    bool stemUp,
  ) {
    final stemPaint = Paint()
      ..color = color
      ..strokeWidth = 1.4;

    final stemHeight = lineSpacing * 3.2;
    final stemX = center.dx + (stemUp ? lineSpacing * 0.45 : -lineSpacing * 0.45);
    final stemStart = Offset(stemX, center.dy);
    final stemEnd = Offset(
      stemX,
      center.dy + (stemUp ? -stemHeight : stemHeight),
    );
    canvas.drawLine(stemStart, stemEnd, stemPaint);

    if (beats < 1.0) {
      _drawFlag(canvas, stemEnd, stemUp, color, lineSpacing, 1);
    }
    if (beats < 0.5) {
      _drawFlag(canvas, stemEnd, stemUp, color, lineSpacing, 2);
    }
  }

  void _drawFlag(
    Canvas canvas,
    Offset stemEnd,
    bool stemUp,
    Color color,
    double lineSpacing,
    int index,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4;
    final dir = stemUp ? 1 : -1;
    final y = stemEnd.dy + dir * (index == 1 ? 4 : 8);
    final x = stemEnd.dx;
    canvas.drawLine(
      Offset(x, y),
      Offset(x + (stemUp ? 10 : -10), y + dir * 4),
      paint,
    );
  }

  void _drawLedgerLines(
    Canvas canvas,
    Paint staffLine,
    double x,
    double y,
    double staffTop,
    double staffBottom,
    double lineSpacing,
  ) {
    if (y >= staffTop && y <= staffBottom) return;
    final half = lineSpacing / 2;
    double lineY;
    if (y < staffTop) {
      lineY = staffTop;
      while (y < lineY - half) {
        lineY -= lineSpacing;
        canvas.drawLine(
          Offset(x - 10, lineY),
          Offset(x + 10, lineY),
          staffLine,
        );
      }
    } else {
      lineY = staffBottom;
      while (y > lineY + half) {
        lineY += lineSpacing;
        canvas.drawLine(
          Offset(x - 10, lineY),
          Offset(x + 10, lineY),
          staffLine,
        );
      }
    }
  }

  void _drawAccidental(
    Canvas canvas,
    ScoreNote note,
    Offset center,
    Color color,
  ) {
    final accidental = _accidentalFor(note.midiNote);
    if (accidental == null) return;
    final textPainter = TextPainter(
      text: TextSpan(
        text: accidental,
        style: TextStyle(
          color: color.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - 16, center.dy - 8),
    );
  }

  bool _isBass(ScoreNote note) {
    if (note.hand == 'L') return true;
    if (note.hand == 'R') return false;
    return note.midiNote < 60;
  }

  bool _stemUp(bool isBass, int noteIndex, int refIndex) {
    final mid = refIndex + 4; // Middle line of staff.
    if (isBass) {
      return noteIndex < mid;
    }
    return noteIndex < mid;
  }

  void _drawClefs(Canvas canvas, double trebleTop, double bassTop) {
    final treblePainter = TextPainter(
      text: TextSpan(text: '\uD834\uDD1E', style: TextStyle(fontSize: 24, color: staffColor)),
      textDirection: TextDirection.ltr,
    )..layout();
    final bassPainter = TextPainter(
      text: TextSpan(text: '\uD834\uDD22', style: TextStyle(fontSize: 24, color: staffColor)),
      textDirection: TextDirection.ltr,
    )..layout();
    treblePainter.paint(canvas, Offset(8, trebleTop - 10));
    bassPainter.paint(canvas, Offset(8, bassTop - 6));
  }

  void _drawTimeSignature(Canvas canvas, double trebleTop, double bassTop) {
    final parts = timeSignature.split('/');
    if (parts.length != 2) return;
    final painter = TextPainter(
      text: TextSpan(
        text: '${parts[0]}\n${parts[1]}',
        style: TextStyle(fontSize: 14, color: staffColor),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    painter.paint(canvas, Offset(46, trebleTop - 2));
    painter.paint(canvas, Offset(46, bassTop - 2));
  }

  void _drawKeySignature(
    Canvas canvas,
    double trebleTop,
    double bassTop,
    double lineSpacing,
  ) {
    final key = keySignature.toLowerCase();
    final count = _keySignatureAccidentals(key);
    if (count == 0) return;
    final accidental = count > 0 ? '#' : 'b';
    final num = count.abs();
    final painter = TextPainter(
      text: TextSpan(
        text: List.filled(num, accidental).join(' '),
        style: TextStyle(fontSize: 14, color: staffColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(70, trebleTop - lineSpacing));
    painter.paint(canvas, Offset(70, bassTop - lineSpacing));
  }

  int _keySignatureAccidentals(String key) {
    final cleaned = key
        .replaceAll('major', '')
        .replaceAll('minor', '')
        .replaceAll('maj', '')
        .replaceAll('min', '')
        .trim();
    switch (cleaned) {
      case 'c':
        return 0;
      case 'g':
        return 1;
      case 'd':
        return 2;
      case 'a':
        return 3;
      case 'e':
        return 4;
      case 'b':
        return 5;
      case 'f#':
        return 6;
      case 'c#':
        return 7;
      case 'f':
        return -1;
      case 'bb':
        return -2;
      case 'eb':
        return -3;
      case 'ab':
        return -4;
      case 'db':
        return -5;
      case 'gb':
        return -6;
      case 'cb':
        return -7;
      default:
        return 0;
    }
  }

  void _drawMeasureNumber(
    Canvas canvas,
    int measure,
    double x,
    double y,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: measure.toString(),
        style: TextStyle(fontSize: 10, color: staffColor.withOpacity(0.8)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(x, y));
  }

  void _drawSectionMarker(
    Canvas canvas,
    int measure,
    double x,
    double y,
  ) {
    final index = ((measure - 1) ~/ sectionEveryMeasures) % 8;
    final label = String.fromCharCode('A'.codeUnitAt(0) + index);
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(fontSize: 11, color: staffColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(x, y));
  }

  void _drawBeams(
    Canvas canvas,
    Size size,
    double trebleTop,
    double bassTop,
    double trebleBottom,
    double bassBottom,
    double lineSpacing,
    double playheadX,
    double pxPerSecond,
    double visibleStart,
    double visibleEnd,
    {required double anchorTime}
  ) {
    final baseBeatSeconds = _baseBeatSeconds();
    final beamGroupSeconds = _beamGroupSeconds();
    final measureSeconds = _measureSeconds();
    final beamPaint = Paint()
      ..color = noteColor.withOpacity(0.85)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    List<ScoreNote> group = [];
    double lastTime = -999;
    int currentMeasure = -1;
    int currentBeamGroup = -1;
    double minBeats = 9;
    for (final note in notes) {
      if (note.time < visibleStart || note.time > visibleEnd) continue;
      final beats = (note.duration / baseBeatSeconds).clamp(0.1, 4.0);
      final isBeamCandidate = beats <= 0.5;
      final gap = (note.time - lastTime);
      final measureIndex =
          measureSeconds > 0 ? (note.time / measureSeconds).floor() : 0;
      final beamGroupIndex = beamGroupSeconds > 0
          ? ((note.time - (measureIndex * measureSeconds)) / beamGroupSeconds)
              .floor()
          : 0;
      final groupChanged = !isBeamCandidate ||
          measureIndex != currentMeasure ||
          beamGroupIndex != currentBeamGroup ||
          gap > baseBeatSeconds * 1.25;
      if (groupChanged) {
        _drawBeamGroup(
          canvas,
          group,
          lineSpacing,
          playheadX,
          pxPerSecond,
          anchorTime,
          beamPaint,
          minBeats,
        );
        group = [];
        minBeats = 9;
      }
      if (isBeamCandidate) {
        group.add(note);
        lastTime = note.time;
        currentMeasure = measureIndex;
        currentBeamGroup = beamGroupIndex;
        if (beats < minBeats) minBeats = beats;
      }
    }
    _drawBeamGroup(
      canvas,
      group,
      lineSpacing,
      playheadX,
      pxPerSecond,
      anchorTime,
      beamPaint,
      minBeats,
    );
  }

  void _drawBeamGroup(
    Canvas canvas,
    List<ScoreNote> group,
    double lineSpacing,
    double playheadX,
    double pxPerSecond,
    double anchorTime,
    Paint beamPaint,
    double minBeats,
  ) {
    if (group.length < 2) return;
    final first = group.first;
    final last = group.last;
    final x1 = playheadX + (first.time - anchorTime) * pxPerSecond;
    final x2 = playheadX + (last.time - anchorTime) * pxPerSecond;
    final y1 = _stemYFor(first, lineSpacing);
    final y2 = _stemYFor(last, lineSpacing);
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), beamPaint);
    if (minBeats <= 0.25) {
      canvas.drawLine(
        Offset(x1, y1 + 6),
        Offset(x2, y2 + 6),
        beamPaint,
      );
    }
  }

  double _stemYFor(ScoreNote note, double lineSpacing) {
    final isBass = _isBass(note);
    final staffBottom = isBass
        ? (_topPadding + lineSpacing * 4 + _staffGap + lineSpacing * 4)
        : (_topPadding + lineSpacing * 4);
    final refNote = isBass ? 43 : 64;
    final refIndex = _diatonicIndex(refNote);
    final noteIndex = _diatonicIndex(note.midiNote);
    final step = (noteIndex - refIndex).toDouble();
    final y = staffBottom - step * (lineSpacing / 2);
    final stemUp = _stemUp(isBass, noteIndex, refIndex);
    final stemHeight = lineSpacing * 3.2;
    return y + (stemUp ? -stemHeight : stemHeight);
  }

  void _drawTies(
    Canvas canvas,
    double playheadX,
    double pxPerSecond,
    double visibleStart,
    double visibleEnd,
    double lineSpacing,
    {required double anchorTime}
  ) {
    final paint = Paint()
      ..color = noteColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (int i = 1; i < notes.length; i++) {
      final a = notes[i - 1];
      final b = notes[i];
      if (a.midiNote != b.midiNote) continue;
      if ((b.time - (a.time + a.duration)).abs() > 0.08) continue;
      if (a.time < visibleStart || b.time > visibleEnd) continue;
      final x1 = playheadX + (a.time - anchorTime) * pxPerSecond;
      final x2 = playheadX + (b.time - anchorTime) * pxPerSecond;
      final y = _noteYFor(a, lineSpacing);
      final ctrlY = y - 8;
      final path = Path()
        ..moveTo(x1, y)
        ..quadraticBezierTo((x1 + x2) / 2, ctrlY, x2, y);
      canvas.drawPath(path, paint);
    }
  }

  void _drawArticulation(
    Canvas canvas,
    double playheadX,
    double pxPerSecond,
    double visibleStart,
    double visibleEnd,
    double lineSpacing,
    {required double anchorTime}
  ) {
    final beatSeconds = 60.0 / bpm.clamp(30, 240);
    final paint = Paint()..color = noteColor.withOpacity(0.8);
    for (final note in notes) {
      if (note.time < visibleStart || note.time > visibleEnd) continue;
      final beats = (note.duration / beatSeconds).clamp(0.1, 4.0);
      if (beats > 0.35) continue;
      final x = playheadX + (note.time - anchorTime) * pxPerSecond + 8;
      final y = _noteYFor(note, lineSpacing) - 10;
      canvas.drawCircle(Offset(x, y), 2.2, paint);
    }
  }

  void _drawSlurs(
    Canvas canvas,
    double playheadX,
    double pxPerSecond,
    double visibleStart,
    double visibleEnd,
    double lineSpacing,
    {required double anchorTime}
  ) {
    final beatSeconds = 60.0 / bpm.clamp(30, 240);
    final paint = Paint()
      ..color = noteColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    ScoreNote? last;
    for (final note in notes) {
      if (note.time < visibleStart || note.time > visibleEnd) continue;
      if (last != null) {
        final gap = note.time - last.time;
        if (gap <= beatSeconds && note.hand == last.hand) {
          final x1 = playheadX + (last.time - anchorTime) * pxPerSecond;
          final x2 = playheadX + (note.time - anchorTime) * pxPerSecond;
          final y = _noteYFor(last, lineSpacing) - 14;
          final path = Path()
            ..moveTo(x1, y)
            ..quadraticBezierTo((x1 + x2) / 2, y - 8, x2, y);
          canvas.drawPath(path, paint);
        }
      }
      last = note;
    }
  }

  void _drawDynamics(
    Canvas canvas,
    double trebleTop,
    double bassBottom,
    double playheadX,
    double pxPerSecond,
    double visibleStart,
    double visibleEnd,
    {required double anchorTime}
  ) {
    if (notes.isEmpty) return;
    final first = notes.firstWhere((n) => n.time >= visibleStart,
        orElse: () => notes.first);
    final dynamic = _velocityToDynamic(first.velocity);
    if (dynamic == null) return;
    final x = playheadX + (first.time - anchorTime) * pxPerSecond;
    final painter = TextPainter(
      text: TextSpan(
        text: dynamic,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: staffColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(x, bassBottom + 10));
  }

  String? _velocityToDynamic(int velocity) {
    if (velocity >= 110) return 'ff';
    if (velocity >= 95) return 'f';
    if (velocity >= 80) return 'mf';
    if (velocity >= 65) return 'mp';
    if (velocity >= 50) return 'p';
    return 'pp';
  }

  double _noteYFor(ScoreNote note, double lineSpacing) {
    final isBass = _isBass(note);
    final staffBottom = isBass
        ? (_topPadding + lineSpacing * 4 + _staffGap + lineSpacing * 4)
        : (_topPadding + lineSpacing * 4);
    final refNote = isBass ? 43 : 64;
    final refIndex = _diatonicIndex(refNote);
    final noteIndex = _diatonicIndex(note.midiNote);
    final step = (noteIndex - refIndex).toDouble();
    return staffBottom - step * (lineSpacing / 2);
  }

  double _measureSeconds() {
    final parts = timeSignature.split('/');
    if (parts.length != 2) return (60.0 / bpm.clamp(30, 240)) * 4;
    final top = double.tryParse(parts[0]) ?? 4.0;
    final bottom = double.tryParse(parts[1]) ?? 4.0;
    final beat = 60.0 / bpm.clamp(30, 240);
    final unit = 4.0 / bottom;
    return beat * top * unit;
  }

  double _baseBeatSeconds() {
    final parts = timeSignature.split('/');
    final bottom = parts.length == 2 ? double.tryParse(parts[1]) ?? 4.0 : 4.0;
    final beat = 60.0 / bpm.clamp(30, 240);
    final unit = 4.0 / bottom;
    return beat * unit;
  }

  double _beamGroupSeconds() {
    final parts = timeSignature.split('/');
    if (parts.length != 2) return _baseBeatSeconds();
    final top = int.tryParse(parts[0]) ?? 4;
    final bottom = int.tryParse(parts[1]) ?? 4;
    final base = _baseBeatSeconds();
    if (bottom == 8 && top % 3 == 0) {
      return base * 3;
    }
    return base;
  }

  int _diatonicIndex(int midiNote) {
    final octave = (midiNote ~/ 12) - 1;
    final pitchClass = midiNote % 12;
    final letter = _diatonicLetterIndex(pitchClass);
    return octave * 7 + letter;
  }

  int _diatonicLetterIndex(int pitchClass) {
    switch (pitchClass) {
      case 0: // C
      case 1: // C#
        return 0;
      case 2: // D
      case 3: // D#
        return 1;
      case 4: // E
        return 2;
      case 5: // F
      case 6: // F#
        return 3;
      case 7: // G
      case 8: // G#
        return 4;
      case 9: // A
      case 10: // A#
        return 5;
      case 11: // B
        return 6;
      default:
        return 0;
    }
  }

  String? _accidentalFor(int midiNote) {
    switch (midiNote % 12) {
      case 1:
      case 3:
      case 6:
      case 8:
      case 10:
        return '#';
      default:
        return null;
    }
  }

  @override
  bool shouldRepaint(covariant _SheetMusicPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime ||
        oldDelegate.notes != notes ||
        oldDelegate.activeNotes != activeNotes ||
        oldDelegate.layoutMode != layoutMode ||
        oldDelegate.playheadFraction != playheadFraction ||
        oldDelegate.futureWindowFraction != futureWindowFraction ||
        oldDelegate.keySignature != keySignature ||
        oldDelegate.timeSignature != timeSignature;
  }
}
