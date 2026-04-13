import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  User? _firebaseUser;
  UserModel? _user;
  bool _loading = false;
  String? _error;

  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isGuest => _firebaseUser?.isAnonymous ?? false;
  bool get isPremium => _user?.isPremiumActive ?? false;

  AuthProvider() {
    _service.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    _firebaseUser = user;
    if (user != null && !user.isAnonymous) {
      _user = await _service.fetchUser(user.uid);
    } else {
      _user = null;
    }
    notifyListeners();
  }

  Future<bool> signUpWithEmail(String name, String email, String pass) async {
    _setLoading(true);
    try {
      await _service.signUpWithEmail(name: name, email: email, password: pass);
      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithEmail(String email, String pass) async {
    _setLoading(true);
    try {
      await _service.signInWithEmail(email: email, password: pass);
      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final result = await _service.signInWithGoogle();
      _clearError();
      return result != null;
    } catch (e) {
      _setError('Google sign-in failed. Try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInAsGuest() async {
    _setLoading(true);
    try {
      await _service.signInAsGuest();
      _clearError();
      return true;
    } catch (e) {
      _setError('Could not continue as guest.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    _user = null;
    _firebaseUser = null;
    notifyListeners();
  }

  Future<void> toggleLike(String songId) async {
    if (_user == null) return;
    final liked = _user!.likedSongIds.contains(songId);
    final updated = List<String>.from(_user!.likedSongIds);
    if (liked) {
      updated.remove(songId);
    } else {
      updated.add(songId);
    }
    _user = _user!.copyWith(likedSongIds: updated);
    notifyListeners();
    await _service.toggleLike(_user!.uid, songId, !liked);
  }

  bool isLiked(String songId) => _user?.likedSongIds.contains(songId) ?? false;

  void _setLoading(bool v) { _loading = v; notifyListeners(); }
  void _setError(String msg) { _error = msg; notifyListeners(); }
  void _clearError() { _error = null; }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'This email is already registered.';
      case 'wrong-password': return 'Incorrect password.';
      case 'user-not-found': return 'No account found with this email.';
      case 'invalid-email': return 'Invalid email address.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      default: return 'Something went wrong. Please try again.';
    }
  }
}
