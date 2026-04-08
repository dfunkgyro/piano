import io
import re

path = "lib/models/complete_songs_library.dart"
data = io.open(path, "r", encoding="utf-8").read()

pattern = re.compile(r"CompleteSong\\((.*?)\\)\\s*;", re.S)
out = []
last = 0

for m in pattern.finditer(data):
    block = m.group(0)
    if "timeSignature:" not in block:
        block = re.sub(
            r"(\\bkey:\\s*'[^']+'\\s*,)",
            r"\\1\\n      timeSignature: '4/4',",
            block,
            count=1,
        )
    out.append(data[last : m.start()])
    out.append(block)
    last = m.end()

out.append(data[last:])
io.open(path, "w", encoding="utf-8").write("".join(out))
