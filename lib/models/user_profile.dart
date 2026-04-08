// ============================================
// user_profile.dart - User Profile & Stats
// ============================================

import 'package:flutter/cupertino.dart';
import '../services/theme_service.dart';
import '../services/aws_service.dart';
import '../screens/settings_screen.dart';
import 'package:flutter/material.dart' as material;

class UserProfileScreen extends StatefulWidget {
  final Function() onThemeChanged;

  const UserProfileScreen({
    super.key,
    required this.onThemeChanged,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final AwsService _cloudService = AwsService.instance;
  Map<String, dynamic> _stats = {
    'totalSessions': 0,
    'totalMinutes': 0,
    'totalNotes': 0,
    'averageSessionMinutes': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    if (_cloudService.isInitialized) {
      final stats = await _cloudService.getStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService.theme;

    return CupertinoPageScaffold(
      backgroundColor: theme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.surfaceColor,
        middle: Text(
          'Profile',
          style: TextStyle(color: theme.textColor),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => SettingsScreen(
                  onThemeChanged: widget.onThemeChanged,
                ),
              ),
            );
          },
          child: Icon(CupertinoIcons.settings, color: theme.textColor),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? Center(
                child: CupertinoActivityIndicator(color: theme.primaryColor),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: theme.cardGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.person_fill,
                            size: 40,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Piano Student',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Keep practicing to improve!',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats grid
                  Text(
                    'Practice Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Sessions',
                          '${_stats['totalSessions']}',
                          CupertinoIcons.calendar,
                          theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Total Minutes',
                          '${_stats['totalMinutes']}',
                          CupertinoIcons.time,
                          theme,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Notes Played',
                          '${_stats['totalNotes']}',
                          CupertinoIcons.music_note_2,
                          theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Avg Session',
                          '${_stats['averageSessionMinutes']} min',
                          CupertinoIcons.chart_bar,
                          theme,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Achievements section
                  Text(
                    'Achievements',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: theme.cardGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildAchievement(
                          'First Steps',
                          'Complete your first practice session',
                          _stats['totalSessions'] > 0,
                          theme,
                        ),
                        const material.Divider(height: 24),
                        _buildAchievement(
                          'Dedicated',
                          'Practice for 60 minutes total',
                          _stats['totalMinutes'] >= 60,
                          theme,
                        ),
                        const material.Divider(height: 24),
                        _buildAchievement(
                          'Master',
                          'Play 1000 notes',
                          _stats['totalNotes'] >= 1000,
                          theme,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Refresh button
                  CupertinoButton.filled(
                    onPressed: _loadStats,
                    child: const Text('Refresh Stats'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: theme.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.primaryColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: theme.textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievement(
      String title, String description, bool unlocked, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: unlocked
                ? theme.primaryColor.withOpacity(0.2)
                : theme.textColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            unlocked
                ? CupertinoIcons.checkmark_seal_fill
                : CupertinoIcons.lock_fill,
            color: unlocked
                ? theme.primaryColor
                : theme.textColor.withOpacity(0.3),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: unlocked
                      ? theme.textColor
                      : theme.textColor.withOpacity(0.5),
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
