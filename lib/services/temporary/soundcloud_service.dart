// ─────────────────────────────────────────────────────────────────────────────
//  temporary/soundcloud_service.dart  —  15,000 plays/day free
//  ⚠️  This file is in the 'temporary' folder.
//      Deleting this file only removes SoundCloud — rest of app is unaffected.
//
//  Independent Telugu / Hindi artists, remixes, covers
//  Legal status: ✅ SoundCloud's official API
//
//  GET KEY:
//  1. https://developers.soundcloud.com
//  2. Register → Create App
//  3. Copy Client ID
//  4. Paste in lib/config/api_keys.dart → soundcloudClientId
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/song_model.dart';
import '../../config/api_keys.dart';

class SoundCloudService {
  static const String _base     = 'https://api.soundcloud.com';
  static const String _clientId = ApiKeys.soundcloudClientId;

  bool get isConfigured => _clientId != 'YOUR_SOUNDCLOUD_CLIENT_ID';

  // ── Search ───────────────────────────────────────────────────────────────
  Future<List<SongModel>> search(String query, {int limit = 20}) async {
    if (!isConfigured) return [];
    return _fetch(
      '$_base/tracks'
      '?q=${Uri.encodeComponent(query)}'
      '&limit=$limit'
      '&client_id=$_clientId'
      '&linked_partitioning=1',
    );
  }

  // ── Language shortcuts ───────────────────────────────────────────────────
  Future<List<SongModel>> getTeluguSongs({int limit = 20}) =>
      search('telugu', limit: limit);

  Future<List<SongModel>> getHindiSongs({int limit = 20}) =>
      search('hindi', limit: limit);

  Future<List<SongModel>> getTamilSongs({int limit = 20}) =>
      search('tamil', limit: limit);

  // ── Trending ─────────────────────────────────────────────────────────────
  Future<List<SongModel>> getTrending({int limit = 20}) async {
    if (!isConfigured) return [];
    return _fetch(
      '$_base/tracks'
      '?limit=$limit'
      '&order=hotness'
      '&client_id=$_clientId',
    );
  }

  // ── Internal ─────────────────────────────────────────────────────────────
  Future<List<SongModel>> _fetch(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return [];
      final data   = json.decode(res.body);
      final tracks = (data is List ? data : data['collection']) as List? ?? [];

      return tracks
          .where((t) =>
              t['streamable'] == true &&
              (t['stream_url'] ?? '').toString().isNotEmpty)
          .map((t) {
            final streamUrl =
                '${t['stream_url']}?client_id=$_clientId';
            return SongModel(
              id: 'soundcloud_${t['id']}',
              title: t['title'] ?? 'Unknown',
              artist: t['user']?['username'] ?? 'Unknown Artist',
              album: '',
              audioUrl: streamUrl,
              imageUrl: t['artwork_url'] ??
                  t['user']?['avatar_url'] ?? '',
              duration: ((t['duration'] ?? 0) / 1000).round(),
              genre: t['genre'] ?? '',
            );
          })
          .toList();
    } catch (_) {
      return [];
    }
  }
}
