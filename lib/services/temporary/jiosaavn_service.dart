// ⚠️ RISK FILE — delete this file = app works fine without it
// Requires: deploy https://github.com/sumitkolhe/jiosaavn-api to Vercel
// Add JIOSAAVN_BASE_URL to your .env file

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../models/song_model.dart';

class JioSaavnService {
  String get _base => ApiConfig.jiosaavnBaseUrl;

  bool get isAvailable => _base.isNotEmpty;

  Future<List<SongModel>> search(String query, {int limit = 20}) async {
    if (!isAvailable) return [];
    try {
      final url = Uri.parse(
        '$_base/api/search/songs'
        '?query=${Uri.encodeComponent(query)}'
        '&page=1&limit=$limit',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      
      final data = json.decode(res.body);
      final results = data['data']?['results'] as List? ?? [];
      
      return results
          .map((e) => _toSongModel(e))
          .where((s) => s.audioUrl.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SongModel>> getTrending({int limit = 20}) async {
    if (!isAvailable) return [];
    try {
      final url = Uri.parse(
          '$_base/api/charts?chartid=trending_new_india&limit=$limit');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body);
      final songs = data['data']?['songs'] as List? ?? [];
      return songs.map((e) => _toSongModel(e))
          .where((s) => s.audioUrl.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> getStreamUrl(String songId) async {
    if (!isAvailable) return null;
    try {
      final url = Uri.parse('$_base/api/songs/$songId');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body);
      // Get highest quality available
      final urls = data['data']?[0]?['downloadUrl'] as List? ?? [];
      if (urls.isEmpty) return null;
      return urls.last['url'] as String?; // last = highest quality
    } catch (_) {
      return null;
    }
  }

  SongModel _toSongModel(Map<String, dynamic> e) {
    final downloadUrls = e['downloadUrl'] as List? ?? [];
    String audioUrl = '';
    if (downloadUrls.isNotEmpty) {
      audioUrl = downloadUrls.last['url'] as String? ?? '';
    }
    
    final artists = (e['artists']?['primary'] as List? ?? []);
    final artistName = artists.isNotEmpty
        ? artists.map((a) => a['name']).join(', ')
        : (e['primaryArtists'] ?? 'Unknown');

    final images = e['image'] as List? ?? [];
    final imageUrl = images.isNotEmpty
        ? images.last['url'] as String? ?? ''
        : '';

    return SongModel(
      id: 'saavn_${e['id'] ?? ''}',
      title: e['name'] ?? e['title'] ?? 'Unknown',
      artist: artistName.toString(),
      album: e['album']?['name'] ?? e['album'] ?? '',
      audioUrl: audioUrl,
      imageUrl: imageUrl,
      duration: int.tryParse(e['duration']?.toString() ?? '0') ?? 0,
      genre: '',
    );
  }
}