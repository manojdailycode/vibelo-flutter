import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/song_model.dart';

class PlaylistService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ── Create playlist ──────────────────────────────
  Future<String?> createPlaylist({
    required String userId,
    required String name,
    String? emoji,
  }) async {
    try {
      final id = _uuid.v4();
      await _db
          .collection('users')
          .doc(userId)
          .collection('playlists')
          .doc(id)
          .set({
        'id': id,
        'name': name,
        'emoji': emoji ?? '🎵',
        'songIds': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return id;
    } catch (e) {
      return null;
    }
  }

  // ── Get user playlists ───────────────────────────
  Future<List<Map<String, dynamic>>> getPlaylists(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      // ✓ Optimized: Added pagination to handle 100+ playlists
      var query = _db
          .collection('users')
          .doc(userId)
          .collection('playlists')
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      final snap = await query.get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      return [];
    }
  }

  // ── Add song to playlist ─────────────────────────
  Future<bool> addSongToPlaylist({
    required String userId,
    required String playlistId,
    required SongModel song,
  }) async {
    try {
      final ref = _db
          .collection('users')
          .doc(userId)
          .collection('playlists')
          .doc(playlistId);

      // ✓ Optimized: Use atomic arrayUnion instead of fetch-modify-write
      // This is a single Firestore write (not two), prevents race conditions
      final songData = {
        'id': song.id,
        'title': song.title,
        'artist': song.artist,
        'audioUrl': song.audioUrl,
        'imageUrl': song.imageUrl,
        'duration': song.duration,
      };

      await ref.update({
        'songs': FieldValue.arrayUnion([songData])
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Delete playlist ──────────────────────────────
  Future<void> deletePlaylist(String userId, String playlistId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('playlists')
        .doc(playlistId)
        .delete();
  }
}
