import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ono/Model/LoginStatus.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Service/Auth/GuestAuthService.dart';
import '../../Config/AppConfig.dart';
import '../../Provider/ProblemsProvider.dart';
import '../../Provider/TokenProvider.dart';
import 'AppleAuthService.dart';
import 'GoogleAuthService.dart';

class AuthService with ChangeNotifier {
  final storage = const FlutterSecureStorage();
  final ProblemsProvider problemsProvider;
  final FoldersProvider foldersProvider;
  final TokenProvider tokenProvider = TokenProvider();

  AuthService(this.problemsProvider, this.foldersProvider);

  LoginStatus _isLoggedIn = LoginStatus.wating;
  int _userId = 0;
  String _userName = '';
  String _userEmail = '';

  LoginStatus get isLoggedIn => _isLoggedIn;
  int get userId => _userId;
  String get userName => _userName;
  String get userEmail => _userEmail;

  final GuestAuthService guestAuthService = GuestAuthService();
  final AppleAuthService appleAuthService = AppleAuthService();
  final GoogleAuthService googleAuthService = GoogleAuthService();

  Future<void> signInWithGuest() async {
    _isLoggedIn = LoginStatus.wating;
    notifyListeners();

    final response = await guestAuthService.signInWithGuest();
    await storage.write(key: 'loginMethod', value: 'guest');
    await tokenProvider.setAccessToken(response['accessToken']);
    await tokenProvider.setRefreshToken(response['refreshToken']);
    fetchUserInfo();
    notifyListeners();
  }

  // Google 로그인 함수(앱 처음 설치하고 구글 로그인 버튼 누르면 실행)
  Future<void> signInWithGoogle() async {
    _isLoggedIn = LoginStatus.wating;
    notifyListeners();

    final response = await googleAuthService.signInWithGoogle();
    if(response == null){
      _isLoggedIn = LoginStatus.logout;
    } else{
      await storage.write(key: 'loginMethod', value: 'google');
      await tokenProvider.setAccessToken(response['accessToken']);
      await tokenProvider.setRefreshToken(response['refreshToken']);
      fetchUserInfo();
    }

    notifyListeners();
  }

  // Apple 로그인 함수
  Future<void> signInWithApple(BuildContext context) async {
    _isLoggedIn = LoginStatus.wating;
    notifyListeners();
    final response = await appleAuthService.signInWithApple(context);
    await storage.write(key: 'loginMethod', value: 'apple');
    await tokenProvider.setAccessToken(response['accessToken']);
    await tokenProvider.setRefreshToken(response['refreshToken']);
    fetchUserInfo();
    notifyListeners();
  }

  Future<void> fetchUserInfo() async {
    final accessToken = await tokenProvider.getAccessToken();
    if (accessToken == null) {
      _isLoggedIn = LoginStatus.logout;
      notifyListeners();
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
      _isLoggedIn = LoginStatus.login;

      await foldersProvider.fetchRootFolderContents();
      await problemsProvider.fetchProblems();

    } else {
      _isLoggedIn = LoginStatus.logout;
    }

    notifyListeners();
  }

  Future<void> autoLogin() async {
    _isLoggedIn = LoginStatus.wating;
    String? refreshToken = await storage.read(key: 'refreshToken');
    if (refreshToken == null) {
      _isLoggedIn = LoginStatus.logout;
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

  Future<void> signOut() async {
    try {
      String? loginMethod = await storage.read(key: 'loginMethod');
      if (loginMethod == 'google') {
        googleAuthService.logoutGoogleSignIn();
      } else if (loginMethod == 'apple') {
      } else if (loginMethod == 'guest') {
        deleteAccount();
      }
      _userId = 0;
      _isLoggedIn = LoginStatus.logout;
      _userName = '';
      _userEmail = '';
      await storage.deleteAll();
      notifyListeners();
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
    } else if (loginMethod == 'guest') {
    } else {
      throw Exception("Unknown login method");
    }

    // 서버에서 사용자 계정 삭제
    try {
      final accessToken = await tokenProvider.getAccessToken();
      if (accessToken == null) {
        throw Exception("JWT token is not available");
      }

      final url = Uri.parse('${AppConfig.baseUrl}/api/user');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        _userId = 0;
        _isLoggedIn = LoginStatus.logout;
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
