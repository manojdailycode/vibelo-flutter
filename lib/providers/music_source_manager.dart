// ─────────────────────────────────────────────────────────────────────────────
//  music_source_manager.dart  —  CORE FILE — NEVER DELETE
//
//  Manages all music sources and provides a unified search API.
//  It fetches songs, albums, and artists from multiple platforms, respecting
//  a priority order to ensure the most relevant results appear first.
//
//  Search Priority: YouTube → Spotify → Deezer → Jamendo → Audius
//  Updated Search Priority: JioSaavn → YouTube → Spotify → Deezer → Jamendo → Audius
// ─────────────────────────────────────────────────────────────────────────────

import '../models/song_model.dart';
import '../services/jiosaavn_service.dart';
import '../services/youtube_service.dart';

enum MusicLanguage { telugu, hindi, tamil, english, all }

class MusicSourceManager {
  MusicSourceManager._();
  static final MusicSourceManager instance = MusicSourceManager._();

  // Service instances in priority order for search
  final _jiosaavn = JioSaavnService();
  final _youtube = YouTubeService();

  // ── UNIFIED SEARCH — fetches all content types with priority ───────────
  Future<SearchResults> searchAll(String query, {int limitPerType = 15}) async {
    // --- Songs ---
    final songs = <SongModel>[];
    final songSeen = <String>{};
    void addUniqueSongs(List<SongModel> items) {
      songs.addAll(items.where((s) => songSeen.add('${s.title.toLowerCase()}_${s.artist.toLowerCase()}')));
    }
    addUniqueSongs(await _jiosaavn.searchSongs(query, limit: limitPerType));
    addUniqueSongs(await _youtube.search(query, limit: limitPerType));

    // --- Albums ---
    final albums = <AlbumModel>[];
    final albumSeen = <String>{};
    void addUniqueAlbums(List<AlbumModel> items) {
      albums.addAll(items.where((a) => albumSeen.add('${a.title.toLowerCase()}_${a.artist?.toLowerCase()}')));
    }
    addUniqueAlbums(await _jiosaavn.searchAlbums(query, limit: limitPerType));

    // --- Artists ---
    final artists = <ArtistModel>[];
    final artistSeen = <String>{};
    void addUniqueArtists(List<ArtistModel> items) {
      artists.addAll(items.where((a) => artistSeen.add(a.name.toLowerCase())));
    }
    addUniqueArtists(await _jiosaavn.searchArtists(query, limit: limitPerType));

    // --- Playlists ---
    final playlists = <PlaylistModel>[];
    // Playlist search logic can be added here when services support it.

    return SearchResults(
      songs: songs.take(50).toList(), // Cap total results
      albums: albums.take(20).toList(),
      artists: artists.take(20).toList(),
      playlists: playlists.take(20).toList(),
    );
  }

  // ── TRENDING ─────────────────────────────────────────────────────────────
  Future<List<SongModel>> getTrending({int limit = 20}) async {
    final yt = await _youtube.getTrending(regionCode: 'IN', limit: limit);
    if (yt.isNotEmpty) return yt;

    final jio = await _jiosaavn.searchSongs('trending songs india', limit: limit);
    return jio;
  }

  // ── LANGUAGE-BASED FETCH ─────────────────────────────────────────────────
  Future<List<SongModel>> getSongsByLanguage(
    MusicLanguage language, {
    int limit = 25,
  }) async {
    switch (language) {
      case MusicLanguage.telugu:
        return _getTeluguSongs(limit: limit);
      case MusicLanguage.hindi:
        return _getHindiSongs(limit: limit);
      case MusicLanguage.tamil:
        return _getTamilSongs(limit: limit);
      case MusicLanguage.english:
        return _getEnglishSongs(limit: limit);
      case MusicLanguage.all:
        return _getAllLanguages(limit: limit);
    }
  }

  // ── NEW RELEASES ─────────────────────────────────────────────────────────
  Future<List<SongModel>> getNewReleases({int limit = 20}) async {
    final jio = await _jiosaavn.searchSongs('new releases', limit: limit);
    if (jio.isNotEmpty) return jio;

    return _youtube.search('new songs 2025', limit: limit);
  }

  // ── HOME DATA — returns trending + new releases together ────────────────
  Future<({List<SongModel> trending, List<SongModel> newReleases})>
      loadHomeData() async {
    final results = await Future.wait([
      getTrending(limit: 20),
      getNewReleases(limit: 20),
    ]);
    return (trending: results[0], newReleases: results[1]);
  }

  // ── PRIVATE helpers ──────────────────────────────────────────────────────
  Future<List<SongModel>> _getTeluguSongs({int limit = 25}) async {
    final results = <SongModel>[];
    final futures = await Future.wait([
      _jiosaavn.searchSongs('telugu songs', limit: limit ~/ 2),
      _youtube.getTeluguSongs(limit: limit ~/ 2),
    ]);
    for (final l in futures) {
      results.addAll(l);
    }
    return _deduplicate(results).take(limit).toList();
  }

  Future<List<SongModel>> _getHindiSongs({int limit = 25}) async {
    final results = <SongModel>[];
    final futures = await Future.wait([
      _jiosaavn.searchSongs('hindi songs', limit: limit ~/ 2),
      _youtube.getHindiSongs(limit: limit ~/ 2),
    ]);
    for (final l in futures) {
      results.addAll(l);
    }
    return _deduplicate(results).take(limit).toList();
  }

  Future<List<SongModel>> _getTamilSongs({int limit = 25}) async {
    final results = <SongModel>[];
    final futures = await Future.wait([
      _jiosaavn.searchSongs('tamil songs', limit: limit ~/ 2),
      _youtube.getTamilSongs(limit: limit ~/ 2),
    ]);
    for (final l in futures) {
      results.addAll(l);
    }
    return _deduplicate(results).take(limit).toList();
  }

  Future<List<SongModel>> _getEnglishSongs({int limit = 20}) async {
    final results = <SongModel>[];
    final futures = await Future.wait([
      _jiosaavn.searchSongs('english songs', limit: limit ~/ 2),
      _youtube.getEnglishSongs(limit: limit ~/ 2),
    ]);
    for (final l in futures) {
      results.addAll(l);
    }
    return _deduplicate(results).take(limit).toList();
  }

  Future<List<SongModel>> _getAllLanguages({int limit = 40}) async {
    final results = <SongModel>[];
    final futures = await Future.wait([
      _getTeluguSongs(limit: 10),
      _getHindiSongs(limit: 10),
      _getTamilSongs(limit: 10),
      _getEnglishSongs(limit: 10),
    ]);
    for (final l in futures) {
      results.addAll(l);
    }
    results.shuffle();
    return results.take(limit).toList();
  }

  // Remove songs with duplicate titles+artists across sources
  List<SongModel> _deduplicate(List<SongModel> songs) {
    final seen = <String>{};
    return songs.where((s) {
      final key =
          '${s.title.toLowerCase().trim()}_${s.artist.toLowerCase().trim()}';
      return seen.add(key);
    }).toList();
  }
}
