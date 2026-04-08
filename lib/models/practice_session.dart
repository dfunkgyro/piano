// ============================================
// practice_session.dart
// ============================================

class PracticeSession {
  final String id;
  final String userId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationMinutes;
  final int notesPlayed;
  final double accuracyPercentage;
  final int mistakes;
  final List<String> songsPracticed;
  final List<String> devicesUsed;
  final double? latencySetting;
  final Map<String, dynamic> sessionData;

  PracticeSession({
    required this.id,
    required this.userId,
    required this.startedAt,
    this.endedAt,
    this.durationMinutes,
    this.notesPlayed = 0,
    this.accuracyPercentage = 0.0,
    this.mistakes = 0,
    this.songsPracticed = const [],
    this.devicesUsed = const [],
    this.latencySetting,
    this.sessionData = const {},
  });

  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    return PracticeSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      durationMinutes: json['duration_minutes'] as int?,
      notesPlayed: json['notes_played'] as int? ?? 0,
      accuracyPercentage: (json['accuracy_percentage'] as num?)?.toDouble() ?? 0.0,
      mistakes: json['mistakes'] as int? ?? 0,
      songsPracticed: (json['songs_practiced'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      devicesUsed: (json['devices_used'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      latencySetting: (json['latency_setting'] as num?)?.toDouble(),
      sessionData: json['session_data'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'notes_played': notesPlayed,
      'accuracy_percentage': accuracyPercentage,
      'mistakes': mistakes,
      'songs_practiced': songsPracticed,
      'devices_used': devicesUsed,
      'latency_setting': latencySetting,
      'session_data': sessionData,
    };
  }

  bool get isActive => endedAt == null;

  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  PracticeSession copyWith({
    DateTime? endedAt,
    int? durationMinutes,
    int? notesPlayed,
    double? accuracyPercentage,
    int? mistakes,
    List<String>? songsPracticed,
    Map<String, dynamic>? sessionData,
  }) {
    return PracticeSession(
      id: id,
      userId: userId,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notesPlayed: notesPlayed ?? this.notesPlayed,
      accuracyPercentage: accuracyPercentage ?? this.accuracyPercentage,
      mistakes: mistakes ?? this.mistakes,
      songsPracticed: songsPracticed ?? this.songsPracticed,
      devicesUsed: devicesUsed,
      latencySetting: latencySetting,
      sessionData: sessionData ?? this.sessionData,
    );
  }
}

