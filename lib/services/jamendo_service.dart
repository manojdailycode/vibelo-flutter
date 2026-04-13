import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

// ─────────────────────────────────────────────────────
//  Jamendo API — Royalty-Free Music
//  Register FREE at: https://devportal.jamendo.com/
//  Replace YOUR_CLIENT_ID below with your Client ID
// ─────────────────────────────────────────────────────
class JamendoService {
  static const String _clientId = ''; // ← Replace this
  static const String _base = 'https://api.jamendo.com/v3.0';

  // ── Trending / Featured Songs ────────────────────
  Future<List<SongModel>> getTrendingSongs({int limit = 20}) async {
    return _fetchTracks(
      '$_base/tracks/?client_id=$_clientId'
      '&format=json&limit=$limit'
      '&include=musicinfo&audioformat=mp32'
      '&order=popularity_total',
    );
  }

  // ── New Releases ─────────────────────────────────
  Future<List<SongModel>> getNewReleases({int limit = 20}) async {
    return _fetchTracks(
      '$_base/tracks/?client_id=$_clientId'
      '&format=json&limit=$limit'
      '&include=musicinfo&audioformat=mp32'
      '&order=releasedate_desc',
    );
  }

  // ── Search Songs ─────────────────────────────────
  Future<List<SongModel>> searchSongs(String query, {int limit = 20}) async {
    final encoded = Uri.encodeComponent(query);
    return _fetchTracks(
      '$_base/tracks/?client_id=$_clientId'
      '&format=json&limit=$limit'
      '&include=musicinfo&audioformat=mp32'
      '&search=$encoded',
    );
  }

  // ── By Genre ─────────────────────────────────────
  Future<List<SongModel>> getSongsByGenre(String genre,
      {int limit = 20}) async {
    final encoded = Uri.encodeComponent(genre.toLowerCase());
    return _fetchTracks(
      '$_base/tracks/?client_id=$_clientId'
      '&format=json&limit=$limit'
      '&include=musicinfo&audioformat=mp32'
      '&tags=$encoded',
    );
  }

  // ── By Artist Name ───────────────────────────────
  Future<List<SongModel>> getSongsByArtist(String artistName,
      {int limit = 20}) async {
    final encoded = Uri.encodeComponent(artistName);
    return _fetchTracks(
      '$_base/tracks/?client_id=$_clientId'
      '&format=json&limit=$limit'
      '&include=musicinfo&audioformat=mp32'
      '&artist_name=$encoded',
    );
  }

  // ── Mood Playlists ───────────────────────────────
  static const Map<String, String> moods = {
    'Happy':     'happy',
    'Sad':       'sad',
    'Chill':     'chill',
    'Energy':    'energetic',
    'Focus':     'ambient',
    'Romance':   'romantic',
    'Party':     'party',
    'Sleep':     'sleep',
  };

  Future<List<SongModel>> getMoodPlaylist(String mood,
      {int limit = 20}) async {
    final tag = moods[mood] ?? mood.toLowerCase();
    return getSongsByGenre(tag, limit: limit);
  }

  // ── Genre List ───────────────────────────────────
  static const List<Map<String, dynamic>> genres = [
    {'name': 'Pop',       'tag': 'pop',       'emoji': '🎵'},
    {'name': 'Rock',      'tag': 'rock',      'emoji': '🎸'},
    {'name': 'Hip-Hop',   'tag': 'hiphop',    'emoji': '🎤'},
    {'name': 'Jazz',      'tag': 'jazz',      'emoji': '🎷'},
    {'name': 'Classical', 'tag': 'classical', 'emoji': '🎻'},
    {'name': 'Electronic','tag': 'electronic','emoji': '🎛️'},
    {'name': 'Ambient',   'tag': 'ambient',   'emoji': '🌊'},
    {'name': 'Folk',      'tag': 'folk',      'emoji': '🪕'},
    {'name': 'R&B',       'tag': 'rnb',       'emoji': '💜'},
    {'name': 'Metal',     'tag': 'metal',     'emoji': '🤘'},
  ];

  // ── Internal: Fetch & Parse ──────────────────────
  Future<List<SongModel>> _fetchTracks(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        return results
            .map((e) => SongModel.fromJamendo(e as Map<String, dynamic>))
            .where((s) => s.audioUrl.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      // Return empty on error — UI shows empty state
      return [];
    }
  }
}
