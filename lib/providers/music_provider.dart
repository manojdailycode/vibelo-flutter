import 'dart:async';
import 'package:flutter/foundation.dart';
import '../providers/music_source_manager.dart';
import '../services/jiosaavn_service.dart';
import '../models/song_model.dart';

class MusicProvider extends ChangeNotifier {
  final _manager = MusicSourceManager.instance;
  final _jiosaavn = JioSaavnService();

  List<SongModel> _trending   = [];
  List<SongModel> _newRelease = [];
  List<SongModel> _searchResults = [];
  List<SongModel> _genreSongs = [];

  bool _loadingTrending   = false;
  bool _loadingNew        = false;
  bool _loadingSearch     = false;
  bool _loadingGenre      = false;
  String? _searchQuery;
  String? _searchError;
  String? _jioLastError;
  Timer? _debounce;

  List<SongModel> get trending      => _trending;
  List<SongModel> get newReleases   => _newRelease;
  List<SongModel> get searchResults => _searchResults;
  List<SongModel> get genreSongs    => _genreSongs;

  bool get loadingTrending => _loadingTrending;
  bool get loadingNew      => _loadingNew;
  bool get loadingSearch   => _loadingSearch;
  bool get loadingGenre    => _loadingGenre;
  String? get searchQuery  => _searchQuery;
  String? get searchError  => _searchError;
  String? get jioLastError => _jioLastError;

  // ── Load home data — pulls from ALL sources via MusicSourceManager ───────
  Future<void> loadHomeData() async {
    debugPrint('[MusicProvider] Loading home data...');
    _loadingTrending = true;
    _loadingNew = true;
    notifyListeners();

    try {
      debugPrint('[MusicProvider] Fetching trending and new releases from MusicSourceManager...');
      final home = await _manager.loadHomeData();
      _trending   = home.trending;
      _newRelease = home.newReleases;
      debugPrint('[MusicProvider] ✓ Loaded: ${_trending.length} trending, ${_newRelease.length} new releases');
    } catch (e) {
      debugPrint('[MusicProvider] ✗ MusicSourceManager failed, falling back to JioSaavn: $e');
      
      final results = await Future.wait([
        _jiosaavn.searchSongs('trending songs india', limit: 20),
        _jiosaavn.searchSongs('new releases', limit: 20),
      ]);
      _trending   = results[0];
      _newRelease = results[1];
      debugPrint('[MusicProvider] Fallback: ${_trending.length} trending, ${_newRelease.length} new releases');
    }

    _loadingTrending = false;
    _loadingNew = false;
    notifyListeners();
  }

  // ── Search — pulls from ALL sources, deduplicates ────────────────────────
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchQuery = null;
      notifyListeners();
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      await _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    _searchQuery = query;
    _searchError = null;
    _jioLastError = null;
    _loadingSearch = true;
    notifyListeners();
    debugPrint('[MusicProvider.Search] Starting search for: "$query"');

    try {
      debugPrint('[MusicProvider.Search] Calling MusicSourceManager.searchAll...');
      final results = await _manager.searchAll(query, limitPerType: 30);
      _searchResults = results.songs;
      debugPrint('[MusicProvider.Search] ✓ Got ${_searchResults.length} songs from MusicSourceManager');
      
      // Capture error info from JioSaavn for debugging
      if (_jiosaavn.lastError != null) {
        _jioLastError = '${_jiosaavn.lastError}: ${_jiosaavn.lastErrorMessage}';
        debugPrint('[MusicProvider.Search] JioSaavn had error (but fallback succeeded): $_jioLastError');
      }
    } catch (e) {
      debugPrint('[MusicProvider.Search] ✗ MusicSourceManager failed: $e');
      debugPrint('[MusicProvider.Search] Trying direct JioSaavn search...');
      
      _searchResults = await _jiosaavn.searchSongs(query, limit: 30);
      debugPrint('[MusicProvider.Search] JioSaavn direct: ${_searchResults.length} songs');
      
      if (_searchResults.isEmpty) {
        if (_jiosaavn.lastError != null) {
          _searchError = 'JioSaavn error (${_jiosaavn.lastError}). Unable to search right now.';
          _jioLastError = '${_jiosaavn.lastError}: ${_jiosaavn.lastErrorMessage}';
          debugPrint('[MusicProvider.Search] ✗ No results and error: $_searchError');
        } else {
          _searchError = 'Unable to search right now. Please check your connection.';
          debugPrint('[MusicProvider.Search] ✗ No results from JioSaavn');
        }
      }
    }

    _loadingSearch = false;
    notifyListeners();
    debugPrint('[MusicProvider.Search] Search complete. Total results: ${_searchResults.length}');
  }

  void clearSearch() {
    _searchResults = [];
    _debounce?.cancel();
    _searchQuery = null;
    _searchError = null;
    _jioLastError = null;
    notifyListeners();
  }

  // ── Load by Genre — JioSaavn provides the most reliable Indian tags ───────
  Future<void> loadGenre(String genre) async {
    _loadingGenre = true;
    _searchError = null;
    notifyListeners();
    _genreSongs = await getSongsByGenre(genre, limit: 40);
    _loadingGenre = false;
    notifyListeners();
  }

  Future<List<SongModel>> getTrending({int limit = 20}) async {
    return _manager.getTrending(limit: limit);
  }

  Future<List<SongModel>> getNewReleases({int limit = 20}) async {
    return _manager.getNewReleases(limit: limit);
  }

  Future<List<SongModel>> getSongsByGenre(String genre, {int limit = 40}) async {
    if (genre.trim().isEmpty) return [];
    final results = await _jiosaavn.searchSongs(genre, limit: limit);
    return results;
  }

  // ── Mood — JioSaavn-backed mood search ──────────────────────────────────
  Future<List<SongModel>> getMoodSongs(String mood) async {
    return _jiosaavn.searchSongs(mood, limit: 40);
  }
}
