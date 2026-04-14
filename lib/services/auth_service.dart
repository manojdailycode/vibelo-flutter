import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✓ Optimization: Simple in-memory user cache with TTL
  final Map<String, UserModel> _userCache = {};
  final Map<String, DateTime> _userCacheTimes = {};
  static const _cacheDuration = Duration(hours: 1);

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isGuest => _auth.currentUser?.isAnonymous ?? false;

  // ── Email / Password Sign Up ─────────────────────
  Future<UserCredential?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(name);
    await _saveUserToFirestore(cred.user!, name);
    return cred;
  }

  // ── Email / Password Sign In ─────────────────────
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ── Google Sign In ───────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    await _saveUserToFirestore(
      cred.user!,
      cred.user!.displayName ?? 'Vibelo User',
    );
    return cred;
  }

  // ── Guest / Anonymous ────────────────────────────
  Future<UserCredential?> signInAsGuest() async {
    return await _auth.signInAnonymously();
  }

  // ── Sign Out ─────────────────────────────────────
  Future<void> signOut() async {
    _userCache.clear();
    _userCacheTimes.clear();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Fetch User Data ──────────────────────────────
  Future<UserModel?> fetchUser(String uid) async {
    // ✓ Optimized: Check cache first (valid for 1 hour)
    if (_userCache.containsKey(uid)) {
      final cacheTime = _userCacheTimes[uid];
      if (cacheTime != null && 
          DateTime.now().difference(cacheTime) < _cacheDuration) {
        return _userCache[uid];
      }
    }
    
    // Cache miss or expired - fetch from Firestore
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    
    final user = UserModel.fromMap(doc.data()!, uid);
    
    // Update cache
    _userCache[uid] = user;
    _userCacheTimes[uid] = DateTime.now();
    
    return user;
  }

  // ── Update User ──────────────────────────────────
  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(
          user.toMap(),
          SetOptions(merge: true),
        );
  }

  // ── Toggle Like ──────────────────────────────────
  Future<void> toggleLike(String uid, String songId, bool liked) async {
    final ref = _db.collection('users').doc(uid);
    if (liked) {
      await ref.update({
        'likedSongIds': FieldValue.arrayUnion([songId])
      });
    } else {
      await ref.update({
        'likedSongIds': FieldValue.arrayRemove([songId])
      });
    }
  }

  // ── Private: Save to Firestore ───────────────────
  Future<void> _saveUserToFirestore(User user, String name) async {
    final ref = _db.collection('users').doc(user.uid);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'name': name,
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'isPremium': false,
        'likedSongIds': [],
        'followedArtists': [],
        'language': 'en',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
