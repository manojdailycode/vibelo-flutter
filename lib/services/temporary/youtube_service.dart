// ─────────────────────────────────────────────────────────────────────────────
//  temporary/youtube_service.dart  —  YouTube Data API v3
//  Quota: 10,000 units/day free (search costs 100 units per call)
//  audioUrl stores "youtube:VIDEO_ID" — handled by YoutubePlayerWidget
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/song_model.dart';
import '../../config/api_keys.dart';

class YouTubeService {
  static const String _base = 'https://www.googleapis.com/youtube/v3';
  static String get _key => ApiKeys.youtubeApiKey;

  bool get isAvailable => _key.isNotEmpty && _key != 'YOUR_YOUTUBE_API_KEY';

  // ── Search any song ──────────────────────────────────────────────────────
  Future<List<SongModel>> search(String query, {int limit = 20}) async {
    if (!isAvailable) return [];
    return _fetchSearch(query, limit: limit);
  }

  // ── Trending music in India ───────────────────────────────────────────────
  Future<List<SongModel>> getTrending({String regionCode = 'IN', int limit = 20}) async {
    if (!isAvailable) return [];
    try {
      final url = Uri.parse(
        '$_base/videos'
        '?part=snippet,contentDetails'
        '&chart=mostPopular'
        '&videoCategoryId=10'
        '&regionCode=$regionCode'
        '&maxResults=$limit'
        '&key=$_key',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        _logError('getTrending', res);
        return [];
      }
      final data = json.decode(res.body);
      return _parseVideoItems(data['items'] ?? []);
    } catch (e) {
      return [];
    }
  }

  // ── Language shortcuts ────────────────────────────────────────────────────
  Future<List<SongModel>> getTeluguSongs({int limit = 20}) =>
      _fetchSearch('new telugu songs 2025', limit: limit);

  Future<List<SongModel>> getHindiSongs({int limit = 20}) =>
      _fetchSearch('new hindi songs 2025', limit: limit);

  Future<List<SongModel>> getTamilSongs({int limit = 20}) =>
      _fetchSearch('new tamil songs 2025', limit: limit);

  Future<List<SongModel>> getEnglishSongs({int limit = 20}) =>
      _fetchSearch('top english songs 2025', limit: limit);

  // ── Movie / album songs ───────────────────────────────────────────────────
  Future<List<SongModel>> getMovieSongs(String movieName, {int limit = 10}) =>
      _fetchSearch('$movieName full songs jukebox', limit: limit);

  // ── Internal: search via YouTube Data API v3 ─────────────────────────────
  Future<List<SongModel>> _fetchSearch(String query, {int limit = 20}) async {
    if (!isAvailable) return [];
    try {
      final url = Uri.parse(
        '$_base/search'
        '?part=snippet'
        '&q=${Uri.encodeComponent(query)}'
        '&type=video'
        '&videoCategoryId=10'
        '&maxResults=$limit'
        '&regionCode=IN'
        '&relevanceLanguage=hi'
        '&key=$_key',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        _logError('_fetchSearch($query)', res);
        return [];
      }
      final data = json.decode(res.body);
      final items = data['items'] as List? ?? [];
      return _parseSearchItems(items);
    } catch (e) {
      return [];
    }
  }

  // ── Parse search response items ───────────────────────────────────────────
  List<SongModel> _parseSearchItems(List items) {
    final results = <SongModel>[];
    for (final item in items) {
      final videoId = item['id']?['videoId']?.toString() ?? '';
      if (videoId.isEmpty) continue;

      final snippet  = item['snippet'] ?? {};
      final thumbs   = snippet['thumbnails'] ?? {};
      final imageUrl = thumbs['high']?['url'] ??
          thumbs['medium']?['url'] ??
          thumbs['default']?['url'] ?? '';

      final title   = snippet['title'] ?? 'Unknown';
      final channel = snippet['channelTitle'] ?? 'Unknown Artist';

      results.add(SongModel(
        id: 'youtube_$videoId',
        title: _cleanTitle(title),
        artist: _cleanChannel(channel),
        album: '',
        audioUrl: 'youtube:$videoId',  // handled by YoutubePlayerWidget
        imageUrl: imageUrl,
        duration: 0,
        genre: '',
      ));
    }
    return results;
  }

  // ── Parse video list items (from chart endpoint) ──────────────────────────
  List<SongModel> _parseVideoItems(List items) {
    final results = <SongModel>[];
    for (final item in items) {
      final videoId = item['id']?.toString() ?? '';
      if (videoId.isEmpty) continue;

      final snippet  = item['snippet'] ?? {};
      final thumbs   = snippet['thumbnails'] ?? {};
      final imageUrl = thumbs['maxres']?['url'] ??
          thumbs['high']?['url'] ??
          thumbs['medium']?['url'] ?? '';

      results.add(SongModel(
        id: 'youtube_$videoId',
        title: _cleanTitle(snippet['title'] ?? 'Unknown'),
        artist: _cleanChannel(snippet['channelTitle'] ?? 'Unknown'),
        album: '',
        audioUrl: 'youtube:$videoId',
        imageUrl: imageUrl,
        duration: 0,
        genre: '',
      ));
    }
    return results;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _cleanTitle(String raw) {
    // Remove common YouTube suffixes like "(Official Video)", "[4K]", etc.
    return raw
        .replaceAll(RegExp(r'\(Official.*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'\|.*'), '')
        .trim();
  }

  String _cleanChannel(String raw) {
    return raw
        .replaceAll(RegExp(r'Official$', caseSensitive: false), '')
        .replaceAll(RegExp(r'Music$', caseSensitive: false), '')
        .trim();
  }

  void _logError(String method, http.Response res) {
    assert(() {
      // ignore: avoid_print
      print('YouTubeService.$method — HTTP ${res.statusCode}: ${res.body}');
      return true;
    }());
  }

  // ── Static helpers (used by player) ──────────────────────────────────────
  static bool isYouTubeUrl(String audioUrl) => audioUrl.startsWith('youtube:');

  static String? extractVideoId(String audioUrl) {
    if (!isYouTubeUrl(audioUrl)) return null;
    return audioUrl.replaceFirst('youtube:', '');
  }
}
