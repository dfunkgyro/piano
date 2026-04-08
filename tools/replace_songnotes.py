#!/usr/bin/env python
from __future__ import print_function

import io
import os
import sys


REPLACEMENTS = {
    "_getBachMinuetInGMajorNotes": "tools/midi_sources/minuet_g_major.dart",
    "_getChopinPreludeInEMinorNotes": "tools/midi_sources/chopin_prelude_op28_no4.dart",
    "_getSchumannTraumereiNotes": "tools/midi_sources/schumann_traumerei.dart",
    "_getFurEliseNotes": "tools/midi_sources/fur_elise.dart",
    "_getMozartFantasiaInDMinorNotes": "tools/midi_sources/mozart_fantasia_k397.dart",
    "_getBeethovenMoonlightSonataNotes": "tools/midi_sources/beethoven_moonlight_1st_cc_by_sa.dart",
    "_getDebussyClairDeLuneNotes": "tools/midi_sources/clair_de_lune.dart",
    "_getBachPreludeInCMajorNotes": "tools/midi_sources/bach_prelude_bwv846.dart",
}


def load_list(path, indent):
    with io.open(path, "r", encoding="utf-8") as f:
        lines = [line.rstrip("\n") for line in f]
    if lines:
        lines[0] = lines[0].lstrip("\ufeff")
    if not lines or lines[0].strip() != "[" or lines[-1].strip() != "]":
        raise RuntimeError("Unexpected list format in {}".format(path))
    body = []
    for line in lines[1:-1]:
        stripped = line.strip()
        if not stripped:
            continue
        body.append("{}{}".format(indent, stripped))
    return body


def replace_function_body(src, fn_name, new_body_lines):
    fn_idx = src.find("static List<SongNote> {}()".format(fn_name))
    if fn_idx == -1:
        raise RuntimeError("Function not found: {}".format(fn_name))
    ret_idx = src.find("return [", fn_idx)
    if ret_idx == -1:
        raise RuntimeError("return [ not found for {}".format(fn_name))
    start = ret_idx + len("return [")
    end = src.find("];", start)
    if end == -1:
        raise RuntimeError("]; not found for {}".format(fn_name))

    before = src[:start]
    after = src[end:]
    indent = "\n"
    body = indent + "\n".join(new_body_lines) + "\n"
    return before + body + after


def main():
    target = "lib/models/complete_songs_library.dart"
    if not os.path.exists(target):
        print("Missing target file:", target, file=sys.stderr)
        return 1
    with io.open(target, "r", encoding="utf-8") as f:
        src = f.read()

    for fn_name, list_path in REPLACEMENTS.items():
        if not os.path.exists(list_path):
            raise RuntimeError("Missing list file: {}".format(list_path))
        new_body = load_list(list_path, "      ")
        src = replace_function_body(src, fn_name, new_body)

    with io.open(target, "w", encoding="utf-8") as f:
        f.write(src)
    return 0


if __name__ == "__main__":
    sys.exit(main())
