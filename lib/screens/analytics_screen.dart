import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/complete_songs_library.dart';
import '../services/enhanced_ai_tutor_service.dart';
import '../services/audio_player_service.dart';
import '../services/aws_service.dart';
import '../widgets/falling_notes_widget.dart';
import '../widgets/ai_chat_widget.dart';

// ============================================
// analytics_screen.dart - Practice Analytics
// ============================================

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AwsService _cloudService = AwsService.instance;
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final analytics =
          await _cloudService.getUserAnalytics(days: _selectedDays);
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading analytics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Analytics'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showPeriodPicker,
          child: const Icon(CupertinoIcons.calendar),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOverviewCards(),
                  const SizedBox(height: 16),
                  _buildChartPlaceholder(),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final sessions = _analytics['total_sessions'] ?? 0;
    final minutes = _analytics['total_minutes'] ?? 0;
    final notes = _analytics['total_notes'] ?? 0;
    final accuracy = _analytics['average_accuracy'] ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                CupertinoIcons.music_note,
                '$notes',
                'Notes Played',
                CupertinoColors.systemPurple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                CupertinoIcons.time,
                '$minutes min',
                'Practice Time',
                CupertinoColors.systemBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                CupertinoIcons.chart_bar,
                '$sessions',
                'Sessions',
                CupertinoColors.systemOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                CupertinoIcons.star_fill,
                '${accuracy.toStringAsFixed(1)}%',
                'Accuracy',
                CupertinoColors.systemGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Practice Chart\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(color: CupertinoColors.systemGrey),
        ),
      ),
    );
  }

  void _showPeriodPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Period'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedDays = 7);
              Navigator.pop(context);
              _loadAnalytics();
            },
            child: const Text('Last 7 Days'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedDays = 30);
              Navigator.pop(context);
              _loadAnalytics();
            },
            child: const Text('Last 30 Days'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedDays = 90);
              Navigator.pop(context);
              _loadAnalytics();
            },
            child: const Text('Last 3 Months'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedDays = 365);
              Navigator.pop(context);
              _loadAnalytics();
            },
            child: const Text('Last Year'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
