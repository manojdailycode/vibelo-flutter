// ─────────────────────────────────────────────────────────────────────────────
//  music_provider.dart  —  updated to use MusicSourceManager
//  All sources (Deezer, Audius, YouTube, Spotify, Jamendo) handled here
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import '../services/music_source_manager.dart';
import '../models/song_model.dart';

class MusicProvider extends ChangeNotifier {
  final _mgr = MusicSourceManager.instance;

  List<SongModel> _trending    = [];
  List<SongModel> _newRelease  = [];
  List<SongModel> _searchResults = [];
  List<SongModel> _languageSongs = [];

  bool _loadingTrending  = false;
  bool _loadingNew       = false;
  bool _loadingSearch    = false;
  bool _loadingLanguage  = false;

  String? _searchQuery;
  MusicLanguage _activeLanguage = MusicLanguage.all;

  List<SongModel> get trending      => _trending;
  List<SongModel> get newReleases   => _newRelease;
  List<SongModel> get searchResults => _searchResults;
  List<SongModel> get languageSongs => _languageSongs;

  bool get loadingTrending  => _loadingTrending;
  bool get loadingNew       => _loadingNew;
  bool get loadingSearch    => _loadingSearch;
  bool get loadingLanguage  => _loadingLanguage;

  String?         get searchQuery    => _searchQuery;
  MusicLanguage   get activeLanguage => _activeLanguage;

  // ── Home data ─────────────────────────────────────────────────────────────
  Future<void> loadHomeData() async {
    _loadingTrending = true;
    _loadingNew = true;
    notifyListeners();

    try {
      final data = await _mgr.loadHomeData();
      _trending   = data.trending;
      _newRelease = data.newReleases;
    } catch (e) {
      debugPrint('loadHomeData error: $e');
    }

    _loadingTrending = false;
    _loadingNew = false;
    notifyListeners();
  }

  // ── Search ────────────────────────────────────────────────────────────────
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchQuery = null;
      notifyListeners();
      return;
    }

    _searchQuery = query;
    _loadingSearch = true;
    notifyListeners();

    _searchResults = await _mgr.search(query);

    _loadingSearch = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _searchQuery = null;
    notifyListeners();
  }

  // ── Language songs ────────────────────────────────────────────────────────
  Future<void> loadByLanguage(MusicLanguage language) async {
    _activeLanguage = language;
    _loadingLanguage = true;
    notifyListeners();

    _languageSongs = await _mgr.getSongsByLanguage(language);

    _loadingLanguage = false;
    notifyListeners();
  }

  // ── Genre (kept for backward compat with home_screen.dart) ───────────────
  Future<void> loadGenre(String genre) async {
    _loadingLanguage = true;
    notifyListeners();

    _languageSongs = await _mgr.search(genre, limit: 25);

    _loadingLanguage = false;
    notifyListeners();
  }

  // ── Mood songs (kept for backward compat) ────────────────────────────────
  Future<List<SongModel>> getMoodSongs(String mood) =>
      _mgr.search(mood, limit: 20);
}
