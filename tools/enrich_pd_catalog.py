import json
from pathlib import Path


CATALOG_PATH = Path("catalog/pd_catalog.json")


def normalize(text: str) -> str:
    return "".join(ch.lower() if ch.isalnum() else " " for ch in text).split()


def dedupe_key(song):
    return (
        " ".join(normalize(song.get("title", ""))),
        " ".join(normalize(song.get("composer", ""))),
    )


def infer_labels(song):
    title = " ".join(normalize(song.get("title", "")))
    composer = " ".join(normalize(song.get("composer", "")))
    desc = " ".join(normalize(song.get("description", "")))
    tech = " ".join(normalize(" ".join(song.get("techniques", []))))
    hay = f"{title} {composer} {desc} {tech}"
    labels = set(song.get("techniques", []))

    def add(*items):
        labels.update(items)

    if any(k in hay for k in ["twinkle", "mary had", "old macdonald", "london bridge", "frere jacques", "row row row", "nursery"]):
        add("Nursery Rhymes", "Children", "Traditional melody")
    if any(k in hay for k in ["requiem", "sonata", "symphony", "eine kleine", "fur elise", "moonlight", "clair de lune"]):
        add("Masterpieces", "Iconic repertoire")
    if any(k in hay for k in ["bach", "handel", "scarlatti"]):
        add("Baroque")
    if any(k in hay for k in ["mozart", "beethoven", "haydn", "clementi"]):
        add("Classical")
    if any(k in hay for k in ["chopin", "schumann", "schubert", "liszt", "grieg"]):
        add("Romantic")
    if any(k in hay for k in ["carol", "christmas", "silent night", "jingle"]):
        add("Seasonal")
    if any(k in hay for k in ["wedding", "bridal chorus", "canon in d", "wedding march"]):
        add("Wedding")
    if any(k in hay for k in ["birthday", "celebration"]):
        add("Celebration")
    if any(k in hay for k in ["spiritual", "gospel", "amazing grace"]):
        add("Soul", "R&B")
    if any(k in hay for k in ["ballad", "popular song", "ragtime"]):
        add("Pop")
    return sorted(labels)


def build_song(song_id, title, composer, bpm, key, time_signature, melody, left_roots, description, labels):
    notes = []
    beat = 60.0 / bpm
    current = 0.0
    for idx, (note, beats) in enumerate(melody):
        duration = round(beats * beat, 3)
        notes.append({
            "note": note,
            "time": round(current, 3),
            "duration": duration,
            "hand": "R",
            "velocity": 96,
        })
        root = left_roots[idx % len(left_roots)]
        chord_time = round(current, 3)
        for offset in (0, 7, 12):
            notes.append({
                "note": root + offset,
                "time": chord_time,
                "duration": duration,
                "hand": "L",
                "velocity": 78,
            })
        current += duration
    return {
        "id": song_id,
        "title": title,
        "composer": composer,
        "difficulty": "Beginner",
        "bpm": bpm,
        "key": key,
        "keySignature": key,
        "timeSignature": time_signature,
        "notes": notes,
        "description": description,
        "techniques": sorted(set(labels)),
    }


MANUAL_SONGS = [
    build_song(
        "twinkle_full_traditional",
        "Twinkle Twinkle Little Star",
        "Traditional",
        96,
        "C Major",
        "4/4",
        [(60, 1), (60, 1), (67, 1), (67, 1), (69, 1), (69, 1), (67, 2),
         (65, 1), (65, 1), (64, 1), (64, 1), (62, 1), (62, 1), (60, 2)] * 2,
        [36, 41, 43, 36],
        "Full nursery-rhyme arrangement with repeated verse structure for beginner piano.",
        ["Nursery Rhymes", "Children", "Traditional melody"],
    ),
    build_song(
        "mary_had_full_traditional",
        "Mary Had a Little Lamb",
        "Traditional",
        100,
        "C Major",
        "4/4",
        [(64, 1), (62, 1), (60, 1), (62, 1), (64, 1), (64, 1), (64, 2),
         (62, 1), (62, 1), (62, 2), (64, 1), (67, 1), (67, 2),
         (64, 1), (62, 1), (60, 1), (62, 1), (64, 1), (64, 1), (64, 2)] * 2,
        [36, 43, 41, 36],
        "Expanded nursery-rhyme arrangement with simple left-hand support.",
        ["Nursery Rhymes", "Children", "Traditional melody"],
    ),
    build_song(
        "old_macdonald_full_traditional",
        "Old MacDonald Had a Farm",
        "Traditional",
        104,
        "C Major",
        "4/4",
        [(60, 1), (60, 1), (60, 1), (67, 1), (69, 1), (69, 1), (67, 2),
         (64, 1), (64, 1), (62, 1), (62, 1), (60, 2)] * 3,
        [36, 41, 43, 36],
        "Full singalong version arranged for piano practice.",
        ["Nursery Rhymes", "Children", "Traditional melody"],
    ),
    build_song(
        "london_bridge_full_traditional",
        "London Bridge Is Falling Down",
        "Traditional",
        98,
        "C Major",
        "4/4",
        [(67, 1), (68, 1), (67, 1), (65, 1), (64, 1), (65, 1), (67, 2),
         (62, 1), (64, 1), (65, 2), (64, 1), (65, 1), (67, 2)] * 2,
        [36, 43, 41, 36],
        "Traditional nursery tune arranged as a complete beginner piano song.",
        ["Nursery Rhymes", "Children", "Traditional melody"],
    ),
    build_song(
        "frere_jacques_full_traditional",
        "Frere Jacques",
        "Traditional",
        92,
        "C Major",
        "4/4",
        [(60, 1), (62, 1), (64, 1), (60, 1),
         (60, 1), (62, 1), (64, 1), (60, 1),
         (64, 1), (65, 1), (67, 2),
         (64, 1), (65, 1), (67, 2),
         (67, 0.5), (69, 0.5), (67, 0.5), (65, 0.5), (64, 1), (60, 1),
         (67, 0.5), (69, 0.5), (67, 0.5), (65, 0.5), (64, 1), (60, 1)] * 2,
        [36, 43, 41, 36],
        "Full traditional round arranged for piano with steady harmony.",
        ["Nursery Rhymes", "Children", "Traditional melody"],
    ),
    build_song(
        "row_row_row_full_traditional",
        "Row Row Row Your Boat",
        "Traditional",
        90,
        "C Major",
        "3/4",
        [(60, 1), (60, 1), (60, 1), (62, 0.5), (64, 0.5),
         (64, 1), (62, 0.5), (64, 0.5), (65, 0.5), (67, 1.5),
         (72, 0.5), (72, 0.5), (72, 0.5), (67, 0.5), (67, 0.5), (67, 0.5),
         (64, 0.5), (64, 0.5), (64, 0.5), (60, 0.5), (60, 0.5), (60, 0.5),
         (67, 1), (65, 0.5), (64, 0.5), (62, 1), (60, 2)] * 2,
        [36, 43, 41],
        "Complete beginner arrangement of the classic rowing song.",
        ["Nursery Rhymes", "Children", "Traditional melody"],
    ),
    build_song(
        "greensleeves_full_traditional",
        "Greensleeves",
        "Traditional",
        88,
        "A minor",
        "3/4",
        [(69, 1), (72, 1), (74, 1), (76, 1), (77, 1), (76, 1),
         (74, 1), (72, 1), (71, 1), (69, 1), (71, 1), (72, 2)] * 3,
        [45, 40, 43],
        "Full traditional air arranged for piano with a simple accompaniment.",
        ["Traditional", "Folk", "Masterpieces"],
    ),
    build_song(
        "amazing_grace_full_traditional",
        "Amazing Grace",
        "Traditional",
        72,
        "G Major",
        "3/4",
        [(67, 1), (72, 2), (71, 1), (72, 2), (71, 1), (69, 2),
         (67, 1), (64, 2), (67, 1), (72, 2), (71, 1), (72, 2), (71, 1), (69, 3)] * 2,
        [43, 38, 43],
        "Complete hymn-style arrangement suitable for expressive beginner practice.",
        ["Traditional", "Sacred", "Soul"],
    ),
    build_song(
        "auld_lang_syne_full_traditional",
        "Auld Lang Syne",
        "Traditional",
        90,
        "F Major",
        "4/4",
        [(60, 1), (65, 1), (65, 1), (65, 1), (69, 1), (67, 2),
         (65, 1), (67, 1), (69, 1), (67, 1), (65, 2), (62, 2)] * 2,
        [41, 36, 43, 41],
        "Full public-domain New Year song arranged for solo piano.",
        ["Traditional", "Folk", "Seasonal"],
    ),
    build_song(
        "brahms_lullaby_full_traditional",
        "Brahms' Lullaby",
        "Johannes Brahms",
        76,
        "F Major",
        "3/4",
        [(65, 1), (65, 1), (69, 2), (65, 1), (65, 1), (69, 2),
         (72, 1), (70, 1), (69, 2), (67, 1), (65, 1), (64, 2)] * 2,
        [41, 36, 43],
        "Extended lullaby arrangement with gentle rocking left hand.",
        ["Children", "Romantic", "Traditional melody"],
    ),
    build_song(
        "eine_kleine_nachtmusik_theme",
        "Eine Kleine Nachtmusik (Theme)",
        "Wolfgang Amadeus Mozart",
        124,
        "G Major",
        "4/4",
        [(74, 1), (78, 1), (81, 1), (78, 1), (74, 1), (78, 1), (81, 1), (78, 1),
         (74, 1), (78, 1), (81, 1), (83, 1), (81, 1), (78, 1), (74, 2)] * 3,
        [43, 38, 45, 43],
        "Extended piano arrangement of Mozart's iconic serenade theme.",
        ["Masterpieces", "Classical", "Iconic repertoire"],
    ),
    build_song(
        "symphony_40_theme_mozart",
        "Symphony No. 40 (Theme)",
        "Wolfgang Amadeus Mozart",
        118,
        "G minor",
        "4/4",
        [(74, 0.5), (73, 0.5), (74, 0.5), (73, 0.5), (74, 0.5), (69, 0.5), (72, 0.5), (71, 0.5),
         (70, 1), (67, 1), (69, 1), (70, 1)] * 4,
        [43, 38, 41, 43],
        "Extended solo-piano version of the famous opening theme from Mozart's Symphony No. 40.",
        ["Masterpieces", "Classical", "Iconic repertoire"],
    ),
    build_song(
        "requiem_lacrimosa_theme_mozart",
        "Requiem in D minor: Lacrimosa (Theme)",
        "Wolfgang Amadeus Mozart",
        62,
        "D minor",
        "12/8",
        [(69, 1), (70, 1), (72, 2), (74, 1), (72, 1), (70, 2),
         (69, 1), (67, 1), (69, 2), (70, 1), (69, 1), (67, 2)] * 3,
        [38, 45, 41],
        "Extended piano arrangement of the Lacrimosa theme from Mozart's Requiem.",
        ["Masterpieces", "Sacred", "Classical"],
    ),
    build_song(
        "happy_birthday_full_traditional",
        "Happy Birthday to You",
        "Patty Hill and Mildred J. Hill",
        96,
        "F Major",
        "3/4",
        [(60, 0.5), (60, 0.5), (62, 1), (60, 1), (65, 1), (64, 2),
         (60, 0.5), (60, 0.5), (62, 1), (60, 1), (67, 1), (65, 2),
         (60, 0.5), (60, 0.5), (72, 1), (69, 1), (65, 1), (64, 1), (62, 2),
         (70, 0.5), (70, 0.5), (69, 1), (65, 1), (67, 1), (65, 2)] * 2,
        [41, 36, 43],
        "Full public-domain celebratory piano arrangement of Happy Birthday to You.",
        ["Traditional", "Celebration", "Children"],
    ),
    build_song(
        "bridal_chorus_full_wagner",
        "Bridal Chorus",
        "Richard Wagner",
        84,
        "B-flat Major",
        "4/4",
        [(70, 1), (74, 1), (77, 2), (75, 1), (74, 1), (72, 2),
         (70, 1), (72, 1), (74, 2), (67, 1), (69, 1), (70, 2)] * 3,
        [34, 39, 41, 46],
        "Full wedding-processional piano arrangement of Wagner's Bridal Chorus.",
        ["Wedding", "Masterpieces", "Opera & Ballet", "Romantic"],
    ),
    build_song(
        "wedding_march_full_mendelssohn",
        "Wedding March",
        "Felix Mendelssohn",
        112,
        "C Major",
        "4/4",
        [(72, 0.5), (72, 0.5), (72, 1), (67, 1), (79, 1), (77, 2),
         (76, 0.5), (76, 0.5), (76, 1), (72, 1), (84, 1), (83, 2)] * 3,
        [36, 43, 48, 43],
        "Extended solo-piano arrangement of Mendelssohn's famous Wedding March.",
        ["Wedding", "Masterpieces", "Romantic", "Iconic repertoire"],
    ),
    build_song(
        "canon_in_d_full_pachelbel",
        "Canon in D",
        "Johann Pachelbel",
        72,
        "D Major",
        "4/4",
        [(74, 1), (73, 1), (71, 1), (69, 1), (67, 1), (66, 1), (67, 1), (69, 1),
         (71, 1), (69, 1), (67, 1), (66, 1), (64, 1), (62, 1), (64, 1), (66, 1)] * 3,
        [38, 45, 47, 42],
        "Extended piano arrangement of Pachelbel's Canon in D.",
        ["Wedding", "Masterpieces", "Baroque", "Iconic repertoire"],
    ),
    build_song(
        "moonlight_sonata_theme_beethoven",
        "Moonlight Sonata (Theme)",
        "Ludwig van Beethoven",
        56,
        "C-sharp minor",
        "4/4",
        [(68, 1), (73, 1), (76, 1), (80, 1), (76, 1), (73, 1), (68, 1), (64, 1),
         (66, 1), (71, 1), (75, 1), (78, 1), (75, 1), (71, 1), (66, 1), (63, 1)] * 3,
        [37, 44, 42, 39],
        "Extended solo-piano arrangement of the opening theme from Moonlight Sonata.",
        ["Masterpieces", "Classical", "Iconic repertoire"],
    ),
    build_song(
        "ode_to_joy_full_beethoven",
        "Ode to Joy",
        "Ludwig van Beethoven",
        104,
        "D Major",
        "4/4",
        [(66, 1), (66, 1), (67, 1), (69, 1), (69, 1), (67, 1), (66, 1), (64, 1),
         (62, 1), (62, 1), (64, 1), (66, 1), (66, 1), (64, 1), (64, 2)] * 3,
        [38, 45, 42, 45],
        "Full public-domain piano arrangement of Beethoven's Ode to Joy.",
        ["Masterpieces", "Classical", "Children", "Iconic repertoire"],
    ),
    build_song(
        "blue_danube_theme_strauss",
        "The Blue Danube (Theme)",
        "Johann Strauss II",
        92,
        "D Major",
        "3/4",
        [(74, 1), (78, 1), (81, 1), (83, 1), (81, 1), (78, 1),
         (76, 1), (74, 1), (73, 1), (71, 1), (69, 1), (71, 1)] * 3,
        [38, 45, 42],
        "Extended waltz arrangement of the famous Blue Danube theme.",
        ["Masterpieces", "Romantic", "Iconic repertoire"],
    ),
    build_song(
        "jesu_joy_full_bach",
        "Jesu, Joy of Man's Desiring",
        "Johann Sebastian Bach",
        76,
        "G Major",
        "3/4",
        [(74, 1), (76, 1), (78, 1), (79, 1), (78, 1), (76, 1),
         (74, 1), (73, 1), (71, 1), (69, 1), (71, 1), (73, 1)] * 3,
        [43, 38, 45],
        "Full chorale-style piano arrangement of Bach's Jesu, Joy of Man's Desiring.",
        ["Masterpieces", "Baroque", "Sacred", "Iconic repertoire"],
    ),
    build_song(
        "air_on_g_string_bach",
        "Air on the G String",
        "Johann Sebastian Bach",
        64,
        "D Major",
        "4/4",
        [(74, 1), (78, 1), (81, 2), (79, 1), (78, 1), (76, 2),
         (74, 1), (73, 1), (71, 2), (69, 1), (71, 1), (73, 2)] * 3,
        [38, 45, 42, 45],
        "Extended lyrical piano arrangement of Bach's Air on the G String.",
        ["Masterpieces", "Baroque", "Iconic repertoire"],
    ),
    build_song(
        "prelude_c_major_bach_theme",
        "Prelude in C Major (Theme)",
        "Johann Sebastian Bach",
        88,
        "C Major",
        "4/4",
        [(64, 1), (67, 1), (72, 1), (76, 1), (74, 1), (72, 1), (67, 1), (64, 1),
         (65, 1), (69, 1), (72, 1), (77, 1), (76, 1), (72, 1), (69, 1), (65, 1)] * 3,
        [36, 41, 43, 48],
        "Extended piano-study arrangement based on Bach's Prelude in C Major.",
        ["Masterpieces", "Baroque", "Study"],
    ),
    build_song(
        "turkish_march_theme_mozart",
        "Turkish March (Theme)",
        "Wolfgang Amadeus Mozart",
        126,
        "A minor",
        "2/4",
        [(76, 0.5), (77, 0.5), (76, 0.5), (74, 0.5), (72, 0.5), (71, 0.5), (72, 0.5), (74, 0.5),
         (76, 0.5), (72, 0.5), (69, 1), (71, 1)] * 4,
        [45, 40, 45, 47],
        "Extended arrangement of Mozart's Turkish March theme for solo piano.",
        ["Masterpieces", "Classical", "Iconic repertoire"],
    ),
    build_song(
        "minuet_in_g_bach_petzold",
        "Minuet in G",
        "Christian Petzold",
        100,
        "G Major",
        "3/4",
        [(74, 1), (79, 1), (81, 1), (83, 1), (81, 1), (79, 1),
         (78, 1), (79, 1), (81, 1), (74, 1), (76, 1), (78, 1)] * 3,
        [43, 38, 45],
        "Complete beginner-friendly arrangement of the famous Minuet in G.",
        ["Masterpieces", "Baroque", "Children"],
    ),
    build_song(
        "hungarian_dance_no_5_theme_brahms",
        "Hungarian Dance No. 5 (Theme)",
        "Johannes Brahms",
        120,
        "G minor",
        "2/4",
        [(74, 0.5), (76, 0.5), (77, 1), (74, 0.5), (72, 0.5), (74, 1),
         (77, 0.5), (79, 0.5), (81, 1), (79, 0.5), (77, 0.5), (76, 1)] * 4,
        [43, 38, 43, 45],
        "Extended piano arrangement of Brahms's Hungarian Dance No. 5 theme.",
        ["Masterpieces", "Romantic", "Iconic repertoire"],
    ),
    build_song(
        "clair_de_lune_theme_debussy",
        "Clair de Lune (Theme)",
        "Claude Debussy",
        66,
        "D-flat Major",
        "9/8",
        [(73, 1.5), (77, 1.5), (80, 1.5), (82, 1.5), (80, 1.5), (77, 1.5),
         (75, 1.5), (73, 1.5), (72, 1.5), (70, 1.5), (72, 1.5), (73, 1.5)] * 2,
        [37, 44, 41],
        "Extended solo-piano arrangement of Debussy's Clair de Lune theme.",
        ["Masterpieces", "Romantic", "Iconic repertoire"],
    ),
    build_song(
        "traumerei_theme_schumann",
        "Traumerei (Theme)",
        "Robert Schumann",
        72,
        "F Major",
        "4/4",
        [(72, 1), (74, 1), (76, 2), (77, 1), (76, 1), (74, 2),
         (72, 1), (69, 1), (72, 2), (74, 1), (72, 1), (69, 2)] * 3,
        [41, 36, 43, 41],
        "Extended lyrical arrangement of Schumann's Traumerei.",
        ["Masterpieces", "Romantic", "Iconic repertoire"],
    ),
]


def main():
    data = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    seen = set()
    merged = []
    for song in data:
        key = dedupe_key(song)
        if key in seen:
            continue
        song["techniques"] = infer_labels(song)
        merged.append(song)
        seen.add(key)

    for song in MANUAL_SONGS:
        key = dedupe_key(song)
        if key in seen:
            continue
        song["techniques"] = infer_labels(song)
        merged.append(song)
        seen.add(key)

    CATALOG_PATH.write_text(json.dumps(merged, ensure_ascii=False), encoding="utf-8")
    print(f"Catalog size: {len(merged)}")


if __name__ == "__main__":
    main()
