import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mvp_front/Service/AppleAuthService.dart';
import 'package:mvp_front/Service/GoogleAuthService.dart';
import 'package:http/http.dart' as http;
import '../Config/AppConfig.dart';
import '../Provider/ProblemsProvider.dart';

class AuthService with ChangeNotifier {
  final storage = const FlutterSecureStorage();
  final ProblemsProvider problemsProvider;

  AuthService(this.problemsProvider);

  bool _isLoggedIn = false;
  int _userId = 0;
  String _userName = '';
  String _userEmail = '';

  bool get isLoggedIn => _isLoggedIn;
  int get userId => _userId;
  String get userName => _userName;
  String get userEmail => _userEmail;

  final AppleAuthService appleAuthService = AppleAuthService();
  final GoogleAuthService googleAuthService = GoogleAuthService();

  // Google 로그인 함수(앱 처음 설치하고 구글 로그인 버튼 누르면 실행)
  Future<void> signInWithGoogle() async {
    final jwtToken = await googleAuthService.signInWithGoogle();
    if (jwtToken != null) {
      await storage.write(key: 'loginMethod', value: 'google');
      await setJwtToken(jwtToken);
      fetchUserInfo();
      notifyListeners();
    }
  }

  // Apple 로그인 함수
  Future<void> signInWithApple(BuildContext context) async {
    final jwtToken = await appleAuthService.signInWithApple(context);
    await storage.write(key: 'loginMethod', value: 'apple');
    await setJwtToken(jwtToken);
    fetchUserInfo();
    notifyListeners();
  }

  Future<void> setJwtToken(String token) async {
    await storage.write(key: 'jwtToken', value: token);
  }

  Future<String?> getJwtToken() async {
    return await storage.read(key: 'jwtToken');
  }

  Future<void> fetchUserInfo() async {
    final token = await getJwtToken();
    if (token == null) {
      throw Exception("JWT token is not available");
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/user');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
      _userId = responseBody['userId'];
      _userName = responseBody['userName'];
      _userEmail = responseBody['userEmail'];
      _isLoggedIn = true;
    } else {
      _isLoggedIn = false;
    }

    notifyListeners();
  }

  Future<void> autoLogin() async {
    String? token = await getJwtToken();
    if (token != null) {
      try {
        await fetchUserInfo();
      } catch (e) {
        log('Auto login failed: $e');
      }
    } else {
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    if (_userId != 0 && _userName.isNotEmpty && _userEmail.isNotEmpty) {
      return {
        'userId': _userId,
        'userName': _userName,
        'userEmail': _userEmail,
      };
    } else {
      throw Exception('No user info available');
    }
  }

  // 로그아웃 함수
  Future<void> signOut() async {
    try {
      String? loginMethod = await storage.read(key: 'loginMethod');
      if (loginMethod == 'google') {
        googleAuthService.logoutGoogleSignIn();
      }
      _userId = 0;
      _isLoggedIn = false;
      _userName = '';
      _userEmail = '';
      await storage.deleteAll();
      notifyListeners(); // 리스너들에게 상태 변경을 알림
    } catch (error) {
      log('Error signing out: $error');
      throw Exception('Failed to sign out');
    }
  }

  // 회원 탈퇴 함수
  Future<void> deleteAccount() async {
    String? loginMethod = await storage.read(key: 'loginMethod');
    if (loginMethod == 'google') {
      // 구글 회원 탈퇴 로직
      await googleAuthService.revokeGoogleSignIn();
    } else if (loginMethod == 'apple') {
      // 애플 회원 탈퇴 로직
      await appleAuthService.revokeSignInWithApple();
    } else {
      throw Exception("Unknown login method");
    }

    // 서버에서 사용자 계정 삭제
    try {
      final token = await getJwtToken();
      if (token == null) {
        throw Exception("JWT token is not available");
      }

      final url = Uri.parse('${AppConfig.baseUrl}/api/user');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        log('Account deletion Success!');
        await signOut(); // 로그아웃 처리
      } else {
        log('Failed to delete account: ${response.reasonPhrase}');
        throw Exception("Failed to delete account");
      }
    } catch (error) {
      log('Account deletion error: $error');
    }
  }
}
