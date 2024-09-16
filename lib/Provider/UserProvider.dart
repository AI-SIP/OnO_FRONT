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
import 'package:ono/Service/Auth/KakaoAuthService.dart';
import 'package:ono/Service/Auth/NaverAuthService.dart';
import '../Config/AppConfig.dart';
import 'TokenProvider.dart';
import '../Service/Auth/AppleAuthService.dart';
import '../Service/Auth/GoogleAuthService.dart';

class UserProvider with ChangeNotifier {
  final storage = const FlutterSecureStorage();
  final FoldersProvider foldersProvider;
  final TokenProvider tokenProvider = TokenProvider();

  UserProvider(this.foldersProvider);

  LoginStatus _isLoggedIn = LoginStatus.waiting;
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
  final KakaoAuthService kakaoAuthService = KakaoAuthService();
  final NaverAuthService naverAuthService = NaverAuthService();

  Future<void> signInWithGuest() async {
    _isLoggedIn = LoginStatus.waiting;
    notifyListeners();

    final response = await guestAuthService.signInWithGuest();
    saveUserToken(response: response, loginMethod: 'guest');
  }

  // Google 로그인 함수(앱 처음 설치하고 구글 로그인 버튼 누르면 실행)
  Future<void> signInWithGoogle() async {
    _isLoggedIn = LoginStatus.waiting;
    notifyListeners();

    final response = await googleAuthService.signInWithGoogle();
    saveUserToken(response: response, loginMethod: 'google');
  }

  // Apple 로그인 함수
  Future<void> signInWithApple(BuildContext context) async {
    _isLoggedIn = LoginStatus.waiting;
    notifyListeners();
    final response = await appleAuthService.signInWithApple(context);
    saveUserToken(response: response, loginMethod: 'apple');
  }

  Future<void> signInWithKakao() async {
    _isLoggedIn = LoginStatus.waiting;
    notifyListeners();

    final response = await kakaoAuthService.signInWithKakao();
    saveUserToken(response: response, loginMethod: 'kakao');
  }

  Future<void> signInWithNaver() async{
    _isLoggedIn = LoginStatus.logout;
    notifyListeners();

    final response = await naverAuthService.signInWithNaver();
    saveUserToken(response: response, loginMethod: 'naver');
  }

  Future<void> saveUserToken({Map<String,dynamic>? response, String? loginMethod}) async{
    if(response == null){
      _isLoggedIn = LoginStatus.logout;
    } else{
      await storage.write(key: 'loginMethod', value: loginMethod);
      await tokenProvider.setAccessToken(response['accessToken']);
      await tokenProvider.setRefreshToken(response['refreshToken']);
      fetchUserInfo();
    }

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
    } else {
      _isLoggedIn = LoginStatus.logout;
    }

    notifyListeners();
  }

  Future<void> autoLogin() async {
    _isLoggedIn = LoginStatus.waiting;
    String? refreshToken = await storage.read(key: 'refreshToken');
    if (refreshToken == null) {
      _isLoggedIn = LoginStatus.logout;
      notifyListeners();
    } else {
      fetchUserInfo();
    }
  }

  Future<void> signOut() async {
    try {
      String? loginMethod = await storage.read(key: 'loginMethod');
      if (loginMethod == 'google') {
        googleAuthService.logoutGoogleSignIn();
      } else if (loginMethod == 'apple') {
        // apple 은 별도의 로그아웃 로직이 없습니다.
      } else if (loginMethod == 'kakao') {
        await kakaoAuthService.logoutKakaoSignIn();
      } else if(loginMethod == 'naver'){
        await naverAuthService.logoutNaverSignIn();
      }
      else if (loginMethod == 'guest') {
        deleteAccount();
      }

      resetUserInfo();
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
    } else if(loginMethod == 'kakao'){
      // 카카오 회원 탈퇴 로직
      await kakaoAuthService.revokeKakaoSignIn();
    } else if(loginMethod == 'naver'){
      // 네이버 회우너 탈퇴 로직
      await naverAuthService.revokeNaverSignIn();
    }
    else if (loginMethod == 'guest') {

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
        log('Account deletion Success!');
        resetUserInfo();
      } else {
        log('Failed to delete account: ${response.reasonPhrase}');
        throw Exception("Failed to delete account");
      }
    } catch (error) {
      log('Account deletion error: $error');
    }
  }

  Future<void> resetUserInfo() async{
    _userId = 0;
    _isLoggedIn = LoginStatus.logout;
    _userName = '';
    _userEmail = '';
    await storage.deleteAll();
    notifyListeners();
  }
}
