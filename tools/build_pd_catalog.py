import io
import json
import os
import re
import sys
import time
from html import unescape as html_unescape
from html.parser import HTMLParser
from urllib.parse import urljoin
from urllib.request import urlopen, Request

import mido

SITE = "https://www.mutopiaproject.org/"
BASE = "https://www.mutopiaproject.org/ftp/"
PIECE_LIST_URL = "https://www.mutopiaproject.org/piece-list.html"
SEED_URLS = [
    "https://www.mutopiaproject.org/ftp/BeethovenLv/",
    "https://www.mutopiaproject.org/ftp/ChopinFF/",
    "https://www.mutopiaproject.org/ftp/ClementiM/",
    "https://www.mutopiaproject.org/ftp/CzernyC/",
    "https://www.mutopiaproject.org/ftp/DebussyC/",
    "https://www.mutopiaproject.org/ftp/FieldJ/",
    "https://www.mutopiaproject.org/ftp/GriegE/",
    "https://www.mutopiaproject.org/ftp/HaydnFJ/",
    "https://www.mutopiaproject.org/ftp/JoplinS/",
    "https://www.mutopiaproject.org/ftp/LisztF/",
    "https://www.mutopiaproject.org/ftp/MozartWA/",
    "https://www.mutopiaproject.org/ftp/MussorgskyM/",
    "https://www.mutopiaproject.org/ftp/SatieE/",
    "https://www.mutopiaproject.org/ftp/SchubertF/",
    "https://www.mutopiaproject.org/ftp/SchumannR/",
    "https://www.mutopiaproject.org/ftp/TchaikovskyPI/",
    "https://www.mutopiaproject.org/ftp/BurgmullerJFF/",
    "https://www.mutopiaproject.org/ftp/AlbenizIMF/",
    "https://www.mutopiaproject.org/ftp/GranadosE/",
]


class LinkParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []

    def handle_starttag(self, tag, attrs):
        if tag != "a":
            return
        for k, v in attrs:
            if k == "href":
                self.links.append(v)


def fetch(url):
    req = Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urlopen(req, timeout=30) as resp:
        return resp.read().decode("utf-8", errors="ignore")


def parse_links(html):
    parser = LinkParser()
    parser.feed(html)
    return parser.links


def rdf_tag(text, tag):
    start = text.find(f"<mp:{tag}>")
    if start == -1:
        return ""
    end = text.find(f"</mp:{tag}>", start)
    if end == -1:
        return ""
    open_tag = f"<mp:{tag}>"
    return text[start + len(open_tag) : end].strip()


def strip_tags(text):
    return re.sub(r"<[^>]+>", "", text).strip()


def parse_piece_list(html):
    class PieceListParser(HTMLParser):
        def __init__(self):
            super().__init__()
            self.rows = []
            self._in_tr = False
            self._in_td = False
            self._cells = []
            self._cell_buf = []
            self._title_href = None

        def handle_starttag(self, tag, attrs):
            if tag == "tr":
                self._in_tr = True
                self._cells = []
                self._cell_buf = []
                self._title_href = None
            elif tag == "td" and self._in_tr:
                self._in_td = True
                self._cell_buf = []
            elif tag == "a" and self._in_td:
                for k, v in attrs:
                    if k == "href" and "piece-info.cgi?id=" in v:
                        self._title_href = v

        def handle_data(self, data):
            if self._in_td:
                self._cell_buf.append(data)

        def handle_endtag(self, tag):
            if tag == "td" and self._in_td:
                text = html_unescape("".join(self._cell_buf)).strip()
                self._cells.append(text)
                self._in_td = False
            elif tag == "tr" and self._in_tr:
                if len(self._cells) >= 4 and self._title_href:
                    self.rows.append(
                        {
                            "composer": strip_tags(self._cells[0]),
                            "title": strip_tags(self._cells[1]),
                            "opus": strip_tags(self._cells[2].replace("\xa0", " ")),
                            "instruments": strip_tags(self._cells[3]),
                            "info_url": urljoin(SITE, self._title_href),
                        }
                    )
                self._in_tr = False

    parser = PieceListParser()
    parser.feed(html)
    return parser.rows


def sanitize_key(sig):
    if not sig:
        return "C Major"
    sig = sig.replace("major", "Major").replace("minor", "minor")
    return sig


def sanitize_meter(meter):
    if not meter:
        return "4/4"
    meter = meter.strip()
    if re.match(r"^\\d+\\s*/\\s*\\d+$", meter):
        return meter.replace(" ", "")
    return "4/4"


def estimate_difficulty(note_count, poly_max):
    if note_count < 400 and poly_max <= 2:
        return "Beginner"
    if note_count < 1400 and poly_max <= 4:
        return "Intermediate"
    return "Advanced"


def midi_to_notes(path):
    mid = mido.MidiFile(path, clip=True)
    ticks_per_beat = mid.ticks_per_beat
    tempo = 500000
    time_sig = "4/4"
    key_sig = None
    abs_seconds = 0.0
    active = {}
    notes = []
    poly_max = 1

    for msg in mido.merge_tracks(mid.tracks):
        abs_seconds += mido.tick2second(msg.time, ticks_per_beat, tempo)
        if msg.type == "set_tempo":
            tempo = msg.tempo
            continue
        if msg.type == "time_signature":
            time_sig = f"{msg.numerator}/{msg.denominator}"
            continue
        if msg.type == "key_signature":
            key_sig = msg.key
            continue
        if msg.type == "note_on" and msg.velocity > 0:
            key = (msg.note, msg.channel)
            active[key] = (abs_seconds, msg.velocity)
            poly_max = max(poly_max, len(active))
            continue
        if msg.type == "note_off" or (msg.type == "note_on" and msg.velocity == 0):
            key = (msg.note, msg.channel)
            if key not in active:
                continue
            start, vel = active.pop(key)
            duration = max(0.02, abs_seconds - start)
            hand = "L" if msg.note < 60 else "R"
            notes.append(
                {
                    "note": int(msg.note),
                    "time": round(start, 3),
                    "duration": round(duration, 3),
                    "hand": hand,
                    "velocity": int(vel),
                }
            )

    bpm = int(round(60000000 / tempo)) if tempo else 120
    return notes, bpm, time_sig, key_sig, poly_max


def slugify(text):
    text = re.sub(r"[^a-zA-Z0-9]+", "_", text.lower()).strip("_")
    return text[:60] or "pd_piece"


def build_catalog(
    limit=300,
    out_path="catalog/pd_catalog.json",
    workdir="tools/pd_work",
    state_path="tools/pd_work/state.json",
    max_seconds=None,
    resume=False,
    use_full_crawl=True,
):
    os.makedirs(workdir, exist_ok=True)
    midi_dir = os.path.join(workdir, "midi")
    os.makedirs(midi_dir, exist_ok=True)

    if resume and os.path.exists(state_path):
        state = json.loads(io.open(state_path, "r", encoding="utf-8").read())
        index = int(state.get("index", 0))
        catalog = state.get("catalog", [])
    else:
        index = 0
        catalog = []
    start_time = time.time()

    list_html = fetch(PIECE_LIST_URL)
    entries = parse_piece_list(list_html)
    candidates = [e for e in entries if "piano" in e["instruments"].lower()]

    while index < len(candidates) and len(catalog) < limit:
        if max_seconds is not None and (time.time() - start_time) > max_seconds:
            break
        info = candidates[index]
        index += 1

        try:
            info_html = fetch(info["info_url"])
        except Exception:
            continue

        if "public domain" not in info_html.lower():
            continue

        midi_link = None
        for href in parse_links(info_html):
            if href.lower().endswith(".mid"):
                midi_link = href
                break
        if not midi_link:
            continue

        midi_url = urljoin(info["info_url"], midi_link)
        midi_name = slugify(f"{info['composer']}_{info['title']}") + ".mid"
        midi_path = os.path.join(midi_dir, midi_name)

        if not os.path.exists(midi_path):
            try:
                data = urlopen(Request(midi_url, headers={"User-Agent": "Mozilla/5.0"}), timeout=30).read()
                with io.open(midi_path, "wb") as f:
                    f.write(data)
            except Exception:
                continue

        notes, bpm, time_sig, key_sig, poly_max = midi_to_notes(midi_path)
        if not notes:
            continue

        difficulty = estimate_difficulty(len(notes), poly_max)
        catalog.append(
            {
                "id": slugify(info["title"] + "_" + info["composer"]),
                "title": info["title"],
                "composer": info["composer"],
                "difficulty": difficulty,
                "bpm": bpm,
                "key": sanitize_key(key_sig),
                "keySignature": sanitize_key(key_sig),
                "timeSignature": time_sig,
                "notes": notes,
                "description": "Public-domain piano piece.",
                "techniques": ["Public-domain repertoire"],
            }
        )
        if len(catalog) % 10 == 0:
            _save_state(state_path, index, catalog)

        time.sleep(0.01)

    _save_state(state_path, index, catalog)

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with io.open(out_path, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False)

    return len(catalog)


def _save_state(path, index, catalog):
    state = {"index": index, "catalog": catalog}
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with io.open(path, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False)


if __name__ == "__main__":
    limit = 300
    max_seconds = None
    resume = False
    use_full_crawl = True
    if len(sys.argv) > 1:
        limit = int(sys.argv[1])
    if len(sys.argv) > 2:
        max_seconds = int(sys.argv[2])
    if len(sys.argv) > 3:
        resume = sys.argv[3].lower() == "resume"
    if len(sys.argv) > 4:
        use_full_crawl = sys.argv[4].lower() != "seed"
    out = build_catalog(
        limit=limit,
        max_seconds=max_seconds,
        resume=resume,
        use_full_crawl=use_full_crawl,
    )
    print("Catalog size:", out)
