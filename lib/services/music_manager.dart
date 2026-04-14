import '../config/api_config.dart';
import '../models/song_model.dart';
import 'ZERO_RISK/jamendo_service.dart';
import 'ZERO_RISK/audius_service.dart';
import 'ZERO_RISK/deezer_service.dart';
import 'lyrics_service.dart';

// Conditionally import risky services
// If you delete the RISK folder, remove these 2 imports
import 'RISK/jiosaavn_service.dart';

class MusicManager {
  final _jamendo  = JamendoService();
  final _audius   = AudiusService();
  final _deezer   = DeezerService();
  final _lyrics   = LyricsService();
  final _jiosaavn = JioSaavnService(); // remove if deleting RISK folder

  // ── SEARCH — tries all sources, merges results ──
  Future<List<SongModel>> search(String query) async {
    final futures = <Future<List<SongModel>>>[
      // Zero risk always runs
      _audius.search(query),
      _jamendo.searchSongs(query),
      _deezer.search(query),
      // Risk: only if enabled AND URL is set
      if (ApiConfig.enableJioSaavn && _jiosaavn.isAvailable)
        _jiosaavn.search(query),
    ];

    final results = await Future.wait(futures,
        eagerError: false).catchError((_) => <List<SongModel>>[]);

    // JioSaavn results first (full songs), then others
    final merged = <SongModel>[];
    for (final list in results) {
      merged.addAll(list);
    }
    // Remove duplicates by title+artist
    final seen = <String>{};
    return merged.where((s) {
      final key = '${s.title}_${s.artist}'.toLowerCase();
      return seen.add(key);
    }).toList();
  }

  // ── TRENDING ──
  Future<List<SongModel>> getTrending() async {
    if (ApiConfig.enableJioSaavn && _jiosaavn.isAvailable) {
      final saavn = await _jiosaavn.getTrending();
      if (saavn.isNotEmpty) return saavn;
    }
    return _audius.getTrending();
  }

  // ── LYRICS — zero risk, always works ──
  Future<LyricsResult?> getLyrics(SongModel song) {
    return _lyrics.getLyrics(
      title: song.title,
      artist: song.artist,
      duration: song.duration,
    );
  }
}