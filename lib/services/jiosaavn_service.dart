// ─────────────────────────────────────────────────────────────────────────────
//  jiosaavn_service.dart  —  JIOSAAVN API SERVICE
//
//  Robust JioSaavn API integration with:
//  - Retry logic (2 attempts) for transient failures
//  - Multiple response format support (_extractResults)
//  - Error tracking for smart fallback decisions
//  - Audio URL validation and filtering
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

enum JioSaavnErrorType {
  network,      // Connection/timeout errors → fallback OK
  invalidData,  // Malformed response → fallback OK
  noResults,    // API returned empty → fallback OK
  rateLimited,  // 429, 503 → retry, then fallback
  notFound,     // 404 → no fallback needed
  unknown,
}

class JioSaavnService {
  static const String _baseUrl = String.fromEnvironment(
    'JIOSAAVN_BASE_URL',
    defaultValue: 'https://saavn.dev',
  );

  JioSaavnErrorType? _lastError;
  String? _lastErrorMessage;

  JioSaavnErrorType? get lastError => _lastError;
  String? get lastErrorMessage => _lastErrorMessage;

  /// Clears error state (e.g., before a new search)
  void clearError() {
    _lastError = null;
    _lastErrorMessage = null;
  }

  /// Search for songs with retry logic (2 attempts)
  Future<List<SongModel>> searchSongs(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) {
      developer.log('[JioSaavn] Empty query provided');
      return [];
    }
    
    clearError();
    developer.log('[JioSaavn] Starting song search: "$query" (limit: $limit, baseUrl: $_baseUrl)');

    // Retry once on transient errors
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final url = Uri.parse(
          '$_baseUrl/api/search/songs?query=${Uri.encodeComponent(query)}&limit=$limit',
        );
        developer.log('[JioSaavn] Attempt $attempt: GET $url');

        final res = await http.get(url).timeout(const Duration(seconds: 10));
        developer.log('[JioSaavn] Attempt $attempt: Response status ${res.statusCode}, body length: ${res.body.length}');

        // Successful response
        if (res.statusCode == 200) {
          final results = _extractResults(res.body);
          developer.log('[JioSaavn] Parsed $results results from response');
          
          if (results.isNotEmpty) {
            _lastError = null;
            developer.log('[JioSaavn] ✓ SUCCESS: Found ${results.length} songs with valid audio URLs');
            return results;
          }
          
          // Empty results is OK — app can fallback to YouTube
          _lastError = JioSaavnErrorType.noResults;
          developer.log('[JioSaavn] No songs found with valid audio URLs (will fallback to YouTube)');
          return [];
        }

        // 404 — don't retry, this query has no results
        if (res.statusCode == 404) {
          _lastError = JioSaavnErrorType.notFound;
          _lastErrorMessage = 'Query not found (404)';
          developer.log('[JioSaavn] ✗ 404: Query not found on JioSaavn');
          return [];
        }

        // Rate limited or service unavailable — retry once
        if (res.statusCode == 429 || res.statusCode == 503) {
          _lastError = JioSaavnErrorType.rateLimited;
          _lastErrorMessage = 'Service rate limited (${res.statusCode})';
          developer.log('[JioSaavn] ✗ Rate limited (${res.statusCode}). Attempt $attempt/2${attempt < 2 ? ', retrying...' : ', giving up'}');
          
          if (attempt == 2) {
            return []; // Don't retry after second attempt
          }
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }

        // Other HTTP errors
        _lastError = JioSaavnErrorType.unknown;
        _lastErrorMessage = 'HTTP ${res.statusCode}';
        developer.log('[JioSaavn] ✗ HTTP Error: ${res.statusCode}');
        return [];
      } catch (e, stack) {
        _lastError = JioSaavnErrorType.network;
        _lastErrorMessage = e.toString();
        developer.log('[JioSaavn] ✗ Network/Exception Error (Attempt $attempt/2): $e\n$stack');

        // On last attempt, don't retry
        if (attempt == 2) {
          developer.log('[JioSaavn] Final attempt failed, not retrying');
          return [];
        }

        // Retry once
        developer.log('[JioSaavn] Retrying in 500ms...');
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return [];
  }

  /// Extract results from different response formats
  /// The API can return results in 3 different ways depending on the endpoint/version
  List<SongModel> _extractResults(String body) {
    try {
      developer.log('[JioSaavn] Parsing JSON response (${body.length} chars)...');
      
      final data = json.decode(body) as Map<String, dynamic>?;
      if (data == null) {
        developer.log('[JioSaavn] ✗ JSON decoded to null');
        return [];
      }

      developer.log('[JioSaavn] Response keys: ${data.keys.toList()}');

      // Format 1: { "data": { "results": [...] } }
      if (data['data'] is Map && (data['data'] as Map)['results'] is List) {
        final results = (data['data'] as Map)['results'] as List;
        developer.log('[JioSaavn] ✓ Format 1 detected: data.data.results (${results.length} items)');
        return _parseSongs(results);
      }

      // Format 2: { "results": [...] }
      if (data['results'] is List) {
        final results = data['results'] as List;
        developer.log('[JioSaavn] ✓ Format 2 detected: results (${results.length} items)');
        return _parseSongs(results);
      }

      // Format 3: Direct song object
      if (data.containsKey('id') && data.containsKey('name')) {
        developer.log('[JioSaavn] ✓ Format 3 detected: Single song object');
        return [SongModel.fromJioSaavn(data)];
      }

      developer.log('[JioSaavn] ✗ Could not match any response format');
      return [];
    } catch (e, stack) {
      developer.log('[JioSaavn] ✗ Parse error: $e\n$stack');
      return [];
    }
  }

  /// Parse songs from a list, filtering out invalid entries
  List<SongModel> _parseSongs(List items) {
    final songs = <SongModel>[];
    developer.log('[JioSaavn] Parsing ${items.length} song items...');
    
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Map<String, dynamic>) {
        developer.log('[JioSaavn]   Item $i: Skipped (not a Map)');
        continue;
      }
      
      try {
        final song = SongModel.fromJioSaavn(item);
        
        // Only include songs with a valid audio URL
        if (song.audioUrl != null && song.audioUrl!.isNotEmpty) {
          songs.add(song);
          developer.log('[JioSaavn]   Item $i: ✓ "${song.title}" by ${song.artist} (url: ${song.audioUrl?.substring(0, 50)}...)');
        } else {
          developer.log('[JioSaavn]   Item $i: ✗ "${item['name'] ?? 'Unknown'}" - No audio URL');
        }
      } catch (e) {
        developer.log('[JioSaavn]   Item $i: ✗ Parse error: $e (title: ${item['name'] ?? 'unknown'})');
      }
    }
    
    developer.log('[JioSaavn] Parsed ${songs.length}/${items.length} songs successfully');
    return songs;
  }

  Future<List<AlbumModel>> searchAlbums(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) {
      developer.log('[JioSaavn] Empty album query');
      return [];
    }
    
    clearError();
    developer.log('[JioSaavn] Album search: "$query"');
    
    try {
      final url = Uri.parse(
        '$_baseUrl/api/search/albums?query=${Uri.encodeComponent(query)}&limit=$limit',
      );
      developer.log('[JioSaavn] GET $url');
      
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      developer.log('[JioSaavn] Album response status: ${res.statusCode}');
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final results = data['data']?['results'] as List? ?? [];
        final albums = results
            .whereType<Map<String, dynamic>>()
            .map((e) => AlbumModel.fromJioSaavn(e))
            .toList();
        developer.log('[JioSaavn] Album search: Found ${albums.length} albums');
        return albums;
      }
      
      developer.log('[JioSaavn] Album search failed: HTTP ${res.statusCode}');
    } catch (e, stack) {
      developer.log('[JioSaavn] Album search error: $e\n$stack');
    }
    return [];
  }

  Future<List<ArtistModel>> searchArtists(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) {
      developer.log('[JioSaavn] Empty artist query');
      return [];
    }
    
    clearError();
    developer.log('[JioSaavn] Artist search: "$query"');
    
    try {
      final url = Uri.parse(
        '$_baseUrl/api/search/artists?query=${Uri.encodeComponent(query)}&limit=$limit',
      );
      developer.log('[JioSaavn] GET $url');
      
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      developer.log('[JioSaavn] Artist response status: ${res.statusCode}');
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final results = data['data']?['results'] as List? ?? [];
        final artists = results
            .whereType<Map<String, dynamic>>()
            .map((e) => ArtistModel.fromJioSaavn(e))
            .toList();
        developer.log('[JioSaavn] Artist search: Found ${artists.length} artists');
        return artists;
      }
      
      developer.log('[JioSaavn] Artist search failed: HTTP ${res.statusCode}');
    } catch (e, stack) {
      developer.log('[JioSaavn] Artist search error: $e\n$stack');
    }
    return [];
  }
}