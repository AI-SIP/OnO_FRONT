import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../Config/AppConfig.dart';
import '../Provider/ProblemsProvider.dart';
import 'AppleAuthService.dart';
import 'GoogleAuthService.dart';

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
    final response = await googleAuthService.signInWithGoogle();
    await storage.write(key: 'loginMethod', value: 'google');
    await setAccessToken(response['accessToken']);
    await setRefreshToken(response['refreshToken']);
    fetchUserInfo();
    notifyListeners();
  }

  // Apple 로그인 함수
  Future<void> signInWithApple(BuildContext context) async {
    final response  = await appleAuthService.signInWithApple(context);
    await storage.write(key: 'loginMethod', value: 'apple');
    await setAccessToken(response['accessToken']);
    await setRefreshToken(response['refreshToken']);
    fetchUserInfo();
    notifyListeners();
  }

  Future<void> setAccessToken(String accessToken) async {
    await storage.write(key: 'accessToken', value: accessToken);
  }

  Future<String?> getAccessToken() async {
    String? accessToken = await storage.read(key: 'accessToken');

    if (accessToken == null) {
      log('Access token is not available.');
      return null;
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/auth/verifyAccessToken');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 401) {
      log('Access token is invalid or expired, trying to refresh...');
      await refreshAccessToken();
      accessToken = await storage.read(key: 'accessToken');
    }

    return accessToken;
  }

  Future<void> setRefreshToken(String refreshToken) async{
    await storage.write(key: 'refreshToken', value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return await storage.read(key: 'refreshToken');
  }

  Future<void> fetchUserInfo() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) {
      throw Exception("Access token is not available");
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/user');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
      _userId = responseBody['userId'];
      _userName = responseBody['userName'];
      _userEmail = responseBody['userEmail'];
      _isLoggedIn = true;

      await problemsProvider.fetchProblems();
    } else {
      _isLoggedIn = false;
    }

    notifyListeners();
  }

  Future<bool> refreshAccessToken() async {
    try {
      String? refreshToken = await storage.read(key: 'refreshToken');
      if (refreshToken == null) {
        log('No refresh token available.');
        return false;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        await storage.write(key: 'accessToken', value: data['accessToken']);
        log('Access token refreshed.');
        return true;
      } else {
        log('Failed to refresh token. Logging out.');
        return false;
      }
    } catch (e) {
      log('Error refreshing token: $e');
      return false;
    }
  }

  Future<void> autoLogin() async {
    String? refreshToken = await storage.read(key: 'refreshToken');
    if(refreshToken == null){
      _isLoggedIn = false;
      notifyListeners();
    } else {
      fetchUserInfo();
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
      final token = await getAccessToken();
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
        _userId = 0;
        _isLoggedIn = false;
        _userName = '';
        _userEmail = '';
        await storage.deleteAll();
        notifyListeners();
        log('Account deletion Success!');
      } else {
        log('Failed to delete account: ${response.reasonPhrase}');
        throw Exception("Failed to delete account");
      }
    } catch (error) {
      log('Account deletion error: $error');
    }
  }
}
