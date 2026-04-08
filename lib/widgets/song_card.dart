// ============================================
// song_card.dart - Song Display Widget
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/complete_songs_library.dart';
import '../services/theme_service.dart';

class SongCard extends StatelessWidget {
  final CompleteSong song;
  final double progress;
  final VoidCallback onTap;

  const SongCard({
    super.key,
    required this.song,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService.theme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: theme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon based on genre (using composer as fallback)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getComposerIcon(song.composer),
                    color: theme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.composer,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textColor.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: theme.textColor.withOpacity(0.5),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTag(
                    song.difficulty, _getDifficultyColor(song.difficulty)),
                const SizedBox(width: 8),
                _buildTag(song.key, theme.primaryColor.withOpacity(0.7)),
                const SizedBox(width: 8),
                _buildTag(
                  '${song.bpm} BPM',
                  theme.textColor.withOpacity(0.5),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (song.description.isNotEmpty) ...[
              Text(
                song.description,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textColor.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
            if (song.techniques.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: song.techniques
                    .take(3)
                    .map(
                      (technique) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          technique,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
            if (progress > 0) ...[
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textColor.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: theme.textColor.withOpacity(0.1),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(theme.primaryColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  IconData _getComposerIcon(String composer) {
    final lowerComposer = composer.toLowerCase();

    if (lowerComposer.contains('beethoven')) {
      return CupertinoIcons.music_note_2;
    } else if (lowerComposer.contains('traditional')) {
      return CupertinoIcons.leaf_arrow_circlepath;
    } else if (lowerComposer.contains('mozart') ||
        lowerComposer.contains('bach')) {
      return CupertinoIcons.music_albums;
    } else if (lowerComposer.contains('chopin') ||
        lowerComposer.contains('debussy')) {
      return CupertinoIcons.placemark_fill;
    } else {
      return CupertinoIcons.music_note;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return CupertinoColors.systemGreen;
      case 'intermediate':
        return CupertinoColors.systemOrange;
      case 'advanced':
        return CupertinoColors.systemRed;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}
