import 'dart:convert';
import 'dart:core';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mvp_front/Service/AppleAuthService.dart';
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
  final AppleAuthService appleAuthService = AppleAuthService();

  // Google 로그인 함수(앱 처음 설치하고 구글 로그인 버튼 누르면 실행)
  Future<void> signInWithGoogle() async {
    try {
      final googleSignInAccount = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;

      print(googleSignInAuthentication.accessToken);

      final String? accessToken = googleSignInAuthentication.accessToken;   // 얘가 accessToken
      String? email = googleSignInAccount.email;  // 유저의 이메일을 저장
      String? name =  googleSignInAccount.displayName;    // 유저의 이름을 저장

      if (googleSignInAccount != null) {
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

        if (response.statusCode == 200) {
          print('Google sign-in Success!');
          final responseBody = jsonDecode(response.body);
          final jwtToken = responseBody['token'];

          await storage.write(key: 'loginMethod', value: 'google');
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

    final url = Uri.parse('${AppConfig.baseUrl}/api/user');
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

  // 회원 탈퇴 함수
  Future<void> deleteAccount() async {
    String? loginMethod = await storage.read(key: 'loginMethod');
    if (loginMethod == 'google') {
      // 구글 회원 탈퇴 로직
      await _revokeGoogleSignIn();
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
        print('Account deletion Success!');
        await signOut(); // 로그아웃 처리
      } else {
        print('Failed to delete account: ${response.reasonPhrase}');
        throw Exception("Failed to delete account");
      }
    } catch (error) {
      print('Account deletion error: $error');
    }
  }

  Future<void> _revokeGoogleSignIn() async {
    try {
      final googleSignInAccount = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount!.authentication;

      final String? accessToken = googleSignInAuthentication.accessToken;

      final url = Uri.parse('https://oauth2.googleapis.com/revoke');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'token': accessToken,
        },
      );

      if (response.statusCode == 200) {
        print('Google sign-out Success!');
      } else {
        throw Exception('Failed to revoke Google token');
      }
    } catch (error) {
      print('Google sign-out error: $error');
    }
  }
}
