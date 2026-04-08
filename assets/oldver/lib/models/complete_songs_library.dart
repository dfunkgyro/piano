// ============================================
// complete_songs_library.dart - Enhanced Song Data Models
// ============================================

class CompleteSong {
  final String id;
  final String title;
  final String composer;
  final String difficulty;
  final int bpm;
  final String key;
  final List<SongNote> notes;
  final String description;
  final List<String> techniques;
  final int? catalogNumber; // For classical works (K., Op., BWV, etc.)
  final String? movement; // For multi-movement works

  CompleteSong({
    required this.id,
    required this.title,
    required this.composer,
    required this.difficulty,
    required this.bpm,
    required this.key,
    required this.notes,
    required this.description,
    required this.techniques,
    this.catalogNumber,
    this.movement,
  });

  factory CompleteSong.fromJson(Map<String, dynamic> json) {
    return CompleteSong(
      id: json['id'] as String,
      title: json['title'] as String,
      composer: json['composer'] as String,
      difficulty: json['difficulty'] as String,
      bpm: json['bpm'] as int,
      key: json['key'] as String,
      notes: (json['notes'] as List)
          .map((note) => SongNote.fromJson(note))
          .toList(),
      description: json['description'] as String,
      techniques: List<String>.from(json['techniques'] as List),
      catalogNumber: json['catalogNumber'] as int?,
      movement: json['movement'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'composer': composer,
      'difficulty': difficulty,
      'bpm': bpm,
      'key': key,
      'notes': notes.map((note) => note.toJson()).toList(),
      'description': description,
      'techniques': techniques,
      'catalogNumber': catalogNumber,
      'movement': movement,
    };
  }
}

class SongNote {
  final int note; // MIDI note number
  final double time; // Time in seconds
  final double duration; // Duration in seconds
  final String hand; // 'L' for left, 'R' for right, 'B' for both
  final int velocity; // 0-127
  final int? finger; // Suggested fingering (1-5)

  SongNote({
    required this.note,
    required this.time,
    required this.duration,
    required this.hand,
    this.velocity = 100,
    this.finger,
  });

  factory SongNote.fromJson(Map<String, dynamic> json) {
    return SongNote(
      note: json['note'] as int,
      time: (json['time'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      hand: json['hand'] as String,
      velocity: json['velocity'] as int? ?? 100,
      finger: json['finger'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'note': note,
      'time': time,
      'duration': duration,
      'hand': hand,
      'velocity': velocity,
      'finger': finger,
    };
  }
}

// Enhanced songs library
class SongsLibrary {
  static List<CompleteSong> getSongs() {
    return [
      // Beginner songs
      _getMaryHadALittleLamb(),
      _getTwinkleTwinkleLittleStar(),
      _getOdeToJoy(),
      _getFurElise(), // Beginner section only

      // Intermediate songs
      _getBachMinuetInGMajor(),
      _getChopinPreludeInEMinor(),
      _getSchumannTraumerei(),

      // Intermediate/Advanced classical pieces
      _getMozartFantasiaInDMinor(),
      _getBeethovenMoonlightSonata(),

      // Advanced pieces
      _getDebussyClairDeLune(),
      _getBachPreludeInCMajor(),
    ];
  }

  // ============================================
  // BEGINNER SONGS
  // ============================================

  static CompleteSong _getMaryHadALittleLamb() {
    return CompleteSong(
      id: 'mary_lamb',
      title: 'Mary Had a Little Lamb',
      composer: 'Traditional',
      difficulty: 'Beginner',
      bpm: 100,
      key: 'C Major',
      description: 'Classic nursery rhyme, perfect for absolute beginners.',
      techniques: ['Single note melody', 'Finger independence'],
      notes: [
        SongNote(note: 64, time: 0.0, duration: 0.5, hand: 'R', finger: 3),
        SongNote(note: 62, time: 0.5, duration: 0.5, hand: 'R', finger: 2),
        SongNote(note: 60, time: 1.0, duration: 0.5, hand: 'R', finger: 1),
        SongNote(note: 62, time: 1.5, duration: 0.5, hand: 'R', finger: 2),
        SongNote(note: 64, time: 2.0, duration: 0.5, hand: 'R', finger: 3),
        SongNote(note: 64, time: 2.5, duration: 0.5, hand: 'R', finger: 3),
        SongNote(note: 64, time: 3.0, duration: 1.0, hand: 'R', finger: 3),
        SongNote(note: 62, time: 4.0, duration: 0.5, hand: 'R', finger: 2),
        SongNote(note: 62, time: 4.5, duration: 0.5, hand: 'R', finger: 2),
        SongNote(note: 62, time: 5.0, duration: 1.0, hand: 'R', finger: 2),
        SongNote(note: 64, time: 6.0, duration: 0.5, hand: 'R', finger: 3),
        SongNote(note: 67, time: 6.5, duration: 0.5, hand: 'R', finger: 5),
        SongNote(note: 67, time: 7.0, duration: 1.0, hand: 'R', finger: 5),
      ],
    );
  }

  static CompleteSong _getTwinkleTwinkleLittleStar() {
    return CompleteSong(
      id: 'twinkle',
      title: 'Twinkle Twinkle Little Star',
      composer: 'Traditional',
      difficulty: 'Beginner',
      bpm: 100,
      key: 'C Major',
      description: 'Popular children\'s song based on a French melody.',
      techniques: ['Single note melody', 'Steady rhythm'],
      notes: [
        SongNote(note: 60, time: 0.0, duration: 0.5, hand: 'R', finger: 1),
        SongNote(note: 60, time: 0.5, duration: 0.5, hand: 'R', finger: 1),
        SongNote(note: 67, time: 1.0, duration: 0.5, hand: 'R', finger: 5),
        SongNote(note: 67, time: 1.5, duration: 0.5, hand: 'R', finger: 5),
        SongNote(note: 69, time: 2.0, duration: 0.5, hand: 'R', finger: 5),
        SongNote(note: 69, time: 2.5, duration: 0.5, hand: 'R', finger: 5),
        SongNote(note: 67, time: 3.0, duration: 1.0, hand: 'R', finger: 5),
        SongNote(note: 65, time: 4.0, duration: 0.5, hand: 'R', finger: 4),
        SongNote(note: 65, time: 4.5, duration: 0.5, hand: 'R', finger: 4),
        SongNote(note: 64, time: 5.0, duration: 0.5, hand: 'R', finger: 3),
        SongNote(note: 64, time: 5.5, duration: 0.5, hand: 'R', finger: 3),
        SongNote(note: 62, time: 6.0, duration: 0.5, hand: 'R', finger: 2),
        SongNote(note: 62, time: 6.5, duration: 0.5, hand: 'R', finger: 2),
        SongNote(note: 60, time: 7.0, duration: 1.0, hand: 'R', finger: 1),
      ],
    );
  }

  static CompleteSong _getOdeToJoy() {
    return CompleteSong(
      id: 'ode_to_joy',
      title: 'Ode to Joy',
      composer: 'Ludwig van Beethoven',
      difficulty: 'Beginner',
      bpm: 120,
      key: 'C Major',
      catalogNumber: 125,
      description:
          'Famous melody from Beethoven\'s 9th Symphony. A perfect piece for beginners.',
      techniques: [
        'Single note melody',
        'Pattern recognition',
        'Phrase shaping'
      ],
      notes: [
        SongNote(note: 64, time: 0.0, duration: 0.5, hand: 'R', finger: 3),
        SongNote(note: 64, time: 0.5, duration: 0.5, hand: 'R', finger: 3),
        SongNote(note: 65, time: 1.0, duration: 0.5, hand: 'R', finger: 4),
        SongNote(note: 67, time: 1.5, duration: 0.5, hand: 'R', finger: 5),
        SongNote(note: 67, time: 2.0, duration: 0.5, hand: 'R', finger: 5),
        SongNote(note: 65, time: 2.5, duration: 0.5, hand: 'R', finger: 4),
        SongNote(note: 64, time: 3.0, duration: 0.5, hand: 'R', finger: 3),
        SongNote(note: 62, time: 3.5, duration: 0.5, hand: 'R', finger: 2),
        SongNote(note: 60, time: 4.0, duration: 0.5, hand: 'R', finger: 1),
        SongNote(note: 60, time: 4.5, duration: 0.5, hand: 'R', finger: 1),
        SongNote(note: 62, time: 5.0, duration: 0.5, hand: 'R', finger: 2),
        SongNote(note: 64, time: 5.5, duration: 0.5, hand: 'R', finger: 3),
        SongNote(note: 64, time: 6.0, duration: 0.75, hand: 'R', finger: 3),
        SongNote(note: 62, time: 6.75, duration: 0.25, hand: 'R', finger: 2),
        SongNote(note: 62, time: 7.0, duration: 1.0, hand: 'R', finger: 2),
      ],
    );
  }

  // ============================================
  // INTERMEDIATE CLASSICAL PIECES
  // ============================================

  static CompleteSong _getBachMinuetInGMajor() {
    return CompleteSong(
      id: 'bach_minuet_g_major',
      title: 'Minuet in G Major',
      composer: 'Johann Sebastian Bach (attr. Christian Petzold)',
      difficulty: 'Intermediate',
      bpm: 120,
      key: 'G Major',
      catalogNumber: 114,
      description:
          'Elegant baroque minuet from the Notebook for Anna Magdalena Bach. Features balanced phrases and graceful melodic lines.',
      techniques: [
        'Two-part counterpoint',
        'Baroque ornamentation',
        'Hand independence',
        'Legato touch',
        'Phrasing',
      ],
      notes: _getBachMinuetInGMajorNotes(),
    );
  }

  static List<SongNote> _getBachMinuetInGMajorNotes() {
    return [
      // Measure 1
      SongNote(
          note: 74,
          time: 0.0,
          duration: 0.33,
          hand: 'R',
          velocity: 75,
          finger: 1), // D5
      SongNote(
          note: 67,
          time: 0.33,
          duration: 0.33,
          hand: 'R',
          velocity: 70,
          finger: 2), // G4
      SongNote(
          note: 69,
          time: 0.66,
          duration: 0.33,
          hand: 'R',
          velocity: 70,
          finger: 3), // A4
      SongNote(
          note: 50,
          time: 0.0,
          duration: 1.0,
          hand: 'L',
          velocity: 60,
          finger: 5), // D3
      SongNote(
          note: 55,
          time: 0.0,
          duration: 1.0,
          hand: 'L',
          velocity: 60,
          finger: 2), // G3

      // Measure 2
      SongNote(
          note: 71,
          time: 1.0,
          duration: 0.33,
          hand: 'R',
          velocity: 75,
          finger: 4), // B4
      SongNote(
          note: 72,
          time: 1.33,
          duration: 0.33,
          hand: 'R',
          velocity: 70,
          finger: 5), // C5
      SongNote(
          note: 74,
          time: 1.66,
          duration: 0.33,
          hand: 'R',
          velocity: 70,
          finger: 1), // D5
      SongNote(
          note: 50,
          time: 1.0,
          duration: 1.0,
          hand: 'L',
          velocity: 60,
          finger: 5), // D3
      SongNote(
          note: 55,
          time: 1.0,
          duration: 1.0,
          hand: 'L',
          velocity: 60,
          finger: 2), // G3

      // Measure 3-4
      SongNote(
          note: 67,
          time: 2.0,
          duration: 0.5,
          hand: 'R',
          velocity: 80,
          finger: 2), // G4
      SongNote(
          note: 55,
          time: 2.0,
          duration: 0.5,
          hand: 'L',
          velocity: 60,
          finger: 5), // G3
      SongNote(
          note: 59,
          time: 2.0,
          duration: 0.5,
          hand: 'L',
          velocity: 60,
          finger: 2), // B3
      SongNote(
          note: 67,
          time: 2.5,
          duration: 0.5,
          hand: 'R',
          velocity: 75,
          finger: 2), // G4

      SongNote(
          note: 67,
          time: 3.0,
          duration: 1.0,
          hand: 'R',
          velocity: 85,
          finger: 2), // G4
      SongNote(
          note: 55,
          time: 3.0,
          duration: 1.0,
          hand: 'L',
          velocity: 65,
          finger: 5), // G3
      SongNote(
          note: 59,
          time: 3.0,
          duration: 1.0,
          hand: 'L',
          velocity: 65,
          finger: 2), // B3
    ];
  }

  static CompleteSong _getChopinPreludeInEMinor() {
    return CompleteSong(
      id: 'chopin_prelude_e_minor',
      title: 'Prelude in E minor, Op. 28 No. 4',
      composer: 'Frédéric Chopin',
      difficulty: 'Intermediate',
      bpm: 54,
      key: 'E minor',
      catalogNumber: 28,
      description:
          'One of Chopin\'s most famous preludes, featuring a simple yet profound melody over sustained chords. Known for its melancholic and expressive character.',
      techniques: [
        'Sustained chords',
        'Melody voicing',
        'Legato pedaling',
        'Dynamic control',
        'Expressive rubato',
      ],
      notes: _getChopinPreludeInEMinorNotes(),
    );
  }

  static List<SongNote> _getChopinPreludeInEMinorNotes() {
    return [
      // Measure 1 - Opening sustained chord with melody
      SongNote(
          note: 52,
          time: 0.0,
          duration: 4.0,
          hand: 'L',
          velocity: 60,
          finger: 5), // E2
      SongNote(
          note: 59,
          time: 0.0,
          duration: 4.0,
          hand: 'L',
          velocity: 60,
          finger: 2), // B2
      SongNote(
          note: 64,
          time: 0.0,
          duration: 4.0,
          hand: 'L',
          velocity: 60,
          finger: 1), // E3

      SongNote(
          note: 71,
          time: 0.0,
          duration: 1.0,
          hand: 'R',
          velocity: 70,
          finger: 5), // B4
      SongNote(
          note: 72,
          time: 1.0,
          duration: 1.0,
          hand: 'R',
          velocity: 72,
          finger: 5), // C5
      SongNote(
          note: 71,
          time: 2.0,
          duration: 1.0,
          hand: 'R',
          velocity: 70,
          finger: 5), // B4
      SongNote(
          note: 69,
          time: 3.0,
          duration: 1.0,
          hand: 'R',
          velocity: 68,
          finger: 4), // A4

      // Measure 2
      SongNote(
          note: 52,
          time: 4.0,
          duration: 4.0,
          hand: 'L',
          velocity: 60,
          finger: 5), // E2
      SongNote(
          note: 59,
          time: 4.0,
          duration: 4.0,
          hand: 'L',
          velocity: 60,
          finger: 2), // B2
      SongNote(
          note: 64,
          time: 4.0,
          duration: 4.0,
          hand: 'L',
          velocity: 60,
          finger: 1), // E3

      SongNote(
          note: 67,
          time: 4.0,
          duration: 1.0,
          hand: 'R',
          velocity: 75,
          finger: 3), // G4
      SongNote(
          note: 69,
          time: 5.0,
          duration: 1.0,
          hand: 'R',
          velocity: 73,
          finger: 4), // A4
      SongNote(
          note: 67,
          time: 6.0,
          duration: 1.0,
          hand: 'R',
          velocity: 70,
          finger: 3), // G4
      SongNote(
          note: 66,
          time: 7.0,
          duration: 1.0,
          hand: 'R',
          velocity: 68,
          finger: 2), // F#4

      // Measure 3 - Harmonic shift
      SongNote(
          note: 50,
          time: 8.0,
          duration: 4.0,
          hand: 'L',
          velocity: 60,
          finger: 5), // D2
      SongNote(
          note: 57,
          time: 8.0,
          duration: 4.0,
          hand: 'L',
          velocity: 60,
          finger: 2), // A2
      SongNote(
          note: 62,
          time: 8.0,
          duration: 4.0,
          hand: 'L',
          velocity: 60,
          finger: 1), // D3

      SongNote(
          note: 64,
          time: 8.0,
          duration: 2.0,
          hand: 'R',
          velocity: 80,
          finger: 1), // E4
      SongNote(
          note: 66,
          time: 10.0,
          duration: 1.0,
          hand: 'R',
          velocity: 75,
          finger: 2), // F#4
      SongNote(
          note: 64,
          time: 11.0,
          duration: 1.0,
          hand: 'R',
          velocity: 70,
          finger: 1), // E4
    ];
  }

  static CompleteSong _getSchumannTraumerei() {
    return CompleteSong(
      id: 'schumann_traumerei',
      title: 'Träumerei (Dreaming)',
      composer: 'Robert Schumann',
      difficulty: 'Intermediate',
      bpm: 84,
      key: 'F Major',
      catalogNumber: 15,
      movement: 'Kinderszenen, No. 7',
      description:
          'A tender and lyrical piece from Schumann\'s Scenes from Childhood. Known for its singing melody and romantic character.',
      techniques: [
        'Cantabile melody',
        'Inner voices',
        'Chord voicing',
        'Pedaling',
        'Dynamic shading',
        'Legato playing',
      ],
      notes: _getSchumannTraumereiNotes(),
    );
  }

  static List<SongNote> _getSchumannTraumereiNotes() {
    return [
      // Measure 1 - Opening phrase
      SongNote(
          note: 65,
          time: 0.0,
          duration: 1.0,
          hand: 'R',
          velocity: 75,
          finger: 1), // F4
      SongNote(
          note: 53,
          time: 0.0,
          duration: 0.5,
          hand: 'L',
          velocity: 55,
          finger: 5), // F2
      SongNote(
          note: 60,
          time: 0.0,
          duration: 0.5,
          hand: 'L',
          velocity: 55,
          finger: 2), // C3
      SongNote(
          note: 65,
          time: 0.0,
          duration: 0.5,
          hand: 'L',
          velocity: 55,
          finger: 1), // F3

      SongNote(
          note: 69,
          time: 0.5,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 2), // A4
      SongNote(
          note: 72,
          time: 0.75,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 4), // C5

      SongNote(
          note: 77,
          time: 1.0,
          duration: 1.0,
          hand: 'R',
          velocity: 80,
          finger: 5), // F5
      SongNote(
          note: 53,
          time: 1.0,
          duration: 0.5,
          hand: 'L',
          velocity: 55,
          finger: 5), // F2
      SongNote(
          note: 60,
          time: 1.0,
          duration: 0.5,
          hand: 'L',
          velocity: 55,
          finger: 2), // C3

      // Measure 2
      SongNote(
          note: 76,
          time: 2.0,
          duration: 1.0,
          hand: 'R',
          velocity: 75,
          finger: 4), // E5
      SongNote(
          note: 48,
          time: 2.0,
          duration: 0.5,
          hand: 'L',
          velocity: 55,
          finger: 5), // C2
      SongNote(
          note: 60,
          time: 2.0,
          duration: 0.5,
          hand: 'L',
          velocity: 55,
          finger: 2), // C3
      SongNote(
          note: 64,
          time: 2.0,
          duration: 0.5,
          hand: 'L',
          velocity: 55,
          finger: 1), // E3

      SongNote(
          note: 74,
          time: 3.0,
          duration: 0.5,
          hand: 'R',
          velocity: 70,
          finger: 3), // D5
      SongNote(
          note: 72,
          time: 3.5,
          duration: 0.5,
          hand: 'R',
          velocity: 65,
          finger: 2), // C5

      // Measure 3
      SongNote(
          note: 70,
          time: 4.0,
          duration: 1.0,
          hand: 'R',
          velocity: 80,
          finger: 1), // B♭4
      SongNote(
          note: 50,
          time: 4.0,
          duration: 0.5,
          hand: 'L',
          velocity: 55,
          finger: 5), // D2
      SongNote(
          note: 58,
          time: 4.0,
          duration: 0.5,
          hand: 'L',
          velocity: 55,
          finger: 2), // B♭2
      SongNote(
          note: 62,
          time: 4.0,
          duration: 0.5,
          hand: 'L',
          velocity: 55,
          finger: 1), // D3
    ];
  }

  static CompleteSong _getFurElise() {
    return CompleteSong(
      id: 'beethoven_fur_elise',
      title: 'Für Elise',
      composer: 'Ludwig van Beethoven',
      difficulty: 'Beginner',
      bpm: 72,
      key: 'A minor',
      catalogNumber: 59,
      description:
          'One of the most recognizable piano pieces ever written. This beginner version includes the famous opening theme. Perfect for early intermediate students.',
      techniques: [
        'Alternating hands',
        'Finger independence',
        'Grace notes',
        'Simple accompaniment',
        'Melodic phrasing',
      ],
      notes: _getFurEliseNotes(),
    );
  }

  static List<SongNote> _getFurEliseNotes() {
    return [
      // Famous opening - Measure 1
      SongNote(
          note: 76,
          time: 0.0,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 3), // E5
      SongNote(
          note: 75,
          time: 0.25,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 2), // D#5
      SongNote(
          note: 76,
          time: 0.5,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 3), // E5
      SongNote(
          note: 75,
          time: 0.75,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 2), // D#5
      SongNote(
          note: 76,
          time: 1.0,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 3), // E5
      SongNote(
          note: 71,
          time: 1.25,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 1), // B4
      SongNote(
          note: 74,
          time: 1.5,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 4), // D5
      SongNote(
          note: 72,
          time: 1.75,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 2), // C5

      // Measure 2
      SongNote(
          note: 69,
          time: 2.0,
          duration: 0.5,
          hand: 'R',
          velocity: 75,
          finger: 1), // A4
      SongNote(
          note: 45,
          time: 2.0,
          duration: 0.5,
          hand: 'L',
          velocity: 55,
          finger: 5), // A2
      SongNote(
          note: 57,
          time: 2.0,
          duration: 0.5,
          hand: 'L',
          velocity: 55,
          finger: 2), // A3
      SongNote(
          note: 64,
          time: 2.0,
          duration: 0.5,
          hand: 'L',
          velocity: 55,
          finger: 1), // E3

      SongNote(
          note: 60,
          time: 2.5,
          duration: 0.25,
          hand: 'R',
          velocity: 65,
          finger: 5), // C4
      SongNote(
          note: 64,
          time: 2.75,
          duration: 0.25,
          hand: 'R',
          velocity: 65,
          finger: 3), // E4
      SongNote(
          note: 69,
          time: 3.0,
          duration: 0.5,
          hand: 'R',
          velocity: 70,
          finger: 1), // A4

      // Measure 3 - Repeat pattern
      SongNote(
          note: 71,
          time: 3.5,
          duration: 0.5,
          hand: 'R',
          velocity: 70,
          finger: 2), // B4
      SongNote(
          note: 40,
          time: 3.5,
          duration: 0.5,
          hand: 'L',
          velocity: 55,
          finger: 5), // E2
      SongNote(
          note: 52,
          time: 3.5,
          duration: 0.5,
          hand: 'L',
          velocity: 55,
          finger: 2), // E3
      SongNote(
          note: 68,
          time: 3.5,
          duration: 0.5,
          hand: 'L',
          velocity: 55,
          finger: 1), // G#3

      SongNote(
          note: 64,
          time: 4.0,
          duration: 0.25,
          hand: 'R',
          velocity: 65,
          finger: 5), // E4
      SongNote(
          note: 68,
          time: 4.25,
          duration: 0.25,
          hand: 'R',
          velocity: 65,
          finger: 3), // G#4
      SongNote(
          note: 71,
          time: 4.5,
          duration: 0.5,
          hand: 'R',
          velocity: 70,
          finger: 1), // B4
    ];
  }

  // ============================================
  // ADVANCED CLASSICAL PIECES
  // ============================================

  static CompleteSong _getMozartFantasiaInDMinor() {
    return CompleteSong(
      id: 'mozart_fantasia_d_minor',
      title: 'Fantasia in D minor',
      composer: 'Wolfgang Amadeus Mozart',
      difficulty: 'Advanced',
      bpm: 80,
      key: 'D minor',
      catalogNumber: 397,
      description:
          'Mozart\'s expressive Fantasia K. 397, known for its dramatic changes and improvisational character. Features the famous Adagio opening and virtuosic passages.',
      techniques: [
        'Arpeggios',
        'Scales',
        'Hand coordination',
        'Dynamic contrast',
        'Pedaling',
        'Tempo rubato',
        'Chromatic passages'
      ],
      notes: _getMozartFantasiaInDMinorNotes(),
    );
  }

  static List<SongNote> _getMozartFantasiaInDMinorNotes() {
    return [
      // Opening arpeggio section
      SongNote(
          note: 62,
          time: 0.0,
          duration: 0.5,
          hand: 'L',
          velocity: 70,
          finger: 5), // D
      SongNote(
          note: 65,
          time: 0.0,
          duration: 0.5,
          hand: 'L',
          velocity: 70,
          finger: 3), // F
      SongNote(
          note: 69,
          time: 0.0,
          duration: 0.5,
          hand: 'R',
          velocity: 75,
          finger: 2), // A
      SongNote(
          note: 74,
          time: 0.5,
          duration: 0.5,
          hand: 'R',
          velocity: 80,
          finger: 1), // D
      SongNote(
          note: 62,
          time: 1.0,
          duration: 0.5,
          hand: 'L',
          velocity: 70,
          finger: 5), // D
      SongNote(
          note: 65,
          time: 1.0,
          duration: 0.5,
          hand: 'L',
          velocity: 70,
          finger: 3), // F
      SongNote(
          note: 69,
          time: 1.0,
          duration: 0.5,
          hand: 'R',
          velocity: 75,
          finger: 2), // A
      SongNote(
          note: 74,
          time: 1.5,
          duration: 0.5,
          hand: 'R',
          velocity: 80,
          finger: 1), // D

      // Main theme
      SongNote(
          note: 74,
          time: 2.0,
          duration: 0.75,
          hand: 'R',
          velocity: 85,
          finger: 1), // D
      SongNote(
          note: 72,
          time: 2.75,
          duration: 0.25,
          hand: 'R',
          velocity: 80,
          finger: 2), // C
      SongNote(
          note: 74,
          time: 3.0,
          duration: 0.5,
          hand: 'R',
          velocity: 85,
          finger: 1), // D
      SongNote(
          note: 76,
          time: 3.5,
          duration: 0.5,
          hand: 'R',
          velocity: 85,
          finger: 3), // E
      SongNote(
          note: 77,
          time: 4.0,
          duration: 1.0,
          hand: 'R',
          velocity: 90,
          finger: 4), // F
      SongNote(
          note: 62,
          time: 4.0,
          duration: 1.0,
          hand: 'L',
          velocity: 65,
          finger: 5), // D
      SongNote(
          note: 65,
          time: 4.0,
          duration: 1.0,
          hand: 'L',
          velocity: 65,
          finger: 3), // F

      SongNote(
          note: 77,
          time: 5.0,
          duration: 0.5,
          hand: 'R',
          velocity: 85,
          finger: 4), // F
      SongNote(
          note: 76,
          time: 5.5,
          duration: 0.5,
          hand: 'R',
          velocity: 80,
          finger: 3), // E
      SongNote(
          note: 74,
          time: 6.0,
          duration: 0.5,
          hand: 'R',
          velocity: 80,
          finger: 1), // D
      SongNote(
          note: 72,
          time: 6.5,
          duration: 0.5,
          hand: 'R',
          velocity: 75,
          finger: 2), // C
      SongNote(
          note: 70,
          time: 7.0,
          duration: 1.0,
          hand: 'R',
          velocity: 85,
          finger: 1), // B♭
      SongNote(
          note: 62,
          time: 7.0,
          duration: 1.0,
          hand: 'L',
          velocity: 65,
          finger: 5), // D
      SongNote(
          note: 65,
          time: 7.0,
          duration: 1.0,
          hand: 'L',
          velocity: 65,
          finger: 3), // F

      // Second phrase
      SongNote(
          note: 70,
          time: 8.0,
          duration: 0.75,
          hand: 'R',
          velocity: 85,
          finger: 1), // B♭
      SongNote(
          note: 69,
          time: 8.75,
          duration: 0.25,
          hand: 'R',
          velocity: 80,
          finger: 2), // A
      SongNote(
          note: 70,
          time: 9.0,
          duration: 0.5,
          hand: 'R',
          velocity: 85,
          finger: 1), // B♭
      SongNote(
          note: 72,
          time: 9.5,
          duration: 0.5,
          hand: 'R',
          velocity: 85,
          finger: 3), // C
      SongNote(
          note: 74,
          time: 10.0,
          duration: 1.0,
          hand: 'R',
          velocity: 90,
          finger: 4), // D
      SongNote(
          note: 57,
          time: 10.0,
          duration: 1.0,
          hand: 'L',
          velocity: 65,
          finger: 5), // A
      SongNote(
          note: 62,
          time: 10.0,
          duration: 1.0,
          hand: 'L',
          velocity: 65,
          finger: 2), // D

      // Cadence
      SongNote(
          note: 72,
          time: 11.0,
          duration: 0.5,
          hand: 'R',
          velocity: 80,
          finger: 3), // C
      SongNote(
          note: 70,
          time: 11.5,
          duration: 0.5,
          hand: 'R',
          velocity: 75,
          finger: 2), // B♭
      SongNote(
          note: 69,
          time: 12.0,
          duration: 0.5,
          hand: 'R',
          velocity: 75,
          finger: 2), // A
      SongNote(
          note: 67,
          time: 12.5,
          duration: 0.5,
          hand: 'R',
          velocity: 70,
          finger: 1), // G
      SongNote(
          note: 65,
          time: 13.0,
          duration: 2.0,
          hand: 'R',
          velocity: 85,
          finger: 1), // F
      SongNote(
          note: 53,
          time: 13.0,
          duration: 2.0,
          hand: 'L',
          velocity: 70,
          finger: 5), // F
      SongNote(
          note: 57,
          time: 13.0,
          duration: 2.0,
          hand: 'L',
          velocity: 70,
          finger: 3), // A
      SongNote(
          note: 62,
          time: 13.0,
          duration: 2.0,
          hand: 'L',
          velocity: 70,
          finger: 1), // D

      // Additional measures to complete the main theme
      SongNote(
          note: 65,
          time: 15.0,
          duration: 0.5,
          hand: 'R',
          velocity: 75,
          finger: 1), // F
      SongNote(
          note: 67,
          time: 15.5,
          duration: 0.5,
          hand: 'R',
          velocity: 80,
          finger: 2), // G
      SongNote(
          note: 69,
          time: 16.0,
          duration: 1.0,
          hand: 'R',
          velocity: 85,
          finger: 3), // A
      SongNote(
          note: 53,
          time: 16.0,
          duration: 1.0,
          hand: 'L',
          velocity: 65,
          finger: 5), // F
      SongNote(
          note: 57,
          time: 16.0,
          duration: 1.0,
          hand: 'L',
          velocity: 65,
          finger: 3), // A

      SongNote(
          note: 69,
          time: 17.0,
          duration: 0.5,
          hand: 'R',
          velocity: 80,
          finger: 3), // A
      SongNote(
          note: 67,
          time: 17.5,
          duration: 0.5,
          hand: 'R',
          velocity: 75,
          finger: 2), // G
      SongNote(
          note: 65,
          time: 18.0,
          duration: 0.5,
          hand: 'R',
          velocity: 75,
          finger: 1), // F
      SongNote(
          note: 64,
          time: 18.5,
          duration: 0.5,
          hand: 'R',
          velocity: 70,
          finger: 3), // E
      SongNote(
          note: 62,
          time: 19.0,
          duration: 2.0,
          hand: 'R',
          velocity: 85,
          finger: 1), // D
      SongNote(
          note: 50,
          time: 19.0,
          duration: 2.0,
          hand: 'L',
          velocity: 70,
          finger: 5), // D
      SongNote(
          note: 53,
          time: 19.0,
          duration: 2.0,
          hand: 'L',
          velocity: 70,
          finger: 3), // F
    ];
  }

  static CompleteSong _getBeethovenMoonlightSonata() {
    return CompleteSong(
      id: 'beethoven_moonlight_sonata',
      title: 'Piano Sonata No. 14 "Moonlight" - 1st Movement',
      composer: 'Ludwig van Beethoven',
      difficulty: 'Intermediate',
      bpm: 54,
      key: 'C# minor',
      catalogNumber: 27,
      movement: 'Adagio sostenuto',
      description:
          'The famous first movement of Beethoven\'s "Moonlight" Sonata Op. 27 No. 2. Known for its haunting, melancholic melody over continuous triplet arpeggios.',
      techniques: [
        'Triplet arpeggios',
        'Sustained melody',
        'Pedal technique',
        'Hand independence',
        'Legato playing',
        'Dynamic control',
        'Phrasing'
      ],
      notes: _getBeethovenMoonlightSonataNotes(),
    );
  }

  static List<SongNote> _getBeethovenMoonlightSonataNotes() {
    return [
      // Opening triplet pattern - Measure 1
      SongNote(
          note: 49,
          time: 0.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 5), // C♯
      SongNote(
          note: 56,
          time: 0.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 2), // G♯
      SongNote(
          note: 61,
          time: 0.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 1), // C♯

      SongNote(
          note: 65,
          time: 0.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 5), // F
      SongNote(
          note: 68,
          time: 0.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 3), // G♯
      SongNote(
          note: 73,
          time: 0.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 1), // C♯

      // Triplet continuation
      SongNote(
          note: 49,
          time: 0.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 5), // C♯
      SongNote(
          note: 56,
          time: 0.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 2), // G♯
      SongNote(
          note: 61,
          time: 0.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 1), // C♯

      SongNote(
          note: 65,
          time: 0.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 5), // F
      SongNote(
          note: 68,
          time: 0.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 3), // G♯
      SongNote(
          note: 73,
          time: 0.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 1), // C♯

      SongNote(
          note: 49,
          time: 1.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 5), // C♯
      SongNote(
          note: 56,
          time: 1.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 2), // G♯
      SongNote(
          note: 61,
          time: 1.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 1), // C♯

      SongNote(
          note: 65,
          time: 1.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 5), // F
      SongNote(
          note: 68,
          time: 1.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 3), // G♯
      SongNote(
          note: 73,
          time: 1.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 1), // C♯

      // Main melody begins - Measure 2
      SongNote(
          note: 49,
          time: 1.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 5), // C♯
      SongNote(
          note: 56,
          time: 1.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 2), // G♯
      SongNote(
          note: 61,
          time: 1.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 1), // C♯

      SongNote(
          note: 65,
          time: 1.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 5), // F
      SongNote(
          note: 68,
          time: 1.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 3), // G♯
      SongNote(
          note: 73,
          time: 1.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 1), // C♯
      SongNote(
          note: 76,
          time: 1.5,
          duration: 1.0,
          hand: 'R',
          velocity: 70,
          finger: 4), // E (melody note)

      // Next measure
      SongNote(
          note: 49,
          time: 2.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 5), // C♯
      SongNote(
          note: 56,
          time: 2.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 2), // G♯
      SongNote(
          note: 61,
          time: 2.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 1), // C♯

      SongNote(
          note: 65,
          time: 2.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 5), // F
      SongNote(
          note: 68,
          time: 2.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 3), // G♯
      SongNote(
          note: 73,
          time: 2.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 1), // C♯

      SongNote(
          note: 49,
          time: 2.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 5), // C♯
      SongNote(
          note: 56,
          time: 2.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 2), // G♯
      SongNote(
          note: 61,
          time: 2.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 1), // C♯

      SongNote(
          note: 65,
          time: 2.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 5), // F
      SongNote(
          note: 68,
          time: 2.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 3), // G♯
      SongNote(
          note: 73,
          time: 2.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 1), // C♯
      SongNote(
          note: 76,
          time: 2.5,
          duration: 1.0,
          hand: 'R',
          velocity: 70,
          finger: 4), // E (melody note)

      // Third measure - melody moves
      SongNote(
          note: 49,
          time: 3.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 5), // C♯
      SongNote(
          note: 56,
          time: 3.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 2), // G♯
      SongNote(
          note: 61,
          time: 3.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 1), // C♯

      SongNote(
          note: 65,
          time: 3.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 5), // F
      SongNote(
          note: 68,
          time: 3.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 3), // G♯
      SongNote(
          note: 73,
          time: 3.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 1), // C♯

      SongNote(
          note: 49,
          time: 3.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 5), // C♯
      SongNote(
          note: 56,
          time: 3.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 2), // G♯
      SongNote(
          note: 61,
          time: 3.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 1), // C♯

      SongNote(
          note: 65,
          time: 3.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 5), // F
      SongNote(
          note: 68,
          time: 3.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 3), // G♯
      SongNote(
          note: 73,
          time: 3.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 1), // C♯
      SongNote(
          note: 77,
          time: 3.5,
          duration: 1.0,
          hand: 'R',
          velocity: 75,
          finger: 5), // F (melody note)

      // Fourth measure
      SongNote(
          note: 49,
          time: 4.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 5), // C♯
      SongNote(
          note: 56,
          time: 4.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 2), // G♯
      SongNote(
          note: 61,
          time: 4.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 1), // C♯

      SongNote(
          note: 65,
          time: 4.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 5), // F
      SongNote(
          note: 68,
          time: 4.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 3), // G♯
      SongNote(
          note: 73,
          time: 4.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 1), // C♯

      SongNote(
          note: 49,
          time: 4.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 5), // C♯
      SongNote(
          note: 56,
          time: 4.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 2), // G♯
      SongNote(
          note: 61,
          time: 4.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 1), // C♯

      SongNote(
          note: 65,
          time: 4.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 5), // F
      SongNote(
          note: 68,
          time: 4.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 3), // G♯
      SongNote(
          note: 73,
          time: 4.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 1), // C♯
      SongNote(
          note: 76,
          time: 4.5,
          duration: 1.0,
          hand: 'R',
          velocity: 70,
          finger: 4), // E (melody note)

      // Additional measures to complete the main theme
      SongNote(
          note: 51,
          time: 5.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 5), // D♯
      SongNote(
          note: 56,
          time: 5.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 2), // G♯
      SongNote(
          note: 63,
          time: 5.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 1), // D♯

      SongNote(
          note: 66,
          time: 5.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 5), // F♯
      SongNote(
          note: 68,
          time: 5.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 3), // G♯
      SongNote(
          note: 75,
          time: 5.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 1), // D♯
      SongNote(
          note: 78,
          time: 5.0,
          duration: 1.0,
          hand: 'R',
          velocity: 75,
          finger: 4), // F♯ (melody note)

      SongNote(
          note: 51,
          time: 5.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 5), // D♯
      SongNote(
          note: 56,
          time: 5.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 2), // G♯
      SongNote(
          note: 63,
          time: 5.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 1), // D♯

      SongNote(
          note: 66,
          time: 5.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 5), // F♯
      SongNote(
          note: 68,
          time: 5.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 3), // G♯
      SongNote(
          note: 75,
          time: 5.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 1), // D♯
      SongNote(
          note: 78,
          time: 5.5,
          duration: 1.0,
          hand: 'R',
          velocity: 75,
          finger: 4), // F♯ (melody note)
    ];
  }

  static CompleteSong _getDebussyClairDeLune() {
    return CompleteSong(
      id: 'debussy_clair_de_lune',
      title: 'Clair de Lune',
      composer: 'Claude Debussy',
      difficulty: 'Advanced',
      bpm: 46,
      key: 'D♭ Major',
      catalogNumber: 75,
      movement: 'Suite bergamasque, No. 3',
      description:
          'One of Debussy\'s most beloved compositions, meaning "Moonlight". Features impressionistic harmonies, flowing arpeggios, and a dreamlike quality.',
      techniques: [
        'Complex arpeggios',
        'Pedal technique',
        'Voicing',
        'Rubato',
        'Hand crossing',
        'Wide stretches',
        'Impressionist harmony',
      ],
      notes: _getDebussyClairDeLuneNotes(),
    );
  }

  static List<SongNote> _getDebussyClairDeLuneNotes() {
    return [
      // Opening measures - Andante très expressif
      // Measure 1 - Opening arpeggio
      SongNote(
          note: 49,
          time: 0.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 5), // C#2
      SongNote(
          note: 56,
          time: 0.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 2), // G#2
      SongNote(
          note: 61,
          time: 1.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 1), // C#3

      SongNote(
          note: 61,
          time: 0.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 5), // C#3
      SongNote(
          note: 68,
          time: 0.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 2), // G#3
      SongNote(
          note: 73,
          time: 1.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 1), // C#4

      // Measure 2
      SongNote(
          note: 49,
          time: 1.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 5), // C#2
      SongNote(
          note: 56,
          time: 2.0,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 2), // G#2
      SongNote(
          note: 61,
          time: 2.5,
          duration: 0.5,
          hand: 'L',
          velocity: 50,
          finger: 1), // C#3

      SongNote(
          note: 61,
          time: 1.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 5), // C#3
      SongNote(
          note: 68,
          time: 2.0,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 2), // G#3
      SongNote(
          note: 73,
          time: 2.5,
          duration: 0.5,
          hand: 'R',
          velocity: 55,
          finger: 1), // C#4

      // Famous melody entrance - Measure 3
      SongNote(
          note: 54,
          time: 3.0,
          duration: 1.0,
          hand: 'L',
          velocity: 50,
          finger: 5), // F#2
      SongNote(
          note: 61,
          time: 3.0,
          duration: 1.0,
          hand: 'L',
          velocity: 50,
          finger: 2), // C#3
      SongNote(
          note: 66,
          time: 3.0,
          duration: 1.0,
          hand: 'L',
          velocity: 50,
          finger: 1), // F#3

      SongNote(
          note: 73,
          time: 3.0,
          duration: 2.0,
          hand: 'R',
          velocity: 70,
          finger: 3), // C#4 - Melody note
      SongNote(
          note: 75,
          time: 5.0,
          duration: 1.0,
          hand: 'R',
          velocity: 75,
          finger: 4), // D#4

      // Measure 4
      SongNote(
          note: 54,
          time: 6.0,
          duration: 1.0,
          hand: 'L',
          velocity: 50,
          finger: 5), // F#2
      SongNote(
          note: 61,
          time: 6.0,
          duration: 1.0,
          hand: 'L',
          velocity: 50,
          finger: 2), // C#3
      SongNote(
          note: 66,
          time: 6.0,
          duration: 1.0,
          hand: 'L',
          velocity: 50,
          finger: 1), // F#3

      SongNote(
          note: 78,
          time: 6.0,
          duration: 2.0,
          hand: 'R',
          velocity: 80,
          finger: 5), // F#4 - Melody peak
      SongNote(
          note: 75,
          time: 8.0,
          duration: 1.0,
          hand: 'R',
          velocity: 75,
          finger: 3), // D#4
    ];
  }

  static CompleteSong _getBachPreludeInCMajor() {
    return CompleteSong(
      id: 'bach_prelude_c_major',
      title: 'Prelude in C Major, BWV 846',
      composer: 'Johann Sebastian Bach',
      difficulty: 'Advanced',
      bpm: 72,
      key: 'C Major',
      catalogNumber: 846,
      movement: 'Well-Tempered Clavier, Book I',
      description:
          'The first prelude from Bach\'s Well-Tempered Clavier. Features continuous arpeggiated patterns and harmonic progressions. Made famous by Gounod\'s Ave Maria.',
      techniques: [
        'Arpeggio patterns',
        'Harmonic progression',
        'Hand position shifts',
        'Sustained pedaling',
        'Even articulation',
        'Baroque style',
      ],
      notes: _getBachPreludeInCMajorNotes(),
    );
  }

  static List<SongNote> _getBachPreludeInCMajorNotes() {
    return [
      // Measure 1 - C Major arpeggio pattern
      SongNote(
          note: 60,
          time: 0.0,
          duration: 0.25,
          hand: 'L',
          velocity: 65,
          finger: 5), // C3
      SongNote(
          note: 64,
          time: 0.25,
          duration: 0.25,
          hand: 'L',
          velocity: 65,
          finger: 3), // E3
      SongNote(
          note: 67,
          time: 0.5,
          duration: 0.25,
          hand: 'L',
          velocity: 65,
          finger: 2), // G3
      SongNote(
          note: 72,
          time: 0.75,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 1), // C4
      SongNote(
          note: 76,
          time: 1.0,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 3), // E4
      SongNote(
          note: 67,
          time: 1.25,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 2), // G4
      SongNote(
          note: 72,
          time: 1.5,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 1), // C4
      SongNote(
          note: 76,
          time: 1.75,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 3), // E4

      // Measure 2 - D minor 7 pattern
      SongNote(
          note: 62,
          time: 2.0,
          duration: 0.25,
          hand: 'L',
          velocity: 65,
          finger: 5), // D3
      SongNote(
          note: 65,
          time: 2.25,
          duration: 0.25,
          hand: 'L',
          velocity: 65,
          finger: 3), // F3
      SongNote(
          note: 69,
          time: 2.5,
          duration: 0.25,
          hand: 'L',
          velocity: 65,
          finger: 2), // A3
      SongNote(
          note: 72,
          time: 2.75,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 1), // C4
      SongNote(
          note: 77,
          time: 3.0,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 4), // F4
      SongNote(
          note: 69,
          time: 3.25,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 2), // A4
      SongNote(
          note: 72,
          time: 3.5,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 1), // C4
      SongNote(
          note: 77,
          time: 3.75,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 4), // F4

      // Measure 3 - G dominant 7 pattern
      SongNote(
          note: 59,
          time: 4.0,
          duration: 0.25,
          hand: 'L',
          velocity: 65,
          finger: 5), // B2
      SongNote(
          note: 62,
          time: 4.25,
          duration: 0.25,
          hand: 'L',
          velocity: 65,
          finger: 4), // D3
      SongNote(
          note: 67,
          time: 4.5,
          duration: 0.25,
          hand: 'L',
          velocity: 65,
          finger: 2), // G3
      SongNote(
          note: 72,
          time: 4.75,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 1), // C4
      SongNote(
          note: 76,
          time: 5.0,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 3), // E4
      SongNote(
          note: 67,
          time: 5.25,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 2), // G4
      SongNote(
          note: 72,
          time: 5.5,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 1), // C4
      SongNote(
          note: 76,
          time: 5.75,
          duration: 0.25,
          hand: 'R',
          velocity: 70,
          finger: 3), // E4
    ];
  }

  // ============================================
  // UTILITY METHODS
  // ============================================

  static CompleteSong? getSongById(String id) {
    try {
      return getSongs().firstWhere((song) => song.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<CompleteSong> getSongsByDifficulty(String difficulty) {
    return getSongs().where((song) => song.difficulty == difficulty).toList();
  }

  static List<CompleteSong> getSongsByComposer(String composer) {
    return getSongs()
        .where((song) =>
            song.composer.toLowerCase().contains(composer.toLowerCase()))
        .toList();
  }

  static List<String> getAllComposers() {
    return getSongs().map((song) => song.composer).toSet().toList()..sort();
  }

  static List<String> getAllDifficulties() {
    return getSongs().map((song) => song.difficulty).toSet().toList()..sort();
  }
}

// ============================================
// HELPER: MIDI to SongNote Converter
// ============================================
// Use this class if you have MIDI files to convert

class MidiToSongNoteConverter {
  /// Convert a list of MIDI events to SongNote list
  ///
  /// Expected MIDI event format:
  /// {
  ///   'note': int (MIDI note number),
  ///   'time': double (seconds),
  ///   'duration': double (seconds),
  ///   'velocity': int (0-127),
  ///   'track': int (0 = right hand, 1 = left hand)
  /// }
  static List<SongNote> convertMidiEvents(
      List<Map<String, dynamic>> midiEvents) {
    return midiEvents.map((event) {
      return SongNote(
        note: event['note'] as int,
        time: (event['time'] as num).toDouble(),
        duration: (event['duration'] as num).toDouble(),
        hand: (event['track'] as int) == 0 ? 'R' : 'L',
        velocity: event['velocity'] as int? ?? 100,
      );
    }).toList();
  }

  /// Sort notes by time to ensure proper playback order
  static List<SongNote> sortNotes(List<SongNote> notes) {
    final sorted = List<SongNote>.from(notes);
    sorted.sort((a, b) => a.time.compareTo(b.time));
    return sorted;
  }
}
