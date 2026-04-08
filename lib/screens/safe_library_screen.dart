import 'package:flutter/cupertino.dart';
import '../models/complete_songs_library.dart';
import '../models/song.dart';
import '../services/app_settings_store.dart';
import '../services/song_catalog_service.dart';
import '../services/song_search_service.dart';
import '../ui/ui_controller.dart';
import '../ui/ui_presets.dart';
import '../ui/ui_switcher.dart';
import '../utils/app_theme.dart';
import '../widgets/motion_fx.dart';
import 'complete_song_lesson_screen.dart';
import 'lesson_screen.dart';

class SafeLibraryScreen extends StatefulWidget {
  const SafeLibraryScreen({super.key});

  @override
  State<SafeLibraryScreen> createState() => _SafeLibraryScreenState();
}

class _SafeLibraryScreenState extends State<SafeLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';
  String _selectedGenre = 'All';
  String _sortBy = 'relevance';
  String _difficultyFilter = 'All';
  String _timeSignatureFilter = 'All';
  String _keySignatureFilter = 'All';
  String _collection = 'All';
  bool _favoritesOnly = false;
  bool _showSearchJump = false;
  Set<String> _favoriteSongIds = <String>{};
  List<String> _recentSearches = const [];
  late Future<List<CompleteSong>> _fullSongsFuture;

  @override
  void initState() {
    super.initState();
    _fullSongsFuture = SongCatalogService.loadCatalog();
    _scrollController.addListener(_handleScroll);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final favorites = await AppSettingsStore.getFavoriteSongIds();
    final recent = await AppSettingsStore.getRecentSongSearches();
    final sortBy = await AppSettingsStore.getLibrarySort();
    final difficulty = await AppSettingsStore.getLibraryDifficulty();
    final timeSignature = await AppSettingsStore.getLibraryTimeSignature();
    final keySignature = await AppSettingsStore.getLibraryKeySignature();
    final favoritesOnly = await AppSettingsStore.getLibraryFavoritesOnly();
    if (!mounted) return;
    setState(() {
      _favoriteSongIds = favorites;
      _recentSearches = recent;
      _sortBy = sortBy;
      _difficultyFilter = difficulty;
      _timeSignatureFilter = timeSignature;
      _keySignatureFilter = keySignature;
      _favoritesOnly = favoritesOnly;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final show = _scrollController.hasClients && _scrollController.offset > 220;
    if (show != _showSearchJump && mounted) {
      setState(() => _showSearchJump = show);
    }
  }

  Future<void> _jumpToSearch() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted) return;
    FocusScope.of(context).requestFocus(_searchFocusNode);
  }

  Future<void> _submitSearch(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    await AppSettingsStore.addRecentSongSearch(normalized);
    final recent = await AppSettingsStore.getRecentSongSearches();
    if (!mounted) return;
    setState(() => _recentSearches = recent);
  }

  Future<void> _toggleFavorite(String songId) async {
    final next = {..._favoriteSongIds};
    if (!next.add(songId)) {
      next.remove(songId);
    }
    await AppSettingsStore.setFavoriteSongIds(next);
    if (!mounted) return;
    setState(() => _favoriteSongIds = next);
  }

  bool _matchesAdvanced<T>(SongSearchResult<T> result, String songId) {
    if (!SongSearchService.matches(
      query: _query,
      selectedGenre: _selectedGenre,
      searchText: result.searchText,
      genre: result.genre,
    )) {
      return false;
    }
    if (_favoritesOnly && !_favoriteSongIds.contains(songId)) {
      return false;
    }
    final song = result.song as dynamic;
    if (_difficultyFilter != 'All' && song.difficulty != _difficultyFilter) {
      return false;
    }
    if (_timeSignatureFilter != 'All' &&
        song.timeSignature != _timeSignatureFilter) {
      return false;
    }
    final keySignature =
        (song.keySignature as String?) ?? (song.key as String?) ?? '';
    if (_keySignatureFilter != 'All' && keySignature != _keySignatureFilter) {
      return false;
    }
    return true;
  }

  Future<void> _showFilterSheet(
    AppTheme theme,
    List<String> difficultyOptions,
    List<String> timeSignatureOptions,
    List<String> keySignatureOptions,
  ) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return CupertinoPopupSurface(
          isSurfacePainted: false,
          child: SafeArea(
            top: false,
            child: Container(
              color: theme.surfaceColor,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  Future<void> persist(Future<void> Function() action) async {
                    await action();
                    if (!mounted) return;
                    setState(() {});
                    setModalState(() {});
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Filters',
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Done',
                                style: TextStyle(color: theme.primaryColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _modalSection(
                          theme,
                          'Genre',
                          SongSearchService.genreOrder,
                          _selectedGenre,
                          (value) => setModalState(() => _selectedGenre = value),
                        ),
                        _modalSection(
                          theme,
                          'Sort',
                          SongSearchService.sortOrder,
                          _sortBy,
                          (value) => persist(() async {
                            await AppSettingsStore.setLibrarySort(value);
                            _sortBy = value;
                          }),
                          pretty: true,
                        ),
                        _modalSection(
                          theme,
                          'Difficulty',
                          difficultyOptions,
                          _difficultyFilter,
                          (value) => persist(() async {
                            await AppSettingsStore.setLibraryDifficulty(value);
                            _difficultyFilter = value;
                          }),
                        ),
                        _modalSection(
                          theme,
                          'Time Signature',
                          timeSignatureOptions,
                          _timeSignatureFilter,
                          (value) => persist(() async {
                            await AppSettingsStore.setLibraryTimeSignature(value);
                            _timeSignatureFilter = value;
                          }),
                        ),
                        _modalSection(
                          theme,
                          'Key Signature',
                          keySignatureOptions,
                          _keySignatureFilter,
                          (value) => persist(() async {
                            await AppSettingsStore.setLibraryKeySignature(value);
                            _keySignatureFilter = value;
                          }),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Favorites only',
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            CupertinoSwitch(
                              value: _favoritesOnly,
                              activeColor: theme.primaryColor,
                              onChanged: (value) => persist(() async {
                                await AppSettingsStore.setLibraryFavoritesOnly(
                                  value,
                                );
                                _favoritesOnly = value;
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => persist(() async {
                            await AppSettingsStore.setLibrarySort('relevance');
                            await AppSettingsStore.setLibraryDifficulty('All');
                            await AppSettingsStore.setLibraryTimeSignature('All');
                            await AppSettingsStore.setLibraryKeySignature('All');
                            await AppSettingsStore.setLibraryFavoritesOnly(false);
                            _selectedGenre = 'All';
                            _sortBy = 'relevance';
                            _difficultyFilter = 'All';
                            _timeSignatureFilter = 'All';
                            _keySignatureFilter = 'All';
                            _favoritesOnly = false;
                          }),
                          child: Text(
                            'Reset filters',
                            style: TextStyle(color: theme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UiController.config,
      builder: (context, config, _) {
        final style = UiPresets.styles[config.styleIndex];
        final layout = UiPresets.layouts[config.layoutIndex];
        final theme = AppTheme.fromStyle(
          background: style.background,
          surface: style.surface,
          primary: style.primary,
          secondary: style.secondary,
          text: style.text,
          accent: style.accent,
          brightness: style.brightness,
        );
        final quickSource =
            SongLibrary.songs.map(SongSearchService.quickResult).toList();

        return FutureBuilder<List<CompleteSong>>(
          future: _fullSongsFuture,
          builder: (context, snapshot) {
            final fullSource = (snapshot.data ?? SongsLibrary.getSongs())
                .map(SongSearchService.fullResult)
                .toList();
            final allItems = [...quickSource, ...fullSource];
            final difficultyOptions =
                SongSearchService.difficultyOptions(allItems);
            final timeSignatureOptions =
                SongSearchService.timeSignatureOptions(allItems);
            final keySignatureOptions =
                SongSearchService.keySignatureOptions(allItems);
            final suggestions = SongSearchService.suggestions(
              query: _query,
              items: allItems,
            );
            final quickFiltered = SongSearchService.sortResults(
              quickSource
                  .where((song) => _matchesAdvanced(song, song.song.id))
                  .toList(),
              sortBy: _sortBy,
              favoriteIds: _favoriteSongIds,
              idOf: (song) => song.id,
            );
            final fullFiltered = SongSearchService.sortResults(
              fullSource
                  .where((song) => _matchesAdvanced(song, song.song.id))
                  .toList(),
              sortBy: _sortBy,
              favoriteIds: _favoriteSongIds,
              idOf: (song) => song.id,
            );
            final discover = _query.isEmpty ? _recentSearches : suggestions;
            final activeFilters = _activeFilterLabels();

            return CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                backgroundColor: theme.surfaceColor,
                middle: Text(
                  'Song Library',
                  style: TextStyle(color: theme.textColor),
                ),
                trailing: const UiSwitcher(),
              ),
              child: MotionBackdrop(
                backgroundColor: theme.backgroundColor,
                surfaceColor: theme.surfaceColor,
                accentColor: theme.primaryColor,
                child: SafeArea(
                  child: Stack(
                    children: [
                      ListView(
                        controller: _scrollController,
                        padding: layout.contentPadding,
                        children: [
                      MotionReveal(
                        delay: const Duration(milliseconds: 30),
                        child: _heroPanel(
                          theme,
                          layout,
                          quickCount: quickFiltered.length,
                          fullCount: fullFiltered.length,
                          discover: discover,
                          activeFilters: activeFilters,
                          difficultyOptions: difficultyOptions,
                          timeSignatureOptions: timeSignatureOptions,
                          keySignatureOptions: keySignatureOptions,
                        ),
                      ),
                      SizedBox(height: layout.panelSpacing),
                      _collectionPicker(theme),
                      SizedBox(height: layout.panelSpacing),
                      if (_collection != 'Full')
                        _section(
                          theme,
                          'Quick Lessons',
                          'Short focused studies and exercises',
                          '${quickFiltered.length}',
                        ),
                      if (_collection != 'Full')
                        ..._buildQuickResults(
                          context,
                          theme,
                          layout,
                          quickFiltered,
                        ),
                      if (_collection == 'All')
                        SizedBox(height: layout.panelSpacing),
                      if (_collection != 'Quick')
                        _section(
                          theme,
                          'Full Songs',
                          'Long-form songs with fuller arrangements',
                          '${fullFiltered.length}',
                        ),
                      if (_collection != 'Quick')
                        ..._buildFullResults(
                          context,
                          theme,
                          layout,
                          fullFiltered,
                        ),
                        ],
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 180),
                          offset: _showSearchJump
                              ? Offset.zero
                              : const Offset(0, 1.4),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: _showSearchJump ? 1 : 0,
                            child: GestureDetector(
                              onTap: _jumpToSearch,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.94),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          theme.primaryColor.withOpacity(0.24),
                                      blurRadius: 20,
                                      spreadRadius: -8,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.search,
                                      color: theme.backgroundColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Search',
                                      style: TextStyle(
                                        color: theme.backgroundColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _heroPanel(
    AppTheme theme,
    UiLayoutPreset layout, {
    required int quickCount,
    required int fullCount,
    required List<String> discover,
    required List<String> activeFilters,
    required List<String> difficultyOptions,
    required List<String> timeSignatureOptions,
    required List<String> keySignatureOptions,
  }) {
    final discoverLabel = _query.isEmpty ? 'Recent' : 'Suggestions';
    return MotionCard(
      color: theme.surfaceColor.withOpacity(0.78),
      borderColor: theme.textColor.withOpacity(0.08),
      radius: layout.cardRadius,
      glowColor: theme.primaryColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose something worth playing.',
            style: TextStyle(
              color: theme.textColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A quieter library view with a cleaner search flow and clearer song cards.',
            style: TextStyle(
              color: theme.textColor.withOpacity(0.72),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          CupertinoSearchTextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (value) => setState(() => _query = value.toLowerCase()),
            onSubmitted: _submitSearch,
            placeholder: 'Search songs, composers, keys, techniques',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statPill(theme, '$quickCount quick'),
              _statPill(theme, '$fullCount full'),
              _statPill(theme, '${quickCount + fullCount} visible'),
              _actionPill(
                theme,
                label: activeFilters.isEmpty
                    ? 'Filters'
                    : 'Filters ${activeFilters.length}',
                icon: CupertinoIcons.slider_horizontal_3,
                onTap: () => _showFilterSheet(
                  theme,
                  difficultyOptions,
                  timeSignatureOptions,
                  keySignatureOptions,
                ),
              ),
              _actionPill(
                theme,
                label: _favoritesOnly ? 'Favorites on' : 'Favorites off',
                icon: _favoritesOnly
                    ? CupertinoIcons.star_fill
                    : CupertinoIcons.star,
                onTap: () async {
                  final next = !_favoritesOnly;
                  await AppSettingsStore.setLibraryFavoritesOnly(next);
                  if (!mounted) return;
                  setState(() => _favoritesOnly = next);
                },
              ),
            ],
          ),
          if (activeFilters.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  activeFilters.map((label) => _filterTag(theme, label)).toList(),
            ),
          ],
          if (discover.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              discoverLabel,
              style: TextStyle(
                color: theme.textColor.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: discover.take(8).map((item) {
                return GestureDetector(
                  onTap: () async {
                    _searchController.text = item;
                    setState(() => _query = item.toLowerCase());
                    await _submitSearch(item);
                  },
                  child: _filterTag(theme, item),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _collectionPicker(AppTheme theme) {
    return CupertinoSlidingSegmentedControl<String>(
      groupValue: _collection,
      thumbColor: theme.primaryColor.withOpacity(0.9),
      backgroundColor: theme.surfaceColor.withOpacity(0.72),
      children: {
        'All': _segmentLabel(theme, 'All'),
        'Quick': _segmentLabel(theme, 'Quick'),
        'Full': _segmentLabel(theme, 'Full'),
      },
      onValueChanged: (value) {
        if (value == null) return;
        setState(() => _collection = value);
      },
    );
  }

  Widget _segmentLabel(AppTheme theme, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        label,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _section(
    AppTheme theme,
    String label,
    String caption,
    String meta,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: TextStyle(
                    color: theme.textColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            meta,
            style: TextStyle(
              color: theme.textColor.withOpacity(0.6),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildQuickResults(
    BuildContext context,
    AppTheme theme,
    UiLayoutPreset layout,
    List<SongSearchResult<Song>> songs,
  ) {
    if (songs.isEmpty) {
      return [_emptyState(theme, 'No quick lessons match these filters.')];
    }
    return songs.asMap().entries.map((entry) {
      return MotionReveal(
        delay: Duration(milliseconds: 40 + (entry.key * 18)),
        child: _songCard(context, theme, layout, entry.value),
      );
    }).toList();
  }

  List<Widget> _buildFullResults(
    BuildContext context,
    AppTheme theme,
    UiLayoutPreset layout,
    List<SongSearchResult<CompleteSong>> songs,
  ) {
    if (songs.isEmpty) {
      return [_emptyState(theme, 'No full songs match these filters.')];
    }
    return songs.asMap().entries.map((entry) {
      return MotionReveal(
        delay: Duration(milliseconds: 40 + (entry.key * 18)),
        child: _completeSongCard(context, theme, layout, entry.value),
      );
    }).toList();
  }

  Widget _emptyState(AppTheme theme, String label) {
    return MotionCard(
      color: theme.surfaceColor.withOpacity(0.52),
      borderColor: theme.textColor.withOpacity(0.08),
      radius: 18,
      padding: const EdgeInsets.all(18),
      child: Text(
        label,
        style: TextStyle(
          color: theme.textColor.withOpacity(0.7),
          fontSize: 13,
        ),
      ),
    );
  }

  List<String> _activeFilterLabels() {
    final labels = <String>[];
    if (_selectedGenre != 'All') labels.add(_selectedGenre);
    if (_difficultyFilter != 'All') labels.add(_difficultyFilter);
    if (_timeSignatureFilter != 'All') labels.add(_timeSignatureFilter);
    if (_keySignatureFilter != 'All') labels.add(_keySignatureFilter);
    if (_sortBy != 'relevance') labels.add('Sort ${_sortBy.toUpperCase()}');
    if (_favoritesOnly) labels.add('Favorites');
    return labels;
  }

  Widget _statPill(AppTheme theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withOpacity(0.36),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.textColor.withOpacity(0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.textColor.withOpacity(0.78),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _actionPill(
    AppTheme theme, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.primaryColor.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterTag(AppTheme theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withOpacity(0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.textColor.withOpacity(0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.textColor.withOpacity(0.8),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _modalSection(
    AppTheme theme,
    String title,
    List<String> options,
    String selected,
    ValueChanged<String> onSelected, {
    bool pretty = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textColor.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final active = option == selected;
              final label = pretty
                  ? option[0].toUpperCase() + option.substring(1)
                  : option;
              return GestureDetector(
                onTap: () => onSelected(option),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: active
                        ? theme.primaryColor.withOpacity(0.18)
                        : theme.backgroundColor.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active
                          ? theme.primaryColor.withOpacity(0.42)
                          : theme.textColor.withOpacity(0.08),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _songCard(
    BuildContext context,
    AppTheme theme,
    UiLayoutPreset layout,
    SongSearchResult<Song> result,
  ) {
    final song = result.song;
    final favorite = _favoriteSongIds.contains(song.id);
    return MotionCard(
      margin: EdgeInsets.only(bottom: layout.panelSpacing),
      color: theme.surfaceColor.withOpacity(0.74),
      borderColor: theme.textColor.withOpacity(0.08),
      radius: layout.cardRadius,
      glowColor: theme.primaryColor,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.music_note_2,
                  color: theme.primaryColor,
                  size: 20,
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
                        color: theme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.composer,
                      style: TextStyle(
                        color: theme.textColor.withOpacity(0.62),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 34,
                onPressed: () => _toggleFavorite(song.id),
                child: Icon(
                  favorite ? CupertinoIcons.star_fill : CupertinoIcons.star,
                  color: favorite
                      ? CupertinoColors.systemYellow
                      : theme.textColor.withOpacity(0.48),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metaChip(theme, result.genre),
              _metaChip(theme, song.difficulty),
              _metaChip(theme, song.keySignature),
              _metaChip(theme, song.timeSignature),
              _metaChip(theme, '${song.bpm} BPM'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                song.lessonType == LessonType.chord
                    ? 'Chord lesson'
                    : 'Quick lesson',
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              CupertinoButton.filled(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                borderRadius: BorderRadius.circular(999),
                onPressed: () async {
                  await _submitSearch(song.title);
                  if (!mounted) return;
                  Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => LessonScreen(song: song)),
                  );
                },
                child: const Text('Start'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _completeSongCard(
    BuildContext context,
    AppTheme theme,
    UiLayoutPreset layout,
    SongSearchResult<CompleteSong> result,
  ) {
    final song = result.song;
    final favorite = _favoriteSongIds.contains(song.id);
    return MotionCard(
      margin: EdgeInsets.only(bottom: layout.panelSpacing),
      color: theme.surfaceColor.withOpacity(0.74),
      borderColor: theme.textColor.withOpacity(0.08),
      radius: layout.cardRadius,
      glowColor: theme.primaryColor,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.music_note_list,
                  color: theme.primaryColor,
                  size: 20,
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
                        color: theme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.composer,
                      style: TextStyle(
                        color: theme.textColor.withOpacity(0.62),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 34,
                onPressed: () => _toggleFavorite(song.id),
                child: Icon(
                  favorite ? CupertinoIcons.star_fill : CupertinoIcons.star,
                  color: favorite
                      ? CupertinoColors.systemYellow
                      : theme.textColor.withOpacity(0.48),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metaChip(theme, result.genre),
              _metaChip(theme, song.difficulty),
              _metaChip(theme, song.keySignature),
              _metaChip(theme, song.timeSignature),
              _metaChip(theme, '${song.bpm} BPM'),
            ],
          ),
          if (song.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              song.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor.withOpacity(0.62),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Full arrangement',
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              CupertinoButton.filled(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                borderRadius: BorderRadius.circular(999),
                onPressed: () async {
                  await _submitSearch(song.title);
                  if (!mounted) return;
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => CompleteSongLessonScreen(song: song),
                    ),
                  );
                },
                child: const Text('Start'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaChip(AppTheme theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.textColor.withOpacity(0.84),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
