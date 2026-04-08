// ============================================
// song_library_screen.dart - Browse Songs
// ============================================

import 'package:flutter/cupertino.dart';
import '../models/complete_songs_library.dart';
import '../services/theme_service.dart';
import '../services/aws_service.dart';
import '../widgets/song_card.dart';
import 'lesson_screen.dart';
import 'complete_song_lesson_screen.dart';

class SongLibraryScreen extends StatefulWidget {
  const SongLibraryScreen({super.key});

  @override
  State<SongLibraryScreen> createState() => _SongLibraryScreenState();
}

class _SongLibraryScreenState extends State<SongLibraryScreen> {
  final AwsService _cloudService = AwsService.instance;
  String _selectedDifficulty = 'All';
  String _selectedGenre = 'All';
  final Map<String, double> _songProgress = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    if (!_cloudService.isInitialized) return;

    for (var song in SongsLibrary.getSongs()) {
      final progress = await _cloudService.getSongProgress(song.id);
      setState(() => _songProgress[song.id] = progress);
    }
  }

  List<CompleteSong> get _filteredSongs {
    return SongsLibrary.getSongs().where((song) {
      final matchesDifficulty = _selectedDifficulty == 'All' ||
          song.difficulty == _selectedDifficulty;
      // Since CompleteSong doesn't have genre, we'll filter by composer or key instead
      final matchesGenre =
          _selectedGenre == 'All' || _getSongCategory(song) == _selectedGenre;
      return matchesDifficulty && matchesGenre;
    }).toList();
  }

  String _getSongCategory(CompleteSong song) {
    // Use composer to determine category since genre doesn't exist
    final composer = song.composer.toLowerCase();
    if (composer.contains('beethoven') ||
        composer.contains('traditional') ||
        composer.contains('mozart') ||
        composer.contains('bach') ||
        composer.contains('chopin')) {
      return 'Classical';
    }
    // For other composers, you might want to add more categories
    // For now, we'll use the key as fallback
    return song.key.contains('Major') ? 'Major' : 'Minor';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService.theme;

    return CupertinoPageScaffold(
      backgroundColor: theme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.surfaceColor,
        middle: Text(
          'Song Library',
          style: TextStyle(color: theme.textColor),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Filters
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: theme.cardGradient,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: theme.primaryColor.withOpacity(0.2),
                      onPressed: () => _showDifficultyPicker(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Difficulty: $_selectedDifficulty',
                            style:
                                TextStyle(color: theme.textColor, fontSize: 14),
                          ),
                          Icon(CupertinoIcons.chevron_down,
                              color: theme.textColor, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: theme.primaryColor.withOpacity(0.2),
                      onPressed: () => _showCategoryPicker(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Category: $_selectedGenre',
                            style:
                                TextStyle(color: theme.textColor, fontSize: 14),
                          ),
                          Icon(CupertinoIcons.chevron_down,
                              color: theme.textColor, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Song list
            Expanded(
              child: _filteredSongs.isEmpty
                  ? Center(
                      child: Text(
                        'No songs found',
                        style:
                            TextStyle(color: theme.textColor.withOpacity(0.5)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = _filteredSongs[index];
                        final progress = _songProgress[song.id] ?? 0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SongCard(
                            song: song,
                            progress: progress,
                            onTap: () => _openSong(song),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDifficultyPicker() {
    final difficulties = ['All', 'Beginner', 'Intermediate', 'Advanced'];

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Difficulty'),
        actions: difficulties.map((diff) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedDifficulty = diff);
              Navigator.pop(context);
            },
            child: Text(diff),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    final categories = ['All', 'Classical', 'Major', 'Minor'];

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Category'),
        actions: categories.map((category) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedGenre = category);
              Navigator.pop(context);
            },
            child: Text(category),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _openSong(CompleteSong song) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => CompleteSongLessonScreen(song: song),
      ),
    );
  }
}
