// ─────────────────────────────────────────────────────────────────────────────
//  music_source_manager.dart  —  CORE FILE — NEVER DELETE
//
//  Manages all music sources with automatic fallback.
//  If any temporary service file is deleted, this manager skips it gracefully.
//  Priority order:
//    1. Deezer   (no key, 30s previews, all Indian films)
//    2. Audius   (no key, full songs, independent artists)
//    3. YouTube  (API key needed, full songs via video player)
//    4. Spotify  (API key needed, 30s previews)
//    5. SoundCloud (API key needed, full songs)
//    6. Jamendo  (API key needed, Western/World music)
// ─────────────────────────────────────────────────────────────────────────────

import '../models/song_model.dart';
import 'jamendo_service.dart';
import 'audius_service.dart';
import 'deezer_service.dart';
import 'temporary/youtube_service.dart';
import 'temporary/spotify_service.dart';
import 'temporary/soundcloud_service.dart';

enum MusicLanguage { telugu, hindi, tamil, english, all }

class MusicSourceManager {
  MusicSourceManager._();
  static final MusicSourceManager instance = MusicSourceManager._();

  final _deezer      = DeezerService();
  final _audius      = AudiusService();
  final _jamendo     = JamendoService();
  final _youtube     = YouTubeService();
  final _spotify     = SpotifyService();
  final _soundcloud  = SoundCloudService();

  // ── SEARCH — tries all sources, merges results ───────────────────────────
  Future<List<SongModel>> search(String query, {int limit = 25}) async {
    final results = <SongModel>[];

    // Run all sources in parallel for speed
    final futures = await Future.wait([
      _deezer.search(query, limit: limit ~/ 2),
      _audius.search(query, limit: limit ~/ 3),
      _youtube.search(query, limit: limit ~/ 3),
      _spotify.search(query, limit: limit ~/ 3),
      _soundcloud.search(query, limit: limit ~/ 4),
    ]);

    for (final list in futures) {
      results.addAll(list);
    }

    return _deduplicate(results).take(limit).toList();
  }

  // ── TRENDING ─────────────────────────────────────────────────────────────
  Future<List<SongModel>> getTrending({int limit = 20}) async {
    // Try YouTube trending India first (most relevant for Indian users)
    final yt = await _youtube.getTrending(regionCode: 'IN', limit: limit);
    if (yt.isNotEmpty) return yt;

    // Fallback: Deezer charts
    final deezer = await _deezer.getChartSongs(limit: limit);
    if (deezer.isNotEmpty) return deezer;

    // Fallback: Audius
    final audius = await _audius.getTrending(limit: limit);
    if (audius.isNotEmpty) return audius;

    // Final fallback: Jamendo
    return _jamendo.getTrendingSongs(limit: limit);
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
    final spotify = await _spotify.getNewReleases(limit: limit);
    if (spotify.isNotEmpty) return spotify;

    final jamendo = await _jamendo.getNewReleases(limit: limit);
    if (jamendo.isNotEmpty) return jamendo;

    return _audius.getTrending(limit: limit);
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
      _deezer.getTeluguSongs(limit: limit ~/ 2),
      _youtube.getTeluguSongs(limit: limit ~/ 3),
      _audius.getTeluguSongs(limit: limit ~/ 4),
      _spotify.getTeluguSongs(limit: limit ~/ 4),
    ]);
    for (final l in futures) results.addAll(l);
    return _deduplicate(results).take(limit).toList();
  }

  Future<List<SongModel>> _getHindiSongs({int limit = 25}) async {
    final results = <SongModel>[];
    final futures = await Future.wait([
      _deezer.getHindiSongs(limit: limit ~/ 2),
      _youtube.getHindiSongs(limit: limit ~/ 3),
      _spotify.getHindiSongs(limit: limit ~/ 4),
      _audius.getHindiSongs(limit: limit ~/ 4),
    ]);
    for (final l in futures) results.addAll(l);
    return _deduplicate(results).take(limit).toList();
  }

  Future<List<SongModel>> _getTamilSongs({int limit = 25}) async {
    final results = <SongModel>[];
    final futures = await Future.wait([
      _deezer.getTamilSongs(limit: limit ~/ 2),
      _youtube.getTamilSongs(limit: limit ~/ 3),
      _spotify.getTamilSongs(limit: limit ~/ 4),
      _audius.getTamilSongs(limit: limit ~/ 4),
    ]);
    for (final l in futures) results.addAll(l);
    return _deduplicate(results).take(limit).toList();
  }

  Future<List<SongModel>> _getEnglishSongs({int limit = 20}) async {
    final results = <SongModel>[];
    final futures = await Future.wait([
      _deezer.getEnglishSongs(limit: limit ~/ 2),
      _youtube.getEnglishSongs(limit: limit ~/ 3),
      _jamendo.getTrendingSongs(limit: limit ~/ 4),
    ]);
    for (final l in futures) results.addAll(l);
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
    for (final l in futures) results.addAll(l);
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
