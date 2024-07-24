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

      if (googleSignInAccount != null && idToken != null) {
        //print('Google Sign-In successful. ID Token: $idToken');

        final url = Uri.parse('${AppConfig.baseUrl}/api/auth/google');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({'idToken': idToken}),
        );

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          final jwtToken = responseBody['token'];
          print('JWT Token: $jwtToken');

          await setJwtToken(jwtToken);
          fetchUserInfo();
          notifyListeners();
        } else {
          throw Exception("Failed to Register user on server");
        }
      } else {
        throw Exception("Failed to get Google idToken");
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

      print(appleCredential.toString());
      print(appleCredential.identityToken);
      print(appleCredential.authorizationCode);

      if (appleCredential != null) {

        final url = Uri.parse('${AppConfig.baseUrl}/api/user/join');
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
          //setUserInfo(response);
        } else {
          throw Exception("Failed to Register user on server");
        }
      }
    } catch (error) {
        print('Apple sign-in error: $error');
    }
  }

  Future<void> setJwtToken(String token) async{
    await storage.write(key: 'jwtToken', value: token);
  }

  Future<String?> getJwtToken() async{
    return await storage.read(key: 'jwtToken');
  }

  Future<void> fetchUserInfo() async {
    final token = await getJwtToken();
    if (token == null) {
      throw Exception("JWT token is not available");
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/user/info');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print(response.toString());

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
      _userId = responseBody['userId'];
      _userName = responseBody['name'];
      _userEmail = responseBody['email'];
      _isLoggedIn = true;
      notifyListeners();
    } else {
      throw Exception("Failed to fetch user info");
    }
  }

  Future<http.Response> sendAuthenticatedRequest(String endpoint, Map<String, dynamic> body) async {
    final token = await getJwtToken();
    if (token == null) {
      throw Exception("JWT token is not available");
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/$endpoint');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );


    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('Authenticated request successful');
    } else {
      print('Failed to authenticate request');
    }

    return response;
  }

  Future<void> autoLogin() async {
    String? token = await getJwtToken();
    if (token != null) {
      try {
        await fetchUserInfo();
        print('====auto login complete====');
      } catch (e) {
        print('Auto login failed: $e');
      }
      notifyListeners();
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
