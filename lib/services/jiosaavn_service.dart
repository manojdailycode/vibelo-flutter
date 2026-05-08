import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

enum JioSaavnErrorType { none, configMissing, timeout, httpError, parseError, unknown }

class JioSaavnService {
  // Read from --dart-define / environment only.
  // Keep default empty to avoid exposing infrastructure URLs in source.
  static const String _baseUrl = String.fromEnvironment(
    'JIOSAAVN_BASE_URL',
    defaultValue: '',
  );

  String get _normalizedBaseUrl =>
      _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  JioSaavnErrorType _lastErrorType = JioSaavnErrorType.none;
  String? _lastErrorMessage;
  int _lastStatusCode = 0;

  final Map<String, List<SongModel>> _searchCache = {};
  final Map<String, Future<List<SongModel>>> _inflightSearch = {};

  JioSaavnErrorType get lastErrorType => _lastErrorType;
  String? get lastErrorMessage => _lastErrorMessage;
  int get lastStatusCode => _lastStatusCode;
  bool get lastRequestFailed => _lastErrorType != JioSaavnErrorType.none;

  void _setError(JioSaavnErrorType type, String message, {int statusCode = 0}) {
    _lastErrorType = type;
    _lastErrorMessage = message;
    _lastStatusCode = statusCode;
    _log('[JioSaavnService] ERROR [$type] $message (status=$statusCode)');
  }

  void _clearError() {
    _lastErrorType = JioSaavnErrorType.none;
    _lastErrorMessage = null;
    _lastStatusCode = 0;
  }

  void _debugResponse({
    required String endpoint,
    required http.Response response,
    required String query,
  }) {
    _log('[JioSaavnService] endpoint: $endpoint');
    _log('[JioSaavnService] query: $query');
    _log('[JioSaavnService] statusCode: ${response.statusCode}');
    _log('[JioSaavnService] body: ${response.body}');
  }

  List<dynamic> _extractResults(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return const [];

    final v1 = decoded['data']?['results'];
    if (v1 is List) return v1;

    final v2 = decoded['data']?['data']?['results'];
    if (v2 is List) return v2;

    final v3 = decoded['results'];
    if (v3 is List) return v3;

    return const [];
  }

  Future<List<SongModel>> searchSongs(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    final normalizedQuery = query.trim().toLowerCase();
    final cacheKey = '$normalizedQuery::$limit';

    if (_searchCache.containsKey(cacheKey)) {
      _log('[JioSaavnService] cache hit for "$query"');
      return _searchCache[cacheKey]!;
    }

    final inflight = _inflightSearch[cacheKey];
    if (inflight != null) {
      _log('[JioSaavnService] in-flight dedupe for "$query"');
      return inflight;
    }

    final future = _searchSongsInternal(query, limit: limit, cacheKey: cacheKey);
    _inflightSearch[cacheKey] = future;
    try {
      return await future;
    } finally {
      _inflightSearch.remove(cacheKey);
    }
  }

  Future<List<SongModel>> _searchSongsInternal(
    String query, {
    required int limit,
    required String cacheKey,
  }) async {
    if (_normalizedBaseUrl.isEmpty) {
      _log('JioSaavn searchSongs skipped: JIOSAAVN_BASE_URL is not configured.');
      _setError(JioSaavnErrorType.configMissing,
          'JIOSAAVN_BASE_URL is not configured');
      return [];
    }
    _clearError();

    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final url = Uri.parse(
          '$_normalizedBaseUrl/api/search/songs'
          '?query=${Uri.encodeComponent(query)}&limit=$limit',
        );
        final res =
            await http.get(url).timeout(const Duration(seconds: 10));
        _debugResponse(endpoint: '/api/search/songs', response: res, query: query);

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          _log('[JioSaavnService] parsed JSON: $data');

          final results = _extractResults(data);
          _log('[JioSaavnService] results length: ${results.length}');

          final songs = results
              .whereType<Map<String, dynamic>>()
              .map(SongModel.fromJioSaavn)
              .where((s) => (s.audioUrl ?? '').trim().isNotEmpty)
              .toList();

          _log('[JioSaavnService] mapped songs length: ${songs.length}');
          _clearError();
          _searchCache[cacheKey] = songs;
          return songs;
        }

        _setError(
          JioSaavnErrorType.httpError,
          'HTTP ${res.statusCode} for "$query"',
          statusCode: res.statusCode,
        );
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('TimeoutException')) {
          _setError(JioSaavnErrorType.timeout,
              'Timeout while searching "$query"');
        } else if (msg.contains('FormatException')) {
          _setError(JioSaavnErrorType.parseError,
              'JSON parse failed for "$query": $e');
        } else {
          _setError(JioSaavnErrorType.unknown,
              'Exception while searching "$query": $e');
        }
      }

      if (attempt < 2) {
        _log('[JioSaavnService] retrying searchSongs "$query" attempt=${attempt + 1}');
      }
    }

    return [];
  }

  Future<List<AlbumModel>> searchAlbums(String query,
      {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    if (_normalizedBaseUrl.isEmpty) {
      _log('JioSaavn searchAlbums skipped: JIOSAAVN_BASE_URL is not configured.');
      return [];
    }
    try {
      final url = Uri.parse(
        '$_normalizedBaseUrl/api/search/albums'
        '?query=${Uri.encodeComponent(query)}&limit=$limit',
      );
      final res =
          await http.get(url).timeout(const Duration(seconds: 10));
      _debugResponse(endpoint: '/api/search/albums', response: res, query: query);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _log('[JioSaavnService] parsed JSON: $data');
        final results = _extractResults(data);
        _log('[JioSaavnService] results length: ${results.length}');
        return results
            .map((e) => AlbumModel.fromJioSaavn(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  Future<List<ArtistModel>> searchArtists(String query,
      {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    if (_normalizedBaseUrl.isEmpty) {
      _log(
          'JioSaavn searchArtists skipped: JIOSAAVN_BASE_URL is not configured.');
      return [];
    }
    try {
      final url = Uri.parse(
        '$_normalizedBaseUrl/api/search/artists'
        '?query=${Uri.encodeComponent(query)}&limit=$limit',
      );
      final res =
          await http.get(url).timeout(const Duration(seconds: 10));
      _debugResponse(endpoint: '/api/search/artists', response: res, query: query);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _log('[JioSaavnService] parsed JSON: $data');
        final results = _extractResults(data);
        _log('[JioSaavnService] results length: ${results.length}');
        return results
            .map((e) => ArtistModel.fromJioSaavn(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // ignore
    }
    return [];
  }
}