// ─────────────────────────────────────────────────────────────────────────────
//  temporary/youtube_service.dart  —  QUOTA-BASED (10,000 units/day free)
//  ⚠️  This file is in the 'temporary' folder.
//      Deleting this file only removes YouTube — rest of app is unaffected.
//
//  Has ALL Telugu / Hindi / Tamil / English songs as full music videos
//  Plays inside the app using youtube_player_flutter package
//  Legal status: ✅ YouTube's official Data API v3 — personal use allowed
//
//  GET KEY:
//  1. https://console.cloud.google.com
//  2. New Project → name "Vibelo"
//  3. APIs & Services → Library → search "YouTube Data API v3" → Enable
//  4. Credentials → Create Credentials → API Key → copy it
//  5. Paste in lib/config/api_keys.dart → youtubeApiKey
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/song_model.dart';
import '../../config/api_keys.dart';

class YouTubeService {
  static const String _base = 'https://www.googleapis.com/youtube/v3';
  static const String _key  = ApiKeys.youtubeApiKey;

  // Quota cost: 100 units per search call
  // 10,000 units/day = ~100 searches/day free

  // ── Search any song ──────────────────────────────────────────────────────
  Future<List<SongModel>> search(String query, {int limit = 20}) async {
    if (_key == 'YOUR_YOUTUBE_API_KEY') return [];
    return _fetchSearch(query, limit: limit);
  }

  // ── Language shortcuts ───────────────────────────────────────────────────
  Future<List<SongModel>> getTeluguSongs({int limit = 20}) =>
      _fetchSearch('telugu songs 2024', limit: limit);

  Future<List<SongModel>> getHindiSongs({int limit = 20}) =>
      _fetchSearch('hindi songs 2024', limit: limit);

  Future<List<SongModel>> getTamilSongs({int limit = 20}) =>
      _fetchSearch('tamil songs 2024', limit: limit);

  Future<List<SongModel>> getEnglishSongs({int limit = 20}) =>
      _fetchSearch('english songs 2024', limit: limit);

  // ── Trending / popular ───────────────────────────────────────────────────
  Future<List<SongModel>> getTrending({
    String regionCode = 'IN',
    int limit = 20,
  }) async {
    if (_key == 'YOUR_YOUTUBE_API_KEY') return [];
    try {
      final url = '$_base/videos'
          '?part=snippet,contentDetails'
          '&chart=mostPopular'
          '&videoCategoryId=10'   // category 10 = Music
          '&regionCode=$regionCode'
          '&maxResults=$limit'
          '&key=$_key';

      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return [];
      final data = json.decode(res.body);
      return _parseVideoItems(data['items'] ?? []);
    } catch (_) {
      return [];
    }
  }

  // ── Specific artist ──────────────────────────────────────────────────────
  Future<List<SongModel>> getArtistSongs(String artist,
      {int limit = 15}) =>
      _fetchSearch('$artist songs', limit: limit);

  // ── Movie / album songs ──────────────────────────────────────────────────
  Future<List<SongModel>> getMovieSongs(String movieName,
      {int limit = 10}) =>
      _fetchSearch('$movieName full songs jukebox', limit: limit);

  // ── Internal: search ────────────────────────────────────────────────────
  Future<List<SongModel>> _fetchSearch(String query,
      {int limit = 20}) async {
    if (_key == 'YOUR_YOUTUBE_API_KEY') return [];
    try {
      final url = '$_base/search'
          '?part=snippet'
          '&q=${Uri.encodeComponent(query)}'
          '&type=video'
          '&videoCategoryId=10'
          '&maxResults=$limit'
          '&regionCode=IN'
          '&key=$_key';

      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return [];
      final data = json.decode(res.body);
      final items = data['items'] as List? ?? [];

      return items.map((item) {
        final videoId  = item['id']?['videoId']?.toString() ?? '';
        final snippet  = item['snippet'] ?? {};
        final thumbs   = snippet['thumbnails'] ?? {};
        final imageUrl = thumbs['high']?['url'] ??
            thumbs['medium']?['url'] ?? '';

        return SongModel(
          id: 'youtube_$videoId',
          title: snippet['title'] ?? 'Unknown',
          artist: snippet['channelTitle'] ?? 'Unknown Artist',
          album: '',
          // audioUrl stores the video ID — YouTubePlayerWidget reads this
          audioUrl: 'youtube:$videoId',
          imageUrl: imageUrl,
          duration: 0,   // duration unknown from search; fill if needed
          genre: '',
        );
      }).where((s) => s.audioUrl != 'youtube:').toList();
    } catch (_) {
      return [];
    }
  }

  // ── Internal: parse video list items ────────────────────────────────────
  List<SongModel> _parseVideoItems(List items) {
    return items.map((item) {
      final videoId = item['id']?.toString() ?? '';
      final snippet = item['snippet'] ?? {};
      final thumbs  = snippet['thumbnails'] ?? {};
      final imageUrl = thumbs['high']?['url'] ??
          thumbs['medium']?['url'] ?? '';

      return SongModel(
        id: 'youtube_$videoId',
        title: snippet['title'] ?? 'Unknown',
        artist: snippet['channelTitle'] ?? 'Unknown',
        album: '',
        audioUrl: 'youtube:$videoId',
        imageUrl: imageUrl,
        duration: 0,
        genre: '',
      );
    }).where((s) => s.audioUrl != 'youtube:').toList();
  }

  // ── Helper: extract video ID from audioUrl ───────────────────────────────
  static String? extractVideoId(String audioUrl) {
    if (!audioUrl.startsWith('youtube:')) return null;
    return audioUrl.replaceFirst('youtube:', '');
  }

  static bool isYouTubeUrl(String audioUrl) =>
      audioUrl.startsWith('youtube:');
}
