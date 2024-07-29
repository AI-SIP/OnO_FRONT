import 'dart:convert';
import 'dart:core';
import 'dart:io' show Platform;
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
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;

      print(googleSignInAuthentication.accessToken);

      //final String? idToken = googleSignInAuthentication.idToken;   // 얘가 null로 저장되는 문제 발생
      final String? accessToken = googleSignInAuthentication.accessToken;   // 얘가 accessToken
      String? email = googleSignInAccount.email;  // 유저의 이메일을 저장
      String? name =  googleSignInAccount.displayName;    // 유저의 이름을 저장

      if (googleSignInAccount != null) {
      //if (googleSignInAccount != null && idToken != null) {
        //print('Google Sign-In successful. ID Token: $idToken');
        final platform = _getPlatform(); // 플랫폼 정보 확인

        final url = Uri.parse('${AppConfig.baseUrl}/api/auth/google');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            //'idToken': idToken,
            'accessToken': accessToken,
            'platform': platform,
            'email': email,
            'name': name,
          }),
        );

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          print('Google sign-in Success!');
          final responseBody = jsonDecode(response.body);
          final jwtToken = responseBody['token'];

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

      final String? idToken = appleCredential.identityToken;
      final String? email = appleCredential.email;
      final String? firstName = appleCredential.givenName;
      final String? lastName = appleCredential.familyName;
      final String? name = (lastName ?? "") + (firstName ?? "");

      if (idToken != null) {
        final url = Uri.parse('${AppConfig.baseUrl}/api/auth/apple');
        final response = await http.post(
          url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String?>{
            'idToken': idToken,
            'email': email,
            'name': name,
          }),
        );

        if (response.statusCode == 200) {
          print('Apple sign-in Success!');
          final responseBody = jsonDecode(response.body);
          final jwtToken = responseBody['token'];
          await setJwtToken(jwtToken);
          fetchUserInfo();
          notifyListeners();
        } else {
          throw Exception("Failed to Register user on server");
        }
      } else {
        throw Exception("Failed to get Apple idToken");
      }
    } catch (error) {
      print('Apple sign-in error: $error');
    }
  }

  Future<void> setJwtToken(String token) async {
    await storage.write(key: 'jwtToken', value: token);
  }

  Future<String?> getJwtToken() async {
    return await storage.read(key: 'jwtToken');
  }

  String _getPlatform() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else {
      return 'unknown';
    }
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
      _userName = responseBody['userName'];
      _userEmail = responseBody['userEmail'];
      _isLoggedIn = true;
      notifyListeners();
    } else {
      throw Exception("Failed to fetch user info");
    }
  }

  Future<http.Response> sendAuthenticatedRequest(
      String endpoint, Map<String, dynamic> body) async {
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
