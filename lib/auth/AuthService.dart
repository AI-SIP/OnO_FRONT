import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService with ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _googleUser;
  bool _isLoggedIn = false;

  GoogleSignInAccount? get googleUser => _googleUser;
  bool get isLoggedIn => _isLoggedIn;

  // Google 로그인 함수
  Future<void> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        _googleUser = account;
        _isLoggedIn = true;
        notifyListeners();
      }
    } catch (error) {
      print('Google sign-in error: $error');
    }
  }

  // Apple 로그인 함수
  Future<void> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (appleCredential != null) {
        _isLoggedIn = true;
        notifyListeners();
      }
    } catch (error) {
      print('Apple sign-in error: $error');
    }
  }

  // 로그아웃 함수
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _googleUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}