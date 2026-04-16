// ─────────────────────────────────────────────────────────────────────────────
//  deezer_service.dart  —  PERMANENT · NO API KEY · 30-second previews
//  Has ALL Telugu / Hindi / Tamil / English film songs as 30s previews
//  Legal status: ✅ Deezer's official public API — previews are legally allowed
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class DeezerService {
  static const String _base = 'https://api.deezer.com';

  // ── Search (any language / artist / film) ────────────────────────────────
  Future<List<SongModel>> search(String query, {int limit = 25}) async {
    return _fetch('$_base/search?q=${Uri.encodeComponent(query)}&limit=$limit');
  }

  // --- Search Albums & Artists (Placeholders) -----------------------------
  Future<List<AlbumModel>> searchAlbums(String query, {int limit = 20}) async {
    final url = '$_base/search/album?q=${Uri.encodeComponent(query)}&limit=$limit';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return [];
    final data = json.decode(res.body);
    final items = data['data'] as List? ?? [];
    return items.map((item) => AlbumModel.fromDeezer(item)).toList();
  }

  Future<List<ArtistModel>> searchArtists(String query, {int limit = 20}) async {
    final url = '$_base/search/artist?q=${Uri.encodeComponent(query)}&limit=$limit';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return [];
    final data = json.decode(res.body);
    final items = data['data'] as List? ?? [];
    return items.map((item) => ArtistModel.fromDeezer(item)).toList();
  }

  // ── Language shortcuts ───────────────────────────────────────────────────
  Future<List<SongModel>> getTeluguSongs({int limit = 25}) =>
      search('telugu songs', limit: limit);

  Future<List<SongModel>> getHindiSongs({int limit = 25}) =>
      search('hindi songs', limit: limit);

  Future<List<SongModel>> getTamilSongs({int limit = 25}) =>
      search('tamil songs', limit: limit);

  Future<List<SongModel>> getEnglishSongs({int limit = 25}) =>
      search('english pop', limit: limit);

  // ── Chart / trending ─────────────────────────────────────────────────────
  Future<List<SongModel>> getChartSongs({int limit = 25}) async {
    return _fetch('$_base/chart/0/tracks?limit=$limit');
  }

  // ── Artist songs ─────────────────────────────────────────────────────────
  Future<List<SongModel>> getArtistSongs(String artistName,
      {int limit = 20}) async {
    // First find artist id
    try {
      final res = await http
          .get(Uri.parse(
              '$_base/search/artist?q=${Uri.encodeComponent(artistName)}&limit=1'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body);
      final artists = data['data'] as List? ?? [];
      if (artists.isEmpty) return [];
      final artistId = artists.first['id'];
      return _fetch('$_base/artist/$artistId/top?limit=$limit');
    } catch (_) {
      return [];
    }
  }

  // ── Album ────────────────────────────────────────────────────────────────
  Future<List<SongModel>> getAlbumTracks(String albumName,
      {int limit = 20}) async {
    return search(albumName, limit: limit);
  }

  // ── Internal ─────────────────────────────────────────────────────────────
  Future<List<SongModel>> _fetch(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return [];
      final data = json.decode(res.body);

      // Chart endpoint returns {'tracks':{'data':[]}}
      // Search endpoint returns {'data':[]}
      List tracks = [];
      if (data['data'] != null) {
        tracks = data['data'] as List;
      } else if (data['tracks'] != null) {
        tracks = (data['tracks']['data'] ?? []) as List;
      }

      return tracks
          .where((t) => (t['preview'] ?? '').toString().isNotEmpty)
          .map((t) => SongModel(
                id: 'deezer_${t['id']}',
                title: t['title'] ?? 'Unknown',
                artist: t['artist']?['name'] ?? 'Unknown Artist',
                album: t['album']?['title'] ?? '',
                audioUrl: t['preview'] ?? '',   // 30-second MP3 preview
                imageUrl: t['album']?['cover_big'] ??
                    t['album']?['cover_medium'] ?? '',
                duration: (t['duration'] ?? 30) as int,
                genre: '',
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
