import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/playlist_service.dart';
import 'auth_provider.dart';
import '../models/song_model.dart';

class PlaylistProvider extends ChangeNotifier {
  AuthProvider _authProvider;
  final _playlistService = PlaylistService();

  List<Map<String, dynamic>> _playlists = [];
  bool _loadingPlaylists = false;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;

  List<Map<String, dynamic>> get playlists => _playlists;
  bool get isLoading => _loadingPlaylists;

  PlaylistProvider({required AuthProvider authProvider})
      : _authProvider = authProvider {
    // Listen to auth changes to reload playlists on login/logout
    _authProvider.addListener(loadPlaylists);
    loadPlaylists();
  }

  /// Updates the [AuthProvider] dependency and reloads data if it has changed.
  /// This is called by the [ChangeNotifierProxyProvider] in main.dart.
  void updateAuthProvider(AuthProvider newProvider) {
    if (_authProvider != newProvider) {
      _authProvider.removeListener(loadPlaylists);
      _authProvider = newProvider;
      _authProvider.addListener(loadPlaylists);
      loadPlaylists(forceRefresh: true);
    }
  }

  Future<void> loadPlaylists({bool forceRefresh = false}) async {
    if (_authProvider.isGuest || _authProvider.user == null) {
      _playlists = [];
      notifyListeners();
      return;
    }
    if (forceRefresh) {
      _playlists = [];
      _lastDoc = null;
      _hasMore = true;
    }

    if (_loadingPlaylists || !_hasMore) return;

    _loadingPlaylists = true;
    notifyListeners();

    final list = await _playlistService.getPlaylists(_authProvider.user!.uid, startAfter: _lastDoc);
    
    // In a real scenario, you would get the last document for pagination
    // For now, we just add the list.
    _playlists.addAll(list);
    _loadingPlaylists = false;
    notifyListeners();
  }

  Future<String?> createPlaylist(String name, String emoji) async {
    if (_authProvider.user == null) return null;
    final newId = await _playlistService.createPlaylist(
        userId: _authProvider.user!.uid, name: name, emoji: emoji);
    if (newId != null) {
      await loadPlaylists(forceRefresh: true);
    }
    return newId;
  }

  Future<void> deletePlaylist(String playlistId) async {
    if (_authProvider.user == null) return;
    await _playlistService.deletePlaylist(_authProvider.user!.uid, playlistId);
    _playlists.removeWhere((p) => p['id'] == playlistId);
    notifyListeners();
  }

  Future<void> addSongToPlaylist(String playlistId, SongModel song) async {
    if (_authProvider.user == null) return;
    final success = await _playlistService.addSongToPlaylist(
        userId: _authProvider.user!.uid, playlistId: playlistId, song: song);
    if (success) {
      await loadPlaylists(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(loadPlaylists);
    super.dispose();
  }
}