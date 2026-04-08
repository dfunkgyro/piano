class TempoChange {
  final double time;
  final double bpm;

  const TempoChange({
    required this.time,
    required this.bpm,
  });

  factory TempoChange.fromJson(Map<String, dynamic> json) {
    return TempoChange(
      time: (json['time'] as num).toDouble(),
      bpm: (json['bpm'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        'bpm': bpm,
      };
}
