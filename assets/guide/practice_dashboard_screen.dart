import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'achievements_service.dart';

class PracticeStats {
  int totalNotesPlayed;
  int totalPracticeMinutes;
  int currentStreak;
  int longestStreak;
  DateTime? lastPracticeDate;
  Map<String, int> dailyNotes; // date -> note count
  Map<int, int> noteFrequency; // MIDI note -> count
  List<String> practiceHistory; // List of session summaries

  PracticeStats({
    this.totalNotesPlayed = 0,
    this.totalPracticeMinutes = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPracticeDate,
    Map<String, int>? dailyNotes,
    Map<int, int>? noteFrequency,
    List<String>? practiceHistory,
  })  : dailyNotes = dailyNotes ?? {},
        noteFrequency = noteFrequency ?? {},
        practiceHistory = practiceHistory ?? [];

  Map<String, dynamic> toJson() => {
        'totalNotesPlayed': totalNotesPlayed,
        'totalPracticeMinutes': totalPracticeMinutes,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastPracticeDate': lastPracticeDate?.toIso8601String(),
        'dailyNotes': dailyNotes,
        'noteFrequency': noteFrequency.map((k, v) => MapEntry(k.toString(), v)),
        'practiceHistory': practiceHistory,
      };

  factory PracticeStats.fromJson(Map<String, dynamic> json) {
    return PracticeStats(
      totalNotesPlayed: json['totalNotesPlayed'] ?? 0,
      totalPracticeMinutes: json['totalPracticeMinutes'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastPracticeDate: json['lastPracticeDate'] != null
          ? DateTime.parse(json['lastPracticeDate'])
          : null,
      dailyNotes: Map<String, int>.from(json['dailyNotes'] ?? {}),
      noteFrequency: (json['noteFrequency'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
          {},
      practiceHistory: List<String>.from(json['practiceHistory'] ?? []),
    );
  }
}

class PracticeStatsService {
  static PracticeStats _stats = PracticeStats();
  static const String _storageKey = 'practice_stats';

  static Future<void> initialize() async {
    await _loadStats();
  }

  static Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null) {
        _stats = PracticeStats.fromJson(jsonDecode(data));
      }
    } catch (e) {
      print('Error loading practice stats: $e');
    }
  }

  static Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_stats.toJson()));
    } catch (e) {
      print('Error saving practice stats: $e');
    }
  }

  static void recordNote(int midiNote) {
    _stats.totalNotesPlayed++;
    _stats.noteFrequency[midiNote] = (_stats.noteFrequency[midiNote] ?? 0) + 1;

    final today = _getTodayKey();
    _stats.dailyNotes[today] = (_stats.dailyNotes[today] ?? 0) + 1;

    _updateStreak();
    _saveStats();
  }

  static void recordPracticeTime(int minutes) {
    _stats.totalPracticeMinutes += minutes;
    _updateStreak();
    _saveStats();
  }

  static void _updateStreak() {
    final today = DateTime.now();
    final lastPractice = _stats.lastPracticeDate;

    if (lastPractice == null) {
      _stats.currentStreak = 1;
      _stats.longestStreak = 1;
    } else {
      final daysDiff = today.difference(lastPractice).inDays;

      if (daysDiff == 0) {
        // Same day, maintain streak
      } else if (daysDiff == 1) {
        // Consecutive day
        _stats.currentStreak++;
        if (_stats.currentStreak > _stats.longestStreak) {
          _stats.longestStreak = _stats.currentStreak;
        }
      } else {
        // Streak broken
        _stats.currentStreak = 1;
      }
    }

    _stats.lastPracticeDate = today;
  }

  static String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static PracticeStats get stats => _stats;

  static List<int> getMostPlayedNotes({int count = 10}) {
    final sorted = _stats.noteFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).map((e) => e.key).toList();
  }

  static Map<String, int> getWeeklyNotes() {
    final result = <String, int>{};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      result[_getDayName(date.weekday)] = _stats.dailyNotes[key] ?? 0;
    }

    return result;
  }

  static String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  static int getOctavesExplored() {
    final octaves = <int>{};
    for (var note in _stats.noteFrequency.keys) {
      octaves.add((note - 12) ~/ 12);
    }
    return octaves.length;
  }
}

class PracticeDashboardScreen extends StatefulWidget {
  final AchievementsService achievementsService;

  const PracticeDashboardScreen({
    super.key,
    required this.achievementsService,
  });

  @override
  State<PracticeDashboardScreen> createState() =>
      _PracticeDashboardScreenState();
}

class _PracticeDashboardScreenState extends State<PracticeDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final stats = PracticeStatsService.stats;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFF2C2C2E),
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.chart_bar_alt_fill,
                size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text('Practice Dashboard', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Level Display
            LevelDisplay(
              level: widget.achievementsService.level,
              totalPoints: widget.achievementsService.totalPoints,
              progress: widget.achievementsService.levelProgress,
            ),

            const SizedBox(height: 24),

            // Quick Stats Grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Notes Played',
                    value: _formatNumber(stats.totalNotesPlayed),
                    icon: CupertinoIcons.music_note_2,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Practice Time',
                    value:
                        '${(stats.totalPracticeMinutes / 60).toStringAsFixed(1)}h',
                    icon: CupertinoIcons.clock,
                    color: CupertinoColors.systemPurple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Current Streak',
                    value: '${stats.currentStreak} days',
                    icon: CupertinoIcons.flame_fill,
                    color: CupertinoColors.systemOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Longest Streak',
                    value: '${stats.longestStreak} days',
                    icon: CupertinoIcons.star_fill,
                    color: CupertinoColors.systemYellow,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Weekly Activity Chart
            _buildWeeklyChart(),

            const SizedBox(height: 24),

            // Most Played Notes
            _buildMostPlayedNotes(),

            const SizedBox(height: 24),

            // Recent Achievements
            _buildRecentAchievements(),

            const SizedBox(height: 24),

            // Progress Summary
            _buildProgressSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final weeklyData = PracticeStatsService.getWeeklyNotes();
    final maxValue = weeklyData.values.isEmpty
        ? 100
        : weeklyData.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.graph_square_fill,
                color: CupertinoColors.systemBlue,
              ),
              SizedBox(width: 8),
              Text(
                'Weekly Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weeklyData.entries.map((entry) {
              final height = maxValue > 0
                  ? (entry.value / maxValue * 100).clamp(10.0, 100.0)
                  : 10.0;

              return Column(
                children: [
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: height.toDouble(),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          CupertinoColors.systemBlue,
                          CupertinoColors.systemPurple,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMostPlayedNotes() {
    final topNotes = PracticeStatsService.getMostPlayedNotes(count: 5);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.music_note_list,
                color: CupertinoColors.systemGreen,
              ),
              SizedBox(width: 8),
              Text(
                'Most Played Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topNotes.asMap().entries.map((entry) {
            final index = entry.key;
            final note = entry.value;
            final count = PracticeStatsService.stats.noteFrequency[note] ?? 0;
            final noteName = _getNoteNameFromMidi(note);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _getRankColor(index),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          noteName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$count times',
                          style: const TextStyle(
                            fontSize: 11,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentAchievements() {
    final recent =
        widget.achievementsService.unlockedAchievements.take(3).toList();

    if (recent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.star_fill,
                color: CupertinoColors.systemYellow,
              ),
              SizedBox(width: 8),
              Text(
                'Recent Achievements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recent.map((achievement) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      achievement.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '+${achievement.points} points',
                            style: const TextStyle(
                              fontSize: 11,
                              color: CupertinoColors.systemYellow,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildProgressSummary() {
    final octavesExplored = PracticeStatsService.getOctavesExplored();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.chart_pie_fill,
                color: CupertinoColors.systemTeal,
              ),
              SizedBox(width: 8),
              Text(
                'Progress Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _progressItem('Octaves Explored', '$octavesExplored/7'),
          _progressItem('Achievements',
              '${widget.achievementsService.unlockedAchievements.length}/${widget.achievementsService.allAchievements.length}'),
          _progressItem('Unique Notes Played',
              '${PracticeStatsService.stats.noteFrequency.length}/88'),
        ],
      ),
    );
  }

  Widget _progressItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.systemTeal,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return CupertinoColors.systemYellow;
      case 1:
        return CupertinoColors.systemGrey;
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return CupertinoColors.systemBlue;
    }
  }

  String _getNoteNameFromMidi(int midiNote) {
    const noteNames = [
      'A',
      'A#',
      'B',
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#'
    ];
    final octave = (midiNote - 12) ~/ 12;
    final noteIndex = (midiNote - 21) % 12;
    return '${noteNames[noteIndex]}$octave';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }
}
