import 'package:flutter/foundation.dart';
import '../services/jamendo_service.dart';
import '../models/song_model.dart';

class MusicProvider extends ChangeNotifier {
  final JamendoService _api = JamendoService();

  List<SongModel> _trending   = [];
  List<SongModel> _newRelease = [];
  List<SongModel> _searchResults = [];
  List<SongModel> _genreSongs = [];

  bool _loadingTrending   = false;
  bool _loadingNew        = false;
  bool _loadingSearch     = false;
  bool _loadingGenre      = false;
  String? _searchQuery;

  List<SongModel> get trending     => _trending;
  List<SongModel> get newReleases  => _newRelease;
  List<SongModel> get searchResults=> _searchResults;
  List<SongModel> get genreSongs   => _genreSongs;

  bool get loadingTrending => _loadingTrending;
  bool get loadingNew      => _loadingNew;
  bool get loadingSearch   => _loadingSearch;
  bool get loadingGenre    => _loadingGenre;
  String? get searchQuery  => _searchQuery;

  // ── Load home data ───────────────────────────────
  Future<void> loadHomeData() async {
    _loadingTrending = true;
    _loadingNew = true;
    notifyListeners();

    final results = await Future.wait([
      _api.getTrendingSongs(limit: 20),
      _api.getNewReleases(limit: 20),
    ]);

    _trending   = results[0];
    _newRelease = results[1];
    _loadingTrending = false;
    _loadingNew = false;
    notifyListeners();
  }

  // ── Search ───────────────────────────────────────
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
    _searchResults = await _api.searchSongs(query);
    _loadingSearch = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _searchQuery = null;
    notifyListeners();
  }

  // ── Load by Genre ────────────────────────────────
  Future<void> loadGenre(String genre) async {
    _loadingGenre = true;
    notifyListeners();
    _genreSongs = await _api.getSongsByGenre(genre);
    _loadingGenre = false;
    notifyListeners();
  }

  // ── Load Mood ────────────────────────────────────
  Future<List<SongModel>> getMoodSongs(String mood) async {
    return _api.getMoodPlaylist(mood);
  }
}
