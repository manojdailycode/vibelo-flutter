// ─────────────────────────────────────────────────────────────────────────────
//  audius_service.dart  —  PERMANENT · NO API KEY · Full audio
//  Decentralised music platform — Creative Commons + artist-uploaded
//  Telugu / Hindi independent artists available
//  Legal status: ✅ artists upload their own music freely
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class AudiusService {
  // Audius auto-discovers healthy nodes; this is the official discovery endpoint
  static const String _discovery = 'https://discoveryprovider.audius.co';
  static const String _appName   = 'Vibelo';

  // ── Search ───────────────────────────────────────────────────────────────
  Future<List<SongModel>> search(String query, {int limit = 20}) async {
    return _fetch(
      '$_discovery/v1/tracks/search'
      '?query=${Uri.encodeComponent(query)}'
      '&limit=$limit'
      '&app_name=$_appName',
    );
  }

  // ── Trending ─────────────────────────────────────────────────────────────
  Future<List<SongModel>> getTrending({int limit = 20}) async {
    return _fetch(
      '$_discovery/v1/tracks/trending'
      '?limit=$limit'
      '&app_name=$_appName',
    );
  }

  // ── Telugu songs ─────────────────────────────────────────────────────────
  Future<List<SongModel>> getTeluguSongs({int limit = 20}) async {
    return search('telugu', limit: limit);
  }

  // ── Hindi songs ──────────────────────────────────────────────────────────
  Future<List<SongModel>> getHindiSongs({int limit = 20}) async {
    return search('hindi', limit: limit);
  }

  // ── Tamil songs ──────────────────────────────────────────────────────────
  Future<List<SongModel>> getTamilSongs({int limit = 20}) async {
    return search('tamil', limit: limit);
  }

  // ── By genre ─────────────────────────────────────────────────────────────
  Future<List<SongModel>> getByGenre(String genre, {int limit = 20}) async {
    return _fetch(
      '$_discovery/v1/tracks/search'
      '?query=${Uri.encodeComponent(genre)}'
      '&limit=$limit'
      '&app_name=$_appName',
    );
  }

  // ── Internal ─────────────────────────────────────────────────────────────
  Future<List<SongModel>> _fetch(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return [];
      final data = json.decode(res.body);
      final List tracks = data['data'] ?? [];

      final results = <SongModel>[];
      for (final t in tracks) {
        final id = t['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        // Stream URL — Audius provides direct stream per track ID
        final streamUrl =
            '$_discovery/v1/tracks/$id/stream?app_name=$_appName';

        final artwork = t['artwork'];
        String imageUrl = '';
        if (artwork != null) {
          imageUrl = artwork['480x480'] ??
              artwork['150x150'] ??
              artwork['_150x150'] ??
              '';
        }

        results.add(SongModel(
          id: 'audius_$id',
          title: t['title'] ?? 'Unknown',
          artist: t['user']?['name'] ?? 'Unknown Artist',
          album: t['album'] ?? '',
          audioUrl: streamUrl,
          imageUrl: imageUrl,
          duration: (t['duration'] ?? 0) as int,
          genre: t['genre'] ?? '',
        ));
      }
      return results;
    } catch (e) {
      return [];
    }
  }
}
