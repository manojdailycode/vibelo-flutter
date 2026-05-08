// music_source_manager.dart  —  CORE FILE
//
// Priority: JioSaavn (primary) → YouTube (fallback only)
// JioSaavn returns playable MP3 URLs directly — no extra resolution needed.
// YouTube songs use youtube_explode_dart to resolve the stream URL at playtime.

import '../models/song_model.dart';
import '../services/jiosaavn_service.dart';
import '../services/youtube_service.dart';

enum MusicLanguage { telugu, hindi, tamil, english, all }

class MusicSourceManager {
  MusicSourceManager._();
  static final MusicSourceManager instance = MusicSourceManager._();

  final _jiosaavn = JioSaavnService();
  final _youtube  = YouTubeService();

  bool _canFallbackToYouTube() {
    final t = _jiosaavn.lastErrorType;
    return t == JioSaavnErrorType.timeout ||
        t == JioSaavnErrorType.httpError ||
        t == JioSaavnErrorType.parseError ||
        t == JioSaavnErrorType.configMissing ||
        t == JioSaavnErrorType.unknown;
  }

  // ── UNIFIED SEARCH ────────────────────────────────────────────────────────
  // Strict priority: JioSaavn first. YouTube only if JioSaavn returns nothing.
  Future<SearchResults> searchAll(String query,
      {int limitPerType = 15}) async {
    final songs    = <SongModel>[];
    final songSeen = <String>{};

    void addUnique(List<SongModel> items) {
      songs.addAll(items.where((s) => songSeen
          .add('${s.title.toLowerCase()}_${s.artist.toLowerCase()}')));
    }

    // JioSaavn first
    addUnique(await _jiosaavn.searchSongs(query, limit: limitPerType));

    // YouTube fallback only when JioSaavn failed (not for temporary empty payloads)
    if (songs.isEmpty && _canFallbackToYouTube()) {
      addUnique(await _youtube.search(query, limit: limitPerType));
    }

    // Albums / Artists from JioSaavn only
    final albums    = <AlbumModel>[];
    final albumSeen = <String>{};
    final rawAlbums = await _jiosaavn.searchAlbums(query, limit: limitPerType);
    albums.addAll(rawAlbums.where((a) =>
        albumSeen.add('${a.title.toLowerCase()}_${a.artist?.toLowerCase()}')));

    final artists    = <ArtistModel>[];
    final artistSeen = <String>{};
    final rawArtists =
        await _jiosaavn.searchArtists(query, limit: limitPerType);
    artists.addAll(rawArtists
        .where((a) => artistSeen.add(a.name.toLowerCase())));

    return SearchResults(
      songs:    songs.take(50).toList(),
      albums:   albums.take(20).toList(),
      artists:  artists.take(20).toList(),
      playlists: const [],
    );
  }

  // ── TRENDING ──────────────────────────────────────────────────────────────
  // JioSaavn first. YouTube trending only if JioSaavn returns nothing.
  Future<List<SongModel>> getTrending({int limit = 20}) async {
    final jio =
        await _jiosaavn.searchSongs('trending songs india 2024', limit: limit);
    if (jio.isNotEmpty) return jio;
    if (!_canFallbackToYouTube()) return [];

    // Fallback: YouTube trending music (needs API key)
    final yt = await _youtube.getTrending(regionCode: 'IN', limit: limit);
    return yt;
  }

  // ── NEW RELEASES ──────────────────────────────────────────────────────────
  Future<List<SongModel>> getNewReleases({int limit = 20}) async {
    final jio =
        await _jiosaavn.searchSongs('new releases 2024', limit: limit);
    if (jio.isNotEmpty) return jio;
    if (!_canFallbackToYouTube()) return [];

    return _youtube.search('new songs 2024', limit: limit);
  }

  // ── HOME DATA ─────────────────────────────────────────────────────────────
  Future<({List<SongModel> trending, List<SongModel> newReleases})>
      loadHomeData() async {
    final results = await Future.wait([
      getTrending(limit: 20),
      getNewReleases(limit: 20),
    ]);
    return (trending: results[0], newReleases: results[1]);
  }

  // ── LANGUAGE-BASED FETCH ──────────────────────────────────────────────────
  Future<List<SongModel>> getSongsByLanguage(
    MusicLanguage language, {
    int limit = 25,
  }) async {
    switch (language) {
      case MusicLanguage.telugu:  return _getTeluguSongs(limit: limit);
      case MusicLanguage.hindi:   return _getHindiSongs(limit: limit);
      case MusicLanguage.tamil:   return _getTamilSongs(limit: limit);
      case MusicLanguage.english: return _getEnglishSongs(limit: limit);
      case MusicLanguage.all:     return _getAllLanguages(limit: limit);
    }
  }

  // ── PRIVATE helpers ───────────────────────────────────────────────────────
  Future<List<SongModel>> _getTeluguSongs({int limit = 25}) async {
    final jio = await _jiosaavn.searchSongs('telugu songs', limit: limit);
    if (jio.isNotEmpty) return _deduplicate(jio).take(limit).toList();
    if (!_canFallbackToYouTube()) return [];

    final yt = await _youtube.getTeluguSongs(limit: limit);
    return _deduplicate(yt).take(limit).toList();
  }

  Future<List<SongModel>> _getHindiSongs({int limit = 25}) async {
    final jio = await _jiosaavn.searchSongs('hindi songs', limit: limit);
    if (jio.isNotEmpty) return _deduplicate(jio).take(limit).toList();
    if (!_canFallbackToYouTube()) return [];

    final yt = await _youtube.getHindiSongs(limit: limit);
    return _deduplicate(yt).take(limit).toList();
  }

  Future<List<SongModel>> _getTamilSongs({int limit = 25}) async {
    final jio = await _jiosaavn.searchSongs('tamil songs', limit: limit);
    if (jio.isNotEmpty) return _deduplicate(jio).take(limit).toList();
    if (!_canFallbackToYouTube()) return [];

    final yt = await _youtube.getTamilSongs(limit: limit);
    return _deduplicate(yt).take(limit).toList();
  }

  Future<List<SongModel>> _getEnglishSongs({int limit = 20}) async {
    final jio = await _jiosaavn.searchSongs('english songs', limit: limit);
    if (jio.isNotEmpty) return _deduplicate(jio).take(limit).toList();
    if (!_canFallbackToYouTube()) return [];

    final yt = await _youtube.getEnglishSongs(limit: limit);
    return _deduplicate(yt).take(limit).toList();
  }

  Future<List<SongModel>> _getAllLanguages({int limit = 40}) async {
    final lists = await Future.wait([
      _getTeluguSongs(limit: 10),
      _getHindiSongs(limit: 10),
      _getTamilSongs(limit: 10),
      _getEnglishSongs(limit: 10),
    ]);
    final all = lists.expand((l) => l).toList()..shuffle();
    return all.take(limit).toList();
  }

  List<SongModel> _deduplicate(List<SongModel> songs) {
    final seen = <String>{};
    return songs.where((s) {
      final key =
          '${s.title.toLowerCase().trim()}_${s.artist.toLowerCase().trim()}';
      return seen.add(key);
    }).toList();
  }
}