import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  FirebaseAuth? _auth;

  AuthService() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _auth = FirebaseAuth.instance;
      }
    } catch (_) {
      _auth = null;
    }
  }

  FirebaseAuth? get auth => _auth;

  /// Register with email and password.
  Future<UserCredential> register(String email, String password, String name) async {
    if (_auth == null) {
      throw Exception('Firebase is not configured for this app.');
    }

    try {
      UserCredential userCredential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(name);
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with email and password.
  Future<UserCredential> login(String email, String password) async {
    if (_auth == null) {
      throw Exception('Firebase is not configured for this app.');
    }

    try {
      return await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out.
  Future<void> logout() async {
    if (_auth == null) return;
    await _auth!.signOut();
  }

  /// Auth state stream.
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? Stream.value(null);

  /// Current user.
  User? get currentUser => _auth?.currentUser;
}
