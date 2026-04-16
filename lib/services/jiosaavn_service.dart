// ─────────────────────────────────────────────────────────────────────────────
//  jiosaavn_service.dart  —  SERVICE TO BE IMPLEMENTED
//
//  This is a placeholder for the JioSaavn API integration.
//  The `searchSongs`, `searchAlbums`, and `searchArtists` methods should be
//  implemented here to fetch data from the JioSaavn API.
//
//  The `song_model.dart` already contains a `SongModel.fromJioSaavn` factory
//  to help with parsing the response.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class JioSaavnService {
  static const String _baseUrl = String.fromEnvironment(
    'JIOSAAVN_BASE_URL',
    defaultValue: 'https://saavn.dev', // Default public instance fallback
  );

  Future<List<SongModel>> searchSongs(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    try {
      final url = Uri.parse('$_baseUrl/api/search/songs?query=${Uri.encodeComponent(query)}&limit=$limit');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final results = data['data']?['results'] as List? ?? [];
        return results.map((e) => SongModel.fromJioSaavn(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Silently catch exceptions and return an empty list
    }
    return [];
  }

  Future<List<AlbumModel>> searchAlbums(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    try {
      final url = Uri.parse('$_baseUrl/api/search/albums?query=${Uri.encodeComponent(query)}&limit=$limit');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final results = data['data']?['results'] as List? ?? [];
        return results.map((e) => AlbumModel.fromJioSaavn(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Silently catch exceptions and return an empty list
    }
    return [];
  }

  Future<List<ArtistModel>> searchArtists(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    try {
      final url = Uri.parse('$_baseUrl/api/search/artists?query=${Uri.encodeComponent(query)}&limit=$limit');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final results = data['data']?['results'] as List? ?? [];
        return results.map((e) => ArtistModel.fromJioSaavn(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Silently catch exceptions and return an empty list
    }
    return [];
  }
}