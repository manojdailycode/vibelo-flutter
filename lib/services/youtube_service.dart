// ─────────────────────────────────────────────────────────────────────────────
//  youtube_service.dart
//
//  Service for interacting with the YouTube API.
//  - Uses YouTube Data API v3 for searching (requires an API key).
//  - Uses YoutubeExplode to extract audio-only stream URLs for playback.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song_model.dart';

class YouTubeService {
  // IMPORTANT: It's recommended to load your API key from a secure location.
  // You can pass it during the build process like this:
  // flutter run --dart-define=YOUTUBE_API_KEY=YOUR_API_KEY
  static const _apiKey = String.fromEnvironment('YOUTUBE_API_KEY');

  final _youtubeExplode = YoutubeExplode();
  final _httpClient = http.Client();

  /// Searches YouTube for videos and returns them as a list of SongModels.
  Future<List<SongModel>> search(String query, {int limit = 20}) async {
    if (_apiKey.isEmpty) {
      // ignore: avoid_print
      print('YouTube API key is not set. Skipping YouTube search.');
      return [];
    }
    try {
      final url = Uri.https('www.googleapis.com', '/youtube/v3/search', {
        'part': 'snippet',
        'q': query,
        'type': 'video',
        'maxResults': limit.toString(),
        'key': _apiKey,
      });

      final res = await _httpClient.get(url);
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body);
      final items = data['items'] as List;

      return items.map((item) {
        final videoId = item['id']['videoId'];
        final snippet = item['snippet'];
        return SongModel(
          id: videoId,
          title: snippet['title'],
          artist: snippet['channelTitle'],
          album: '', // YouTube search API does not provide an album
          imageUrl: snippet['thumbnails']['high']['url'],
          // We use a custom scheme to identify YouTube tracks.
          // The player will resolve this to a real stream URL just before playback.
          audioUrl: 'youtube://$videoId',
          duration: 0, // Search API doesn't provide duration.
          source: 'YouTube',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetches the most popular music videos for a given region.
  Future<List<SongModel>> getTrending({String regionCode = 'IN', int limit = 20}) async {
    if (_apiKey.isEmpty) return [];
    try {
      final url = Uri.https('www.googleapis.com', '/youtube/v3/videos', {
        'part': 'snippet,contentDetails',
        'chart': 'mostPopular',
        'videoCategoryId': '10', // Music
        'regionCode': regionCode,
        'maxResults': limit.toString(),
        'key': _apiKey,
      });
      final res = await _httpClient.get(url);
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body);
      final items = data['items'] as List;

      return items.map((item) {
        final snippet = item['snippet'];
        final duration = _parseDuration(item['contentDetails']?['duration'] ?? 'PT0S');
        return SongModel(
          id: item['id'],
          title: snippet['title'],
          artist: snippet['channelTitle'],
          album: '',
          imageUrl: snippet['thumbnails']?['high']?['url'] ?? '',
          audioUrl: 'youtube://${item['id']}',
          duration: duration,
          source: 'YouTube',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ── Language shortcuts ────────────────────────────────────────────────────
  Future<List<SongModel>> getTeluguSongs({int limit = 20}) =>
      search('new telugu songs 2025', limit: limit);

  Future<List<SongModel>> getHindiSongs({int limit = 20}) =>
      search('new hindi songs 2025', limit: limit);

  Future<List<SongModel>> getTamilSongs({int limit = 20}) =>
      search('new tamil songs 2025', limit: limit);

  Future<List<SongModel>> getEnglishSongs({int limit = 20}) =>
      search('top english songs 2025', limit: limit);

  /// Uses YoutubeExplode to get the actual audio stream URL.
  /// This should be called by your PlayerProvider just before playing a song.
  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(videoId);
      // Get the audio-only stream with the highest bitrate.
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      return streamInfo.url.toString();
    } catch (e) {
      return null;
    }
  }

  /// Helper to parse ISO 8601 duration format (e.g., "PT2M35S") to seconds.
  int _parseDuration(String duration) {
    final regExp = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regExp.firstMatch(duration);
    if (match == null) return 0;
    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
    return (hours * 3600) + (minutes * 60) + seconds;
  }

  void dispose() {
    _youtubeExplode.close();
    _httpClient.close();
  }

  // ── Static helpers (used by player) ──────────────────────────────────────
  static bool isYouTubeUrl(String? audioUrl) {
    if (audioUrl == null || audioUrl.isEmpty) return false;
    return audioUrl.startsWith('youtube://') || audioUrl.startsWith('youtube:');
  }

  static String? extractVideoId(String? audioUrl) {
    if (!isYouTubeUrl(audioUrl)) return null;
    return audioUrl!.replaceFirst(RegExp(r'^youtube:\/\/|^youtube:'), '');
  }
}