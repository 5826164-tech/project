import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthState { idle, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = AuthState.idle;
  String _errorMessage = '';
  AppUser? _user;

  AuthProvider() {
    _init();
  }

  AuthState get state => _state;
  String get errorMessage => _errorMessage;
  AppUser? get user => _user;

  void _init() {
    try {
      _authService.authStateChanges.listen((User? user) {
        if (user != null) {
          _user = AppUser(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
          );
          _state = AuthState.authenticated;
        } else {
          _user = null;
          _state = AuthState.unauthenticated;
        }
        notifyListeners();
      });
    } catch (e) {
      _user = null;
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      if (_authService.auth == null) {
        if (email.trim().isNotEmpty && password.trim().isNotEmpty) {
          _user = AppUser(
            uid: 'demo-user-id',
            email: email.trim(),
            displayName: email.split('@').first.isNotEmpty ? email.split('@').first : 'Demo User',
          );
          _state = AuthState.authenticated;
          _errorMessage = '';
          notifyListeners();
          return true;
        }

        _state = AuthState.error;
        _errorMessage = 'Enter a demo email and password.';
        notifyListeners();
        return false;
      }

      await _authService.login(email, password);
      _errorMessage = '';
      return true;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _state = AuthState.loading;
    notifyListeners();
    try {
      if (_authService.auth == null) {
        _user = AppUser(
          uid: 'demo-user-id',
          email: email.trim(),
          displayName: name.isNotEmpty ? name : 'Demo User',
        );
        _state = AuthState.authenticated;
        _errorMessage = '';
        notifyListeners();
        return true;
      }

      await _authService.register(email, password, name);
      _errorMessage = '';
      return true;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
