import io

path = "lib/widgets/sheet_music_view.dart"
with io.open(path, "r", encoding="utf-8") as f:
    data = f.read()

start = data.find("void _drawClefs")
end = data.find("void _drawTimeSignature", start)
if start == -1 or end == -1:
    raise SystemExit("markers not found")

new_func = (
    "void _drawClefs(Canvas canvas, double trebleTop, double bassTop) {\n"
    "    final treblePainter = TextPainter(\n"
    "      text: TextSpan(text: '\\uD834\\uDD1E', style: TextStyle(fontSize: 24, color: staffColor)),\n"
    "      textDirection: TextDirection.ltr,\n"
    "    )..layout();\n"
    "    final bassPainter = TextPainter(\n"
    "      text: TextSpan(text: '\\uD834\\uDD22', style: TextStyle(fontSize: 24, color: staffColor)),\n"
    "      textDirection: TextDirection.ltr,\n"
    "    )..layout();\n"
    "    treblePainter.paint(canvas, Offset(8, trebleTop - 10));\n"
    "    bassPainter.paint(canvas, Offset(8, bassTop - 6));\n"
    "  }\n\n  "
)

data = data[:start] + new_func + data[end:]
with io.open(path, "w", encoding="utf-8") as f:
    f.write(data)
