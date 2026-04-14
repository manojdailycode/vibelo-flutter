// ─────────────────────────────────────────────────────────────────────────────
//  temporary/spotify_service.dart  —  TOKEN REFRESHES EVERY 60 MIN (auto)
//  ⚠️  This file is in the 'temporary' folder.
//      Deleting this file only removes Spotify — rest of app is unaffected.
//
//  30-second previews of ALL Telugu / Hindi / Tamil / English songs
//  Legal status: ✅ Spotify's official Web API — previews allowed
//
//  GET KEYS:
//  1. https://developer.spotify.com/dashboard
//  2. Log in (free Spotify account works)
//  3. Create App → name "Vibelo" → any redirect URI e.g. http://localhost
//  4. Copy Client ID + Client Secret
//  5. Paste in lib/config/api_keys.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/song_model.dart';
import '../../config/api_keys.dart';

class SpotifyService {
  static const String _authBase = 'https://accounts.spotify.com';
  static const String _apiBase  = 'https://api.spotify.com/v1';

  String? _accessToken;
  DateTime? _tokenExpiry;

  // ── Get / refresh token (Client Credentials flow — no user login needed) ─
  Future<String?> _getToken() async {
    // ignore: prefer_const_declarations
   final clientId = ApiKeys.spotifyClientId;

// ignore: prefer_const_declarations
   final clientSecret = ApiKeys.spotifyClientSecret;
    if (clientId == 'YOUR_SPOTIFY_CLIENT_ID') return null;

    // Return cached token if still valid (with 60s buffer)
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(
            _tokenExpiry!.subtract(const Duration(seconds: 60)))) {
      return _accessToken;
    }

    try {
      final credentials = base64Encode(
          utf8.encode('$clientId:$clientSecret'));

      final res = await http.post(
        Uri.parse('$_authBase/api/token'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'grant_type': 'client_credentials'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null;
      final data = json.decode(res.body);
      _accessToken = data['access_token'];
      _tokenExpiry = DateTime.now()
          .add(Duration(seconds: data['expires_in'] ?? 3600));
      return _accessToken;
    } catch (_) {
      return null;
    }
  }

  // ── Search ───────────────────────────────────────────────────────────────
  Future<List<SongModel>> search(String query, {int limit = 20}) async {
    final token = await _getToken();
    if (token == null) return [];
    return _fetch(
      '$_apiBase/search'
      '?q=${Uri.encodeComponent(query)}'
      '&type=track'
      '&limit=$limit'
      '&market=IN',
      token,
    );
  }

  // ── Language shortcuts ───────────────────────────────────────────────────
  Future<List<SongModel>> getTeluguSongs({int limit = 20}) =>
      search('telugu', limit: limit);

  Future<List<SongModel>> getHindiSongs({int limit = 20}) =>
      search('hindi', limit: limit);

  Future<List<SongModel>> getTamilSongs({int limit = 20}) =>
      search('tamil', limit: limit);

  // ── New releases India ───────────────────────────────────────────────────
  Future<List<SongModel>> getNewReleases({int limit = 20}) async {
    final token = await _getToken();
    if (token == null) return [];
    try {
      final res = await http.get(
        Uri.parse(
            '$_apiBase/browse/new-releases?country=IN&limit=$limit'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return [];
      final data  = json.decode(res.body);
      final albums = data['albums']?['items'] as List? ?? [];

      // Fetch tracks from first album as sample
      if (albums.isEmpty) return [];
      final albumId = albums.first['id'];
      return _fetchAlbumTracks(albumId, token);
    } catch (_) {
      return [];
    }
  }

  // ── Artist top tracks ────────────────────────────────────────────────────
  Future<List<SongModel>> getArtistTopTracks(String artistName) async {
    return search('artist:$artistName');
  }

  // ── Internal: fetch album tracks ────────────────────────────────────────
  Future<List<SongModel>> _fetchAlbumTracks(
      String albumId, String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_apiBase/albums/$albumId/tracks?limit=20'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final data   = json.decode(res.body);
      final tracks = data['items'] as List? ?? [];
      return tracks
          .where((t) => (t['preview_url'] ?? '').toString().isNotEmpty)
          .map((t) => SongModel(
                id: 'spotify_${t['id']}',
                title: t['name'] ?? 'Unknown',
                artist: (t['artists'] as List?)
                        ?.map((a) => a['name'])
                        .join(', ') ??
                    'Unknown',
                album: '',
                audioUrl: t['preview_url'] ?? '',
                imageUrl: '',
                duration: ((t['duration_ms'] ?? 30000) / 1000).round(),
                genre: '',
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Internal: search fetch ───────────────────────────────────────────────
  Future<List<SongModel>> _fetch(String url, String token) async {
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return [];
      final data   = json.decode(res.body);
      final tracks = data['tracks']?['items'] as List? ?? [];

      return tracks
          .where((t) => (t['preview_url'] ?? '').toString().isNotEmpty)
          .map((t) {
            final album   = t['album'] ?? {};
            final images  = album['images'] as List? ?? [];
            final imageUrl = images.isNotEmpty
                ? images.first['url'] ?? ''
                : '';

            return SongModel(
              id: 'spotify_${t['id']}',
              title: t['name'] ?? 'Unknown',
              artist: (t['artists'] as List?)
                      ?.map((a) => a['name'])
                      .join(', ') ??
                  'Unknown',
              album: album['name'] ?? '',
              audioUrl: t['preview_url'] ?? '',
              imageUrl: imageUrl,
              duration: ((t['duration_ms'] ?? 30000) / 1000).round(),
              genre: '',
            );
          })
          .toList();
    } catch (_) {
      return [];
    }
  }
}
