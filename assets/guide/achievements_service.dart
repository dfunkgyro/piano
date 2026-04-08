import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum AchievementCategory { practice, skill, mastery, social, exploration }

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementCategory category;
  final int points;
  final int targetValue;
  final String metric; // 'notesPlayed', 'songsCompleted', etc.
  bool isUnlocked;
  int currentProgress;
  DateTime? unlockedDate;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.points,
    required this.targetValue,
    required this.metric,
    this.isUnlocked = false,
    this.currentProgress = 0,
    this.unlockedDate,
  });

  double get progressPercent =>
      (currentProgress / targetValue * 100).clamp(0, 100);

  Map<String, dynamic> toJson() => {
        'id': id,
        'isUnlocked': isUnlocked,
        'currentProgress': currentProgress,
        'unlockedDate': unlockedDate?.toIso8601String(),
      };

  factory Achievement.fromJson(
    Map<String, dynamic> json,
    Achievement template,
  ) {
    return Achievement(
      id: template.id,
      title: template.title,
      description: template.description,
      emoji: template.emoji,
      category: template.category,
      points: template.points,
      targetValue: template.targetValue,
      metric: template.metric,
      isUnlocked: json['isUnlocked'] ?? false,
      currentProgress: json['currentProgress'] ?? 0,
      unlockedDate: json['unlockedDate'] != null
          ? DateTime.parse(json['unlockedDate'])
          : null,
    );
  }
}

class AchievementsService {
  static final List<Achievement> _allAchievements = [
    // Practice Achievements
    Achievement(
      id: 'first_notes',
      title: 'First Steps',
      description: 'Play your first 100 notes',
      emoji: '🎹',
      category: AchievementCategory.practice,
      points: 10,
      targetValue: 100,
      metric: 'notesPlayed',
    ),
    Achievement(
      id: 'thousand_notes',
      title: 'Thousand Notes',
      description: 'Play 1000 notes',
      emoji: '🏆',
      category: AchievementCategory.practice,
      points: 50,
      targetValue: 1000,
      metric: 'notesPlayed',
    ),
    Achievement(
      id: 'ten_thousand_notes',
      title: 'Note Master',
      description: 'Play 10,000 notes',
      emoji: '⭐',
      category: AchievementCategory.practice,
      points: 200,
      targetValue: 10000,
      metric: 'notesPlayed',
    ),
    Achievement(
      id: 'practice_streak_7',
      title: 'Perfect Week',
      description: 'Practice 7 days in a row',
      emoji: '🔥',
      category: AchievementCategory.practice,
      points: 100,
      targetValue: 7,
      metric: 'practiceStreak',
    ),
    Achievement(
      id: 'practice_streak_30',
      title: 'Monthly Dedication',
      description: 'Practice 30 days in a row',
      emoji: '💪',
      category: AchievementCategory.practice,
      points: 500,
      targetValue: 30,
      metric: 'practiceStreak',
    ),
    Achievement(
      id: 'practice_hours_10',
      title: 'Ten Hours',
      description: 'Practice for 10 total hours',
      emoji: '⏰',
      category: AchievementCategory.practice,
      points: 150,
      targetValue: 600, // minutes
      metric: 'totalPracticeMinutes',
    ),
    Achievement(
      id: 'practice_hours_100',
      title: 'Dedicated Student',
      description: 'Practice for 100 total hours',
      emoji: '🎓',
      category: AchievementCategory.practice,
      points: 1000,
      targetValue: 6000, // minutes
      metric: 'totalPracticeMinutes',
    ),

    // Skill Achievements
    Achievement(
      id: 'full_range_explorer',
      title: 'Full Range Explorer',
      description: 'Play all 88 keys in one session',
      emoji: '🌈',
      category: AchievementCategory.exploration,
      points: 75,
      targetValue: 88,
      metric: 'uniqueKeysPlayed',
    ),
    Achievement(
      id: 'speed_demon',
      title: 'Speed Demon',
      description: 'Play a scale at 200 BPM',
      emoji: '⚡',
      category: AchievementCategory.skill,
      points: 150,
      targetValue: 200,
      metric: 'maxScaleBPM',
    ),
    Achievement(
      id: 'perfect_accuracy',
      title: 'Perfectionist',
      description: 'Complete a song with 100% accuracy',
      emoji: '💯',
      category: AchievementCategory.skill,
      points: 100,
      targetValue: 100,
      metric: 'perfectSongAccuracy',
    ),
    Achievement(
      id: 'beethoven_apprentice',
      title: "Beethoven's Apprentice",
      description: 'Complete all classical songs',
      emoji: '🎼',
      category: AchievementCategory.mastery,
      points: 300,
      targetValue: 6,
      metric: 'classicalSongsCompleted',
    ),
    Achievement(
      id: 'chord_master',
      title: 'Chord Master',
      description: 'Learn 50 different chords',
      emoji: '🌟',
      category: AchievementCategory.mastery,
      points: 250,
      targetValue: 50,
      metric: 'uniqueChordsLearned',
    ),
    Achievement(
      id: 'scale_master',
      title: 'Scale Master',
      description: 'Master all 12 major scales',
      emoji: '🎯',
      category: AchievementCategory.mastery,
      points: 200,
      targetValue: 12,
      metric: 'majorScalesMastered',
    ),
    Achievement(
      id: 'ear_training',
      title: 'Perfect Pitch',
      description: 'Complete 100 ear training exercises',
      emoji: '👂',
      category: AchievementCategory.skill,
      points: 175,
      targetValue: 100,
      metric: 'earTrainingCompleted',
    ),
    Achievement(
      id: 'sight_reading',
      title: 'Sight Reader',
      description: 'Complete 50 sight reading exercises',
      emoji: '📖',
      category: AchievementCategory.skill,
      points: 150,
      targetValue: 50,
      metric: 'sightReadingCompleted',
    ),

    // Exploration Achievements
    Achievement(
      id: 'octave_explorer',
      title: 'Octave Explorer',
      description: 'Play notes in all 7 octaves',
      emoji: '🔍',
      category: AchievementCategory.exploration,
      points: 50,
      targetValue: 7,
      metric: 'octavesExplored',
    ),
    Achievement(
      id: 'all_scales',
      title: 'Scale Collector',
      description: 'Try all scale types (major, minor, pentatonic, etc.)',
      emoji: '📚',
      category: AchievementCategory.exploration,
      points: 100,
      targetValue: 10,
      metric: 'scaleTypesPlayed',
    ),

    // Daily/Weekly Challenges
    Achievement(
      id: 'daily_challenge_complete',
      title: 'Daily Champion',
      description: 'Complete a daily challenge',
      emoji: '🏅',
      category: AchievementCategory.practice,
      points: 25,
      targetValue: 1,
      metric: 'dailyChallengesCompleted',
    ),
    Achievement(
      id: 'weekly_warrior',
      title: 'Weekly Warrior',
      description: 'Complete 7 daily challenges',
      emoji: '⚔️',
      category: AchievementCategory.practice,
      points: 200,
      targetValue: 7,
      metric: 'dailyChallengesCompleted',
    ),
  ];

  List<Achievement> _achievements = [];
  int _totalPoints = 0;
  int _level = 1;
  Function(Achievement)? onAchievementUnlocked;

  Future<void> initialize() async {
    await _loadAchievements();
    _calculateLevel();
  }

  Future<void> _loadAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('achievements');

      if (savedData != null) {
        final Map<String, dynamic> data = jsonDecode(savedData);

        _achievements = _allAchievements.map((template) {
          if (data.containsKey(template.id)) {
            return Achievement.fromJson(data[template.id], template);
          }
          return template;
        }).toList();
      } else {
        _achievements = List.from(_allAchievements);
      }

      _totalPoints = _achievements
          .where((a) => a.isUnlocked)
          .fold(0, (sum, a) => sum + a.points);
    } catch (e) {
      print('Error loading achievements: $e');
      _achievements = List.from(_allAchievements);
    }
  }

  Future<void> _saveAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = {
        for (var achievement in _achievements)
          achievement.id: achievement.toJson(),
      };
      await prefs.setString('achievements', jsonEncode(data));
    } catch (e) {
      print('Error saving achievements: $e');
    }
  }

  void updateProgress(String metric, int value) {
    for (var achievement in _achievements) {
      if (achievement.metric == metric && !achievement.isUnlocked) {
        achievement.currentProgress = value;

        if (achievement.currentProgress >= achievement.targetValue) {
          _unlockAchievement(achievement);
        }
      }
    }
    _saveAchievements();
  }

  void incrementProgress(String metric, {int amount = 1}) {
    for (var achievement in _achievements) {
      if (achievement.metric == metric && !achievement.isUnlocked) {
        achievement.currentProgress += amount;

        if (achievement.currentProgress >= achievement.targetValue) {
          _unlockAchievement(achievement);
        }
      }
    }
    _saveAchievements();
  }

  void _unlockAchievement(Achievement achievement) {
    achievement.isUnlocked = true;
    achievement.unlockedDate = DateTime.now();
    _totalPoints += achievement.points;
    _calculateLevel();

    onAchievementUnlocked?.call(achievement);
    _saveAchievements();

    print('🏆 Achievement Unlocked: ${achievement.title}');
  }

  void _calculateLevel() {
    // Simple level calculation: 100 points per level
    _level = (_totalPoints / 100).floor() + 1;
  }

  List<Achievement> get allAchievements => List.from(_achievements);

  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();

  List<Achievement> get lockedAchievements =>
      _achievements.where((a) => !a.isUnlocked).toList();

  List<Achievement> get inProgressAchievements => _achievements
      .where((a) => !a.isUnlocked && a.currentProgress > 0)
      .toList();

  List<Achievement> getAchievementsByCategory(AchievementCategory category) =>
      _achievements.where((a) => a.category == category).toList();

  int get totalPoints => _totalPoints;
  int get level => _level;
  int get pointsToNextLevel => (level * 100) - _totalPoints;
  double get levelProgress => (_totalPoints % 100) / 100;

  Map<String, dynamic> getStats() {
    return {
      'totalAchievements': _achievements.length,
      'unlockedCount': unlockedAchievements.length,
      'totalPoints': _totalPoints,
      'level': _level,
      'completionPercent':
          (unlockedAchievements.length / _achievements.length * 100)
              .toStringAsFixed(1),
    };
  }
}

// Achievement Card Widget
class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool showProgress;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: achievement.isUnlocked
            ? LinearGradient(
                colors: [
                  CupertinoColors.systemYellow.withOpacity(0.2),
                  CupertinoColors.systemOrange.withOpacity(0.2),
                ],
              )
            : null,
        color: achievement.isUnlocked ? null : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achievement.isUnlocked
              ? CupertinoColors.systemYellow
              : CupertinoColors.systemGrey5,
          width: achievement.isUnlocked ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Emoji Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? CupertinoColors.systemYellow.withOpacity(0.3)
                  : CupertinoColors.systemGrey5,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                achievement.emoji,
                style: TextStyle(
                  fontSize: 32,
                  color: achievement.isUnlocked ? null : Colors.black38,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Achievement Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: achievement.isUnlocked
                              ? CupertinoColors.black
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: achievement.isUnlocked
                            ? CupertinoColors.systemYellow.withOpacity(0.3)
                            : CupertinoColors.systemGrey5,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${achievement.points} pts',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: achievement.isUnlocked
                              ? CupertinoColors.systemOrange
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: achievement.isUnlocked
                        ? CupertinoColors.black.withOpacity(0.7)
                        : CupertinoColors.systemGrey,
                  ),
                ),
                if (!achievement.isUnlocked && showProgress) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:
                          achievement.currentProgress / achievement.targetValue,
                      backgroundColor: CupertinoColors.systemGrey4,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        CupertinoColors.activeBlue,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${achievement.currentProgress}/${achievement.targetValue}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
                if (achievement.isUnlocked &&
                    achievement.unlockedDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Unlocked ${_formatDate(achievement.unlockedDate!)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }
}

// Level Display Widget
class LevelDisplay extends StatelessWidget {
  final int level;
  final int totalPoints;
  final double progress;

  const LevelDisplay({
    super.key,
    required this.level,
    required this.totalPoints,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [CupertinoColors.systemIndigo, CupertinoColors.systemPurple],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Level',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.white,
                    ),
                  ),
                  Text(
                    '$level',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total Points',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.white,
                    ),
                  ),
                  Text(
                    '$totalPoints',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: CupertinoColors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                CupertinoColors.white,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% to Level ${level + 1}',
            style: const TextStyle(fontSize: 12, color: CupertinoColors.white),
          ),
        ],
      ),
    );
  }
}
