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

  // ── Load home data — pulls from ALL sources via MusicSourceManager ───────
  Future<void> loadHomeData() async {
    _loadingTrending = true;
    _loadingNew = true;
    notifyListeners();

    try {
      final home = await _manager.loadHomeData();
      _trending   = home.trending;
      _newRelease = home.newReleases;
    } catch (e) {
      debugPrint('MusicSourceManager.loadHomeData failed, falling back: $e');
      final results = await Future.wait([
        _jiosaavn.searchSongs('trending songs india', limit: 20),
        _jiosaavn.searchSongs('new releases', limit: 20),
      ]);
      _trending   = results[0];
      _newRelease = results[1];
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
    _loadingSearch = true;
    notifyListeners();

    try {
      final results = await _manager.searchAll(query, limitPerType: 30);
      _searchResults = results.songs;
    } catch (e) {
      debugPrint('MusicSourceManager.search failed, falling back: $e');
      _searchResults = await _jiosaavn.searchSongs(query, limit: 30);
      if (_searchResults.isEmpty) {
        _searchError = 'Unable to search right now. Please check your connection.';
      }
    }

    _loadingSearch = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _debounce?.cancel();
    _searchQuery = null;
    _searchError = null;
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
