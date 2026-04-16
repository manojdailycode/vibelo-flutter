import 'dart:async';
import 'package:flutter/foundation.dart';
import '../providers/music_source_manager.dart';
import '../services/jamendo_service.dart';
import '../models/song_model.dart';

class MusicProvider extends ChangeNotifier {
  final _manager = MusicSourceManager.instance;
  final _jamendo = JamendoService();

  List<SongModel> _trending   = [];
  List<SongModel> _newRelease = [];
  List<SongModel> _searchResults = [];
  List<SongModel> _genreSongs = [];

  bool _loadingTrending   = false;
  bool _loadingNew        = false;
  bool _loadingSearch     = false;
  bool _loadingGenre      = false;
  String? _searchQuery;
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
      // Fallback to Jamendo only if the manager fails
      debugPrint('MusicSourceManager.loadHomeData failed, falling back: $e');
      final results = await Future.wait([
        _jamendo.getTrendingSongs(limit: 20),
        _jamendo.getNewReleases(limit: 20),
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
    _loadingSearch = true;
    notifyListeners();

    try {
      final results = await _manager.searchAll(query, limitPerType: 30);
      _searchResults = results.songs;
    } catch (e) {
      debugPrint('MusicSourceManager.search failed, falling back: $e');
      _searchResults = await _jamendo.searchSongs(query);
    }

    _loadingSearch = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _debounce?.cancel();
    _searchQuery = null;
    notifyListeners();
  }

  // ── Load by Genre — Jamendo tags are most reliable for genre ─────────────
  Future<void> loadGenre(String genre) async {
    _loadingGenre = true;
    notifyListeners();
    _genreSongs = await _jamendo.getSongsByGenre(genre);
    _loadingGenre = false;
    notifyListeners();
  }

  // ── Mood — Jamendo mood tags ──────────────────────────────────────────────
  Future<List<SongModel>> getMoodSongs(String mood) async {
    return _jamendo.getMoodPlaylist(mood);
  }
}
