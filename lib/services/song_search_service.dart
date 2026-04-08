import '../models/complete_songs_library.dart';
import '../models/song.dart';

class SongSearchResult<T> {
  final T song;
  final String genre;
  final List<String> tokens;
  final String searchText;

  const SongSearchResult({
    required this.song,
    required this.genre,
    required this.tokens,
    required this.searchText,
  });
}

class SongSearchService {
  static const List<String> sortOrder = [
    'relevance',
    'title',
    'composer',
    'bpm',
    'difficulty',
  ];

  static const List<String> genreOrder = [
    'All',
    'Masterpieces',
    'Nursery Rhymes',
    'Classical',
    'Baroque',
    'Romantic',
    'Traditional',
    'Children',
    'Seasonal',
    'Ragtime',
    'Etude',
    'Opera & Ballet',
    'Sacred',
    'Folk',
    'Jazz',
    'Pop',
    'Soul',
    'R&B',
    'Movie Soundtracks',
    'Other',
  ];

  static SongSearchResult<Song> quickResult(Song song) {
    final genre = inferQuickGenre(song);
    final tokens = _buildTokens(
      title: song.title,
      composer: song.composer,
      keySignature: song.keySignature,
      difficulty: 'Quick Lesson',
      genre: genre,
      description: '',
      techniques: const [],
    );
    return SongSearchResult<Song>(
      song: song,
      genre: genre,
      tokens: tokens,
      searchText: tokens.join(' '),
    );
  }

  static SongSearchResult<CompleteSong> fullResult(CompleteSong song) {
    final genre = inferFullGenre(song);
    final tokens = _buildTokens(
      title: song.title,
      composer: song.composer,
      keySignature: song.keySignature,
      difficulty: song.difficulty,
      genre: genre,
      description: song.description,
      techniques: song.techniques,
    );
    return SongSearchResult<CompleteSong>(
      song: song,
      genre: genre,
      tokens: tokens,
      searchText: tokens.join(' '),
    );
  }

  static String inferQuickGenre(Song song) {
    final hay = _normalize('${song.title} ${song.composer}');
    if (_containsAny(hay, const [
      'twinkle',
      'mary had',
      'old macdonald',
      'row row row',
      'london bridge',
      'frere jacques',
    ])) {
      return 'Nursery Rhymes';
    }
    if (_containsAny(hay, const ['christmas', 'jingle', 'silent night'])) {
      return 'Seasonal';
    }
    if (_containsAny(hay, const ['folk', 'traditional'])) {
      return 'Traditional';
    }
    return 'Traditional';
  }

  static String inferFullGenre(CompleteSong song) {
    final composer = _normalize(song.composer);
    final title = _normalize(song.title);
    final description = _normalize(song.description);
    final techniques = _normalize(song.techniques.join(' '));
    final hay = '$composer $title $description $techniques';

    if (_isMasterpiece(song)) return 'Masterpieces';
    if (_containsAny(hay, const ['nursery', 'rhyme', 'children']) ||
        _containsAny(title, const [
          'twinkle',
          'mary had',
          'old macdonald',
          'row row row',
          'london bridge',
          'frere jacques',
          'baa baa',
        ])) {
      return 'Nursery Rhymes';
    }
    if (_containsAny(hay, const ['rag', 'ragtime']) ||
        composer.contains('joplin')) {
      return 'Ragtime';
    }
    if (_containsAny(hay, const ['etude', 'study']) ||
        composer.contains('czerny')) {
      return 'Etude';
    }
    if (_containsAny(hay, const ['christmas', 'carol', 'noel'])) {
      return 'Seasonal';
    }
    if (_containsAny(hay, const ['oratorio', 'cantata', 'mass', 'requiem', 'chorale'])) {
      return 'Sacred';
    }
    if (_containsAny(hay, const ['opera', 'ballet', 'waltz', 'don giovanni'])) {
      return 'Opera & Ballet';
    }
    if (_containsAny(hay, const ['folk', 'traditional'])) {
      return 'Folk';
    }
    if (_containsAny(hay, const ['jazz', 'blues', 'swing'])) {
      return 'Jazz';
    }
    if (_containsAny(hay, const ['spiritual', 'gospel'])) {
      return 'Soul';
    }
    if (_containsAny(hay, const ['ballad', 'popular song', 'songbook'])) {
      return 'Pop';
    }
    if (composer.contains('bach') ||
        composer.contains('handel') ||
        composer.contains('scarlatti')) {
      return 'Baroque';
    }
    if (composer.contains('chopin') ||
        composer.contains('schumann') ||
        composer.contains('schubert') ||
        composer.contains('liszt') ||
        composer.contains('grieg')) {
      return 'Romantic';
    }
    if (_isClassicalComposer(composer)) return 'Classical';
    return 'Other';
  }

  static bool matches({
    required String query,
    required String selectedGenre,
    required String searchText,
    required String genre,
  }) {
    final normalizedQuery = _normalize(query);
    final normalizedSearch = _normalize(searchText);
    final tokens = normalizedSearch
        .split(' ')
        .where((term) => term.isNotEmpty)
        .toSet()
        .toList();

    final genreOk = selectedGenre == 'All' || genre == selectedGenre;
    if (!genreOk) return false;
    if (normalizedQuery.isEmpty) return true;

    final terms = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
    return terms.every((term) => _termMatches(term, normalizedSearch, tokens));
  }

  static List<String> suggestions({
    required String query,
    required Iterable<SongSearchResult<dynamic>> items,
    int limit = 8,
  }) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return const [];

    final ranked = <String, int>{};
    for (final item in items) {
      for (final token in item.tokens) {
        final normalizedToken = _normalize(token);
        if (normalizedToken.isEmpty) continue;
        final score = _scoreSuggestion(normalized, normalizedToken);
        if (score > 0) {
          ranked[token] = (ranked[token] ?? 0) + score;
        }
      }
    }

    final suggestions = ranked.entries.toList()
      ..sort((a, b) {
        final score = b.value.compareTo(a.value);
        if (score != 0) return score;
        return a.key.length.compareTo(b.key.length);
      });

    return suggestions
        .map((entry) => entry.key)
        .where((token) => token.trim().length > 1)
        .take(limit)
        .toList();
  }

  static List<String> difficultyOptions(
    Iterable<SongSearchResult<dynamic>> items,
  ) {
    final values = items
        .map((item) => _difficultyOf(item.song))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => _difficultyRank(a).compareTo(_difficultyRank(b)));
    return ['All', ...values];
  }

  static List<String> timeSignatureOptions(
    Iterable<SongSearchResult<dynamic>> items,
  ) {
    final values = items
        .map((item) => _timeSignatureOf(item.song))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...values];
  }

  static List<String> keySignatureOptions(
    Iterable<SongSearchResult<dynamic>> items,
  ) {
    final values = items
        .map((item) => _keySignatureOf(item.song))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...values];
  }

  static List<SongSearchResult<T>> sortResults<T>(
    List<SongSearchResult<T>> input, {
    required String sortBy,
    required Set<String> favoriteIds,
    required String Function(T song) idOf,
  }) {
    final items = [...input];
    items.sort((a, b) {
      if (sortBy == 'relevance') {
        final favCompare = (favoriteIds.contains(idOf(b.song)) ? 1 : 0)
            .compareTo(favoriteIds.contains(idOf(a.song)) ? 1 : 0);
        if (favCompare != 0) return favCompare;
      }

      int result;
      switch (sortBy) {
        case 'title':
          result = _titleOf(a.song).compareTo(_titleOf(b.song));
          break;
        case 'composer':
          result = _composerOf(a.song).compareTo(_composerOf(b.song));
          break;
        case 'bpm':
          result = _bpmOf(a.song).compareTo(_bpmOf(b.song));
          break;
        case 'difficulty':
          result = _difficultyRank(_difficultyOf(a.song))
              .compareTo(_difficultyRank(_difficultyOf(b.song)));
          break;
        default:
          result = _titleOf(a.song).compareTo(_titleOf(b.song));
          break;
      }
      if (result != 0) return result;
      return _titleOf(a.song).compareTo(_titleOf(b.song));
    });
    return items;
  }

  static List<String> _buildTokens({
    required String title,
    required String composer,
    required String keySignature,
    required String difficulty,
    required String genre,
    required String description,
    required List<String> techniques,
  }) {
    final labels = _inferLabels(
      title: title,
      composer: composer,
      genre: genre,
      description: description,
      techniques: techniques,
    );

    final raw = <String>{
      title,
      composer,
      keySignature,
      difficulty,
      genre,
      ...labels,
      ...techniques,
      ...description.split(RegExp(r'[^A-Za-z0-9#&]+')),
      ...title.split(RegExp(r'[^A-Za-z0-9#&]+')),
      ...composer.split(RegExp(r'[^A-Za-z0-9#&]+')),
    };

    final normalized = <String>{};
    for (final value in raw) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      normalized.add(trimmed.toLowerCase());
      normalized.add(_normalize(trimmed));
    }
    return normalized.where((value) => value.isNotEmpty).toList();
  }

  static List<String> _inferLabels({
    required String title,
    required String composer,
    required String genre,
    required String description,
    required List<String> techniques,
  }) {
    final hay = _normalize('$title $composer $genre $description ${techniques.join(' ')}');
    final labels = <String>{genre};

    if (_isMasterpieceTitle(title, composer)) {
      labels.addAll(['masterpiece', 'iconic masterpiece']);
    }
    if (_containsAny(hay, const ['nursery', 'rhyme', 'twinkle', 'mary had'])) {
      labels.addAll(['nursery rhyme', 'children']);
    }
    if (_containsAny(hay, const ['movie', 'soundtrack', 'film'])) {
      labels.addAll(['movie soundtrack', 'film music']);
    }
    if (_containsAny(hay, const ['spiritual', 'gospel'])) {
      labels.addAll(['soul', 'r&b']);
    }
    if (_containsAny(hay, const ['popular', 'ballad'])) {
      labels.add('pop');
    }
    return labels.toList();
  }

  static bool _termMatches(
    String term,
    String searchText,
    List<String> tokens,
  ) {
    if (searchText.contains(term)) return true;
    for (final token in tokens) {
      if (token.startsWith(term) || token.contains(term)) {
        return true;
      }
      final distance = _levenshtein(term, token);
      final maxDistance = term.length >= 7 ? 2 : 1;
      if (distance <= maxDistance) {
        return true;
      }
    }
    return false;
  }

  static int _scoreSuggestion(String query, String token) {
    if (token == query) return 8;
    if (token.startsWith(query)) return 6;
    if (token.contains(query)) return 3;
    final distance = _levenshtein(query, token);
    final maxDistance = query.length >= 7 ? 2 : 1;
    return distance <= maxDistance ? 2 : 0;
  }

  static bool _isMasterpiece(CompleteSong song) {
    return _isMasterpieceTitle(song.title, song.composer) ||
        song.techniques.any((technique) => _normalize(technique).contains('masterpiece'));
  }

  static bool _isMasterpieceTitle(String title, String composer) {
    final hay = _normalize('$title $composer');
    return _containsAny(hay, const [
      'fur elise',
      'moonlight sonata',
      'clair de lune',
      'eine kleine',
      'symphony no 40',
      'requiem',
      'well tempered clavier',
      'prelude in c major',
      'fantasy in d minor',
      'ode to joy',
      'air on the g string',
      'canon in d',
    ]);
  }

  static bool _containsAny(String hay, List<String> needles) {
    for (final needle in needles) {
      if (hay.contains(_normalize(needle))) return true;
    }
    return false;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9#\s]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    if ((a.length - b.length).abs() > 2) return 99;

    final costs = List<int>.generate(b.length + 1, (index) => index);
    for (var i = 1; i <= a.length; i++) {
      var previous = costs[0];
      costs[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final current = costs[j];
        final substitution = previous + (a[i - 1] == b[j - 1] ? 0 : 1);
        final insertion = costs[j] + 1;
        final deletion = costs[j - 1] + 1;
        costs[j] = [substitution, insertion, deletion].reduce(
          (left, right) => left < right ? left : right,
        );
        previous = current;
      }
    }
    return costs.last;
  }

  static bool _isClassicalComposer(String composer) {
    return const [
      'beethoven',
      'mozart',
      'haydn',
      'debussy',
      'satie',
      'clementi',
      'burgmuller',
      'albeniz',
      'granados',
      'field',
      'mussorgsky',
      'tchaikovsky',
    ].any(composer.contains);
  }

  static String _titleOf(dynamic song) => (song.title as String).toLowerCase();
  static String _composerOf(dynamic song) =>
      (song.composer as String).toLowerCase();
  static int _bpmOf(dynamic song) => song.bpm as int;
  static String _difficultyOf(dynamic song) =>
      (song.difficulty as String?) ?? 'Other';
  static String _timeSignatureOf(dynamic song) =>
      (song.timeSignature as String?) ?? '';
  static String _keySignatureOf(dynamic song) =>
      ((song.keySignature as String?) ?? (song.key as String?) ?? '');

  static int _difficultyRank(String value) {
    switch (value.toLowerCase()) {
      case 'beginner':
        return 0;
      case 'intermediate':
        return 1;
      case 'advanced':
        return 2;
      default:
        return 3;
    }
  }
}
