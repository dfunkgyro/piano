import io

path = "lib/widgets/sheet_music_view.dart"
with io.open(path, "r", encoding="utf-8") as f:
    lines = f.readlines()

out = []
in_key_switch = False
flats_started = False
removed_gb = False
removed_db = False

for line in lines:
    if "int _keySignatureAccidentals" in line:
        in_key_switch = True
        flats_started = False
        removed_gb = False
        removed_db = False
    if in_key_switch and "case 'f':" in line:
        flats_started = True
    if in_key_switch and not flats_started:
        if "case 'gb':" in line and not removed_gb:
            removed_gb = True
            continue
        if "case 'db':" in line and not removed_db:
            removed_db = True
            continue
    if in_key_switch and "default:" in line:
        in_key_switch = False

    if "final accidental = count > 0 ?" in line:
        line = "    final accidental = count > 0 ? '#' : 'b';\n"

    line = line.replace("color: Colors.black87", "color: staffColor")
    line = line.replace("color: Colors.black54", "color: staffColor.withOpacity(0.8)")

    if "final staffBottom = isBass ? (lineSpacing * 4 + 26 + 24) : (lineSpacing * 4 + 24);" in line:
        line = (
            "    final staffBottom = isBass\n"
            "        ? (_topPadding + lineSpacing * 4 + _staffGap + lineSpacing * 4)\n"
            "        : (_topPadding + lineSpacing * 4);\n"
        )
    out.append(line)

updated = []
inserted = False
for i, line in enumerate(out):
    updated.append(line)
    if not inserted and "void _drawDynamics(" in line:
        inserted = True
        updated.append(
            "  void _drawArticulation(\n"
            "    Canvas canvas,\n"
            "    double playheadX,\n"
            "    double pxPerSecond,\n"
            "    double visibleStart,\n"
            "    double visibleEnd,\n"
            "    double lineSpacing,\n"
            "    {required double anchorTime}\n"
            "  ) {\n"
            "    final beatSeconds = 60.0 / bpm.clamp(30, 240);\n"
            "    final paint = Paint()..color = noteColor.withOpacity(0.8);\n"
            "    for (final note in notes) {\n"
            "      if (note.time < visibleStart || note.time > visibleEnd) continue;\n"
            "      final beats = (note.duration / beatSeconds).clamp(0.1, 4.0);\n"
            "      if (beats > 0.35) continue;\n"
            "      final x = playheadX + (note.time - anchorTime) * pxPerSecond + 8;\n"
            "      final y = _noteYFor(note, lineSpacing) - 10;\n"
            "      canvas.drawCircle(Offset(x, y), 2.2, paint);\n"
            "    }\n"
            "  }\n\n"
        )

with io.open(path, "w", encoding="utf-8") as f:
    f.writelines(updated)
