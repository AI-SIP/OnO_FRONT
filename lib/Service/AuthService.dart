import 'dart:convert';
import 'dart:core';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
import '../Config/AppConfig.dart';

class AuthService with ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final storage = FlutterSecureStorage();
  GoogleSignInAccount? _googleUser;
  bool _isLoggedIn = false;
  int _userId = 0;
  String _userName = '';
  String _userEmail = '';

  GoogleSignInAccount? get googleUser => _googleUser;
  bool get isLoggedIn => _isLoggedIn;
  int get userId => _userId;
  String get userName => _userName;
  String get userEmail => _userEmail;

  // Google 로그인 함수(앱 처음 설치하고 구글 로그인 버튼 누르면 실행)
  Future<void> signInWithGoogle() async {
    try {
      final googleSignInAccount = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount!.authentication;
      final String? idToken = googleSignInAuthentication.idToken;
      final String? accessToken = googleSignInAuthentication.accessToken;

      if (googleSignInAccount != null) {
        // print(googleSignInAccount);
        // _googleUser = googleSignInAccount;
        // _isLoggedIn = true;
        // _userName = googleSignInAccount.displayName ?? '';
        // _userEmail = googleSignInAccount.email;
        // _id = googleSignInAccount.id;
        // _serverAuthCode = googleSignInAccount.serverAuthCode;

        final url = Uri.parse('${AppConfig.baseUrl}/api/user');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'googleId': googleSignInAccount.id,
            'email': googleSignInAccount.email,
            'userName': googleSignInAccount.displayName,
            'socialLoginType': 'GOOGLE',
          }),
        );

        if (response.statusCode == 200) {
          setUserInfo(response);
        } else {
          throw Exception("Failed to Register user on server");
        }
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
        final url = Uri.parse('${AppConfig.baseUrl}/api/user');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'appleId': appleCredential.userIdentifier,
            'email': appleCredential.email,
            'userName': "${appleCredential.familyName ?? ''}${appleCredential.givenName ?? ''}".trim(),
            'socialLoginType': 'APPLE',
          }),
        );

        if (response.statusCode == 200) {
          setUserInfo(response);
        } else {
          throw Exception("Failed to Register user on server");
        }
      }
    } catch (error) {
        print('Apple sign-in error: $error');
    }
  }

  Future<void> setUserInfo(http.Response response) async {
    int userId = jsonDecode(utf8.decode(response.bodyBytes))['userId'];
    String userName = jsonDecode(utf8.decode(response.bodyBytes))['userName'];
    String userEmail = jsonDecode(utf8.decode(response.bodyBytes))['userEmail'];
    String socialId = jsonDecode(utf8.decode(response.bodyBytes))['socialId'];
    String socialLoginType = jsonDecode(utf8.decode(response.bodyBytes))['socialLoginType'];

    await storage.write(key: 'userId', value: userId.toString());
    await storage.write(key: 'userName', value: userName);
    await storage.write(key: 'userEmail', value: userEmail);
    await storage.write(key: 'socialId', value: socialId);
    await storage.write(key: 'socialLoginType', value: socialLoginType);

    _userId = userId;
    _userName = userName;
    _userEmail = userEmail;
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> autoLogin() async {
    String? userIdStr = await storage.read(key: 'userId');
    int? userId = int.parse(userIdStr ?? '');
    if (userId != null) {
      _userId = userId;
      _userName = await storage.read(key: 'userName') ?? '';
      _userEmail = await storage.read(key: 'userEmail') ?? '';
      _isLoggedIn = true;
      print('====auto login complete====');
      notifyListeners();
    } else {
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    String? userId = await storage.read(key: 'userId');
    String? userName = await storage.read(key: 'userName');
    String? userEmail = await storage.read(key: 'userEmail');

    log('userId: $userId, userName: $userName, userEmail: $userEmail');

    if (userId != null && userName != null && userEmail != null) {
      return {
        'userId': int.parse(userId),
        'userName': userName,
        'userEmail': userEmail,
      };
    } else {
      print('No user info found'); // 로그 추가
      throw Exception('No user info found');
    }
  }

  // 로그아웃 함수
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _googleUser = null;
      _userId = 0;
      _isLoggedIn = false;
      _userName = '';
      _userEmail = '';
      await storage.deleteAll();
      notifyListeners(); // 리스너들에게 상태 변경을 알림
    } catch (error) {
      print('Error signing out: $error');
      throw Exception('Failed to sign out');
    }
  }
}
