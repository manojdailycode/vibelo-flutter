import '../models/song_model.dart';
import 'jamendo_service.dart';
import 'audius_service.dart';
import 'deezer_service.dart';
import 'lyrics_service.dart';
import 'temporary/jiosaavn_service.dart';

class MusicManager {
  final _jamendo  = JamendoService();
  final _audius   = AudiusService();
  final _deezer   = DeezerService();
  final _lyrics   = LyricsService();
  final _jiosaavn = JioSaavnService();

  Future<List<SongModel>> search(String query) async {
    final futures = <Future<List<SongModel>>>[
      _audius.search(query),
      _jamendo.searchSongs(query),
      _deezer.search(query),
      if (_jiosaavn.isAvailable) _jiosaavn.search(query),
    ];
    final results = await Future.wait(futures);
    final merged = <SongModel>[];
    for (final list in results) { merged.addAll(list); }
    final seen = <String>{};
    return merged.where((s) {
      final key = '${s.title}_${s.artist}'.toLowerCase();
      return seen.add(key);
    }).toList();
  }

  Future<List<SongModel>> getTrending() async {
    if (_jiosaavn.isAvailable) {
      final saavn = await _jiosaavn.getTrending();
      if (saavn.isNotEmpty) return saavn;
    }
    return _audius.getTrending();
  }

  Future<LyricsResult?> getLyrics(SongModel song) {
    return _lyrics.getLyrics(
      title: song.title,
      artist: song.artist,
      duration: song.duration,
    );
  }
}