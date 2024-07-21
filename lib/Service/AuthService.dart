import 'dart:convert';
import 'dart:core';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
import '../Config/AppConfig.dart';
import '../Service/UserService.dart';

class AuthService with ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _googleUser;
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';
  String _id = '';
  String? _serverAuthCode = '';


  GoogleSignInAccount? get googleUser => _googleUser;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;
  final UserService _userService = UserService();

  // Google 로그인 함수(앱 처음 설치하고 구글 로그인 버튼 누르면 실행)
  Future<void> signInWithGoogle() async {
    try {
      final googleSignInAccount = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount!.authentication;
      final String? idToken = googleSignInAuthentication.idToken;
      final String? accessToken = googleSignInAuthentication.accessToken;

      if (googleSignInAccount != null) {
        print(googleSignInAccount);
        _googleUser = googleSignInAccount;
        _isLoggedIn = true;
        _userName = googleSignInAccount.displayName ?? '';
        _userEmail = googleSignInAccount.email;
        _id = googleSignInAccount.id;
        _serverAuthCode = googleSignInAccount.serverAuthCode;

        notifyListeners();
        sendUserToServer(googleSignInAccount);
      }
    } catch (error) {
      print('Google sign-in error: $error');
    }
  }

  // 구글 로그인에 성공했을 때, 유저 정보를 서버에 전달해 저장
  Future<void> sendUserToServer(GoogleSignInAccount user) async {
    final url = Uri.parse('${Appconfig.baseUrl}/api/user');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'id': user.id,
        'email': user.email,
        'userName': user.displayName,
        'serverAuthCode': user.serverAuthCode,
      }),
    );

    if (response.statusCode == 200) {
      setUserInfo(response);
    } else {
      throw Exception("Failed to Register user on server");
    }
  }

  Future<void> setUserInfo(http.Response response) async {
    int userId = jsonDecode(utf8.decode(response.bodyBytes))['userId'];
    String userName = jsonDecode(utf8.decode(response.bodyBytes))['userName'];
    String userEmail = jsonDecode(utf8.decode(response.bodyBytes))['userEmail'];
    _userName = userName;
    _userEmail = userEmail;
    print('====save user info complete====');
    await _userService.saveUserInfo(userId, userName, userEmail);
    notifyListeners();
  }

  Future<void> autoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');
    if (userId != null) {
      _userName = prefs.getString('userName') ?? '';
      _userEmail = prefs.getString('email') ?? '';
      _isLoggedIn = true;
      print('====auto login complete====');
      notifyListeners();
    } else {
      _isLoggedIn = false;
      notifyListeners();
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
    try {
      await _googleSignIn.signOut();

      // SharedPreferences에서 사용자 정보 삭제
      await _userService.clearUserInfo();

      _googleUser = null;
      _isLoggedIn = false;
      _userName = '';
      _userEmail = '';
      notifyListeners(); // 리스너들에게 상태 변경을 알림

      // 로그인 화면으로 이동하거나 UI를 업데이트하기 위한 추가 로직
    } catch (error) {
      print('Error signing out: $error');
      throw Exception('Failed to sign out');
    }
  }
}
