// ============================================
// song_progress.dart
// ============================================

class SongProgress {
  final String id;
  final String userId;
  final String songId;
  final String songTitle;
  final String composer;
  final String? difficulty;
  final int attempts;
  final double bestAccuracy;
  final double? bestTime;
  final bool completed;
  final DateTime firstAttempted;
  final DateTime lastAttempted;
  final int masteryLevel;
  final Map<String, dynamic> sectionsMastered;
  final Map<String, dynamic> notesPerSection;

  SongProgress({
    required this.id,
    required this.userId,
    required this.songId,
    required this.songTitle,
    required this.composer,
    this.difficulty,
    this.attempts = 1,
    this.bestAccuracy = 0.0,
    this.bestTime,
    this.completed = false,
    required this.firstAttempted,
    required this.lastAttempted,
    this.masteryLevel = 0,
    this.sectionsMastered = const {},
    this.notesPerSection = const {},
  });

  factory SongProgress.fromJson(Map<String, dynamic> json) {
    return SongProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      songId: json['song_id'] as String,
      songTitle: json['song_title'] as String,
      composer: json['composer'] as String,
      difficulty: json['difficulty'] as String?,
      attempts: json['attempts'] as int? ?? 1,
      bestAccuracy: (json['best_accuracy'] as num?)?.toDouble() ?? 0.0,
      bestTime: (json['best_time'] as num?)?.toDouble(),
      completed: json['completed'] as bool? ?? false,
      firstAttempted: DateTime.parse(json['first_attempted'] as String),
      lastAttempted: DateTime.parse(json['last_attempted'] as String),
      masteryLevel: json['mastery_level'] as int? ?? 0,
      sectionsMastered:
          json['sections_mastered'] as Map<String, dynamic>? ?? {},
      notesPerSection: json['notes_per_section'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'song_id': songId,
      'song_title': songTitle,
      'composer': composer,
      'difficulty': difficulty,
      'attempts': attempts,
      'best_accuracy': bestAccuracy,
      'best_time': bestTime,
      'completed': completed,
      'first_attempted': firstAttempted.toIso8601String(),
      'last_attempted': lastAttempted.toIso8601String(),
      'mastery_level': masteryLevel,
      'sections_mastered': sectionsMastered,
      'notes_per_section': notesPerSection,
    };
  }

  String get masteryDescription {
    if (masteryLevel >= 90) return 'Master';
    if (masteryLevel >= 70) return 'Advanced';
    if (masteryLevel >= 50) return 'Intermediate';
    if (masteryLevel >= 30) return 'Learning';
    return 'Beginner';
  }

  double get progressPercentage {
    return masteryLevel / 100.0;
  }

  SongProgress copyWith({
    int? attempts,
    double? bestAccuracy,
    double? bestTime,
    bool? completed,
    DateTime? lastAttempted,
    int? masteryLevel,
    Map<String, dynamic>? sectionsMastered,
    Map<String, dynamic>? notesPerSection,
  }) {
    return SongProgress(
      id: id,
      userId: userId,
      songId: songId,
      songTitle: songTitle,
      composer: composer,
      difficulty: difficulty,
      attempts: attempts ?? this.attempts,
      bestAccuracy: bestAccuracy ?? this.bestAccuracy,
      bestTime: bestTime ?? this.bestTime,
      completed: completed ?? this.completed,
      firstAttempted: firstAttempted,
      lastAttempted: lastAttempted ?? this.lastAttempted,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      sectionsMastered: sectionsMastered ?? this.sectionsMastered,
      notesPerSection: notesPerSection ?? this.notesPerSection,
    );
  }
}
