#!/usr/bin/env python
from __future__ import print_function

import argparse
import json
import os
import sys

import mido
from mido.midifiles import meta as _mido_meta


def parse_args():
    p = argparse.ArgumentParser(description="Convert MIDI to SongNote list.")
    p.add_argument("midi_path", help="Path to .mid file")
    p.add_argument("--hand-split", type=int, default=60, help="MIDI note below is left hand")
    p.add_argument("--min-duration", type=float, default=0.02, help="Clamp minimum note duration (seconds)")
    p.add_argument("--quantize", type=float, default=0.0, help="Quantize time to nearest step (seconds), 0 = off")
    p.add_argument("--pretty", action="store_true", help="Pretty-print Dart output")
    return p.parse_args()


def quantize(value, step):
    if step <= 0:
        return value
    return round(value / step) * step


def midi_to_events(path, hand_split, min_duration, quant_step):
    # Work around invalid key signatures found in some public MIDI files.
    if (8, 0) not in _mido_meta._key_signature_decode:
        _mido_meta._key_signature_decode[(8, 0)] = "C#"
    if (8, 1) not in _mido_meta._key_signature_decode:
        _mido_meta._key_signature_decode[(8, 1)] = "a#"

    mid = mido.MidiFile(path, clip=True)
    ticks_per_beat = mid.ticks_per_beat

    tempo = 500000  # default 120 bpm
    abs_ticks = 0
    abs_seconds = 0.0
    active = {}
    events = []

    for msg in mido.merge_tracks(mid.tracks):
        abs_ticks += msg.time
        delta_seconds = mido.tick2second(msg.time, ticks_per_beat, tempo)
        abs_seconds += delta_seconds

        if msg.type == "set_tempo":
            tempo = msg.tempo
            continue

        if msg.type == "note_on" and msg.velocity > 0:
            key = (msg.note, msg.channel)
            active[key] = (abs_seconds, msg.velocity)
            continue

        if msg.type == "note_off" or (msg.type == "note_on" and msg.velocity == 0):
            key = (msg.note, msg.channel)
            if key not in active:
                continue
            start, velocity = active.pop(key)
            duration = abs_seconds - start
            if duration < min_duration:
                duration = min_duration
            start_q = quantize(start, quant_step)
            duration_q = quantize(duration, quant_step) if quant_step > 0 else duration
            hand = "L" if msg.note < hand_split else "R"
            events.append(
                {
                    "note": msg.note,
                    "time": start_q,
                    "duration": duration_q,
                    "velocity": int(velocity),
                    "hand": hand,
                }
            )

    events.sort(key=lambda e: (e["time"], e["note"]))
    return events


def dart_list(events, pretty):
    sep = "\n" if pretty else ""
    indent = "  " if pretty else ""
    lines = []
    for e in events:
        lines.append(
            "{indent}SongNote(note: {note}, time: {time:.3f}, duration: {dur:.3f}, hand: '{hand}', velocity: {vel}),".format(
                indent=indent,
                note=e["note"],
                time=e["time"],
                dur=e["duration"],
                hand=e["hand"],
                vel=e["velocity"],
            )
        )
    if pretty:
        return "[\n{lines}\n]".format(lines="\n".join(lines))
    return "[" + sep.join(lines) + "]"


def main():
    args = parse_args()
    if not os.path.exists(args.midi_path):
        print("Missing file:", args.midi_path, file=sys.stderr)
        return 1
    events = midi_to_events(args.midi_path, args.hand_split, args.min_duration, args.quantize)
    print(dart_list(events, args.pretty))
    return 0


if __name__ == "__main__":
    sys.exit(main())
