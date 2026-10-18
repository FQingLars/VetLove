import 'package:flutter/foundation.dart';

import '../models/trade.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Состояние аккаунта пользователя.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service);

  final AuthService _service;

  AuthStatus status = AuthStatus.unknown;
  UserProfile? profile;
  String? error;

  bool get isLoggedIn => status == AuthStatus.authenticated;

  void listen() {
    _service.authStateChanges.listen((user) async {
      if (user == null) {
        status = AuthStatus.unauthenticated;
        profile = null;
      } else {
        status = AuthStatus.authenticated;
        profile = await _service.profile(user.uid);
      }
      notifyListeners();
    });
  }

  Future<bool> signInEmail(String email, String password) =>
      _wrap(() => _service.signInEmail(email, password));

  Future<bool> signUpEmail(String email, String password, String nickname) =>
      _wrap(() => _service.signUpEmail(email, password, nickname));

  Future<bool> signInWithGoogle() => _wrap(_service.signInWithGoogle);

  Future<bool> signInWithApple() => _wrap(_service.signInWithApple);

  Future<void> signOut() async {
    await _service.signOut();
    status = AuthStatus.unauthenticated;
    profile = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final u = _service.currentUser;
    if (u != null) {
      profile = await _service.profile(u.uid);
      notifyListeners();
    }
  }

  Future<bool> _wrap(Future<dynamic> Function() action) async {
    error = null;
    try {
      await action();
      status = AuthStatus.authenticated;
      final u = _service.currentUser;
      if (u != null) profile = await _service.profile(u.uid);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
