// ============================================
// achievement.dart
// ============================================

class Achievement {
  final String id;
  final String type;
  final String title;
  final String description;
  final String iconName;
  final DateTime earnedAt;
  final Map<String, dynamic> data;

  Achievement({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.iconName,
    required this.earnedAt,
    this.data = const {},
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String? ?? '',
      type: json['achievement_type'] as String? ?? json['type'] as String,
      title: json['title'] as String? ??
          _getTitleFromType(json['achievement_type'] as String),
      description: json['description'] as String? ?? '',
      iconName: json['icon_name'] as String? ?? 'star',
      earnedAt: json['earned_at'] != null
          ? DateTime.parse(json['earned_at'] as String)
          : DateTime.now(),
      data: json['achievement_data'] as Map<String, dynamic>? ??
          json['data'] as Map<String, dynamic>? ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'achievement_type': type,
      'title': title,
      'description': description,
      'icon_name': iconName,
      'earned_at': earnedAt.toIso8601String(),
      'achievement_data': data,
    };
  }

  static String _getTitleFromType(String type) {
    switch (type) {
      case 'first_practice':
        return 'First Practice';
      case 'practice_streak_7':
        return '7-Day Streak';
      case 'practice_streak_30':
        return '30-Day Streak';
      case 'song_completed':
        return 'Song Master';
      case 'notes_100':
        return '100 Notes';
      case 'notes_1000':
        return '1000 Notes';
      case 'perfect_performance':
        return 'Perfect Performance';
      default:
        return type.replaceAll('_', ' ');
    }
  }
}

// ============================================
// device.dart
// ============================================

class MidiDevice {
  final String id;
  final String name;
  final String type;
  final bool isFavorite;
  final bool autoConnect;
  final DateTime lastUsed;
  final double? latencyPreset;
  final int connectionCount;
  final double? avgLatency;
  final String? notes;

  MidiDevice({
    required this.id,
    required this.name,
    required this.type,
    this.isFavorite = false,
    this.autoConnect = true,
    required this.lastUsed,
    this.latencyPreset,
    this.connectionCount = 1,
    this.avgLatency,
    this.notes,
  });

  factory MidiDevice.fromJson(Map<String, dynamic> json) {
    return MidiDevice(
      id: json['device_id'] as String? ?? json['id'] as String,
      name: json['device_name'] as String? ?? json['name'] as String,
      type: json['device_type'] as String? ?? json['type'] as String? ?? 'BLE',
      isFavorite: json['favorite'] as bool? ?? false,
      autoConnect: json['auto_connect'] as bool? ?? true,
      lastUsed: json['last_used'] != null
          ? DateTime.parse(json['last_used'] as String)
          : DateTime.now(),
      latencyPreset: (json['latency_preset'] as num?)?.toDouble(),
      connectionCount: json['connection_count'] as int? ?? 1,
      avgLatency: (json['avg_latency'] as num?)?.toDouble(),
      notes: json['device_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': id,
      'device_name': name,
      'device_type': type,
      'favorite': isFavorite,
      'auto_connect': autoConnect,
      'last_used': lastUsed.toIso8601String(),
      'latency_preset': latencyPreset,
      'connection_count': connectionCount,
      'avg_latency': avgLatency,
      'device_notes': notes,
    };
  }

  MidiDevice copyWith({
    bool? isFavorite,
    bool? autoConnect,
    DateTime? lastUsed,
    double? latencyPreset,
    int? connectionCount,
    double? avgLatency,
    String? notes,
  }) {
    return MidiDevice(
      id: id,
      name: name,
      type: type,
      isFavorite: isFavorite ?? this.isFavorite,
      autoConnect: autoConnect ?? this.autoConnect,
      lastUsed: lastUsed ?? this.lastUsed,
      latencyPreset: latencyPreset ?? this.latencyPreset,
      connectionCount: connectionCount ?? this.connectionCount,
      avgLatency: avgLatency ?? this.avgLatency,
      notes: notes ?? this.notes,
    );
  }
}
