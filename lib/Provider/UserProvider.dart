import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ono/Model/LoginStatus.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Service/Auth/GuestAuthService.dart';
import 'package:ono/Service/Auth/KakaoAuthService.dart';
import 'package:ono/Service/Auth/NaverAuthService.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../Config/AppConfig.dart';
import 'TokenProvider.dart';
import '../Service/Auth/AppleAuthService.dart';
import '../Service/Auth/GoogleAuthService.dart';

class UserProvider with ChangeNotifier {
  final storage = const FlutterSecureStorage();
  final FoldersProvider foldersProvider;
  final TokenProvider tokenProvider = TokenProvider();

  UserProvider(this.foldersProvider);

  LoginStatus _loginStatus = LoginStatus.waiting;
  int? _userId = 0;
  int? _problemCount = 0;
  String? _userName = '';
  String? _userEmail = '';

  LoginStatus get isLoggedIn => _loginStatus;
  int? get userId => _userId;
  int? get problemCount => _problemCount;
  LoginStatus? get loginStatus => _loginStatus;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  final GuestAuthService guestAuthService = GuestAuthService();
  final AppleAuthService appleAuthService = AppleAuthService();
  final GoogleAuthService googleAuthService = GoogleAuthService();
  final KakaoAuthService kakaoAuthService = KakaoAuthService();
  final NaverAuthService naverAuthService = NaverAuthService();

  Future<void> signInWithGuest() async {
    _loginStatus = LoginStatus.waiting;
    notifyListeners();

    final response = await guestAuthService.signInWithGuest();
    saveUserToken(response: response, loginMethod: 'guest');
  }

  // Google 로그인 함수(앱 처음 설치하고 구글 로그인 버튼 누르면 실행)
  Future<void> signInWithGoogle() async {
    _loginStatus = LoginStatus.waiting;
    notifyListeners();

    final response = await googleAuthService.signInWithGoogle();
    saveUserToken(response: response, loginMethod: 'google');
  }

  // Apple 로그인 함수
  Future<void> signInWithApple(BuildContext context) async {
    _loginStatus = LoginStatus.waiting;
    notifyListeners();
    final response = await appleAuthService.signInWithApple(context);
    saveUserToken(response: response, loginMethod: 'apple');
  }

  Future<void> signInWithKakao() async {
    _loginStatus = LoginStatus.waiting;
    notifyListeners();

    final response = await kakaoAuthService.signInWithKakao();
    saveUserToken(response: response, loginMethod: 'kakao');
  }

  Future<void> signInWithNaver() async{
    _loginStatus = LoginStatus.logout;
    notifyListeners();

    final response = await naverAuthService.signInWithNaver();
    saveUserToken(response: response, loginMethod: 'naver');
  }

  Future<void> saveUserToken({Map<String,dynamic>? response, String? loginMethod}) async{
    if(response == null){
      _loginStatus = LoginStatus.logout;
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
      _loginStatus = LoginStatus.logout;
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
      _userId = responseBody['userId'] ?? 0;
      _userName = responseBody['userName'] ?? '이름 없음';
      _userEmail = responseBody['userEmail'];
      _loginStatus = LoginStatus.login;

      FirebaseAnalytics.instance.logLogin();
      setUserInfoInFirebase(_userId, _userName, _userEmail);

      // Sentry에 유저 정보 설정
      Sentry.configureScope((scope) {
        scope.setUser(SentryUser(
          id: _userId.toString(),  // 유저 아이디 설정
          username: _userName,     // 유저 이름 설정
          email: _userEmail,       // 유저 이메일 설정
        ));
      });

      _problemCount = await getUserProblemCount();
      if(_loginStatus == LoginStatus.login){
        await foldersProvider.fetchRootFolderContents();
      }

    } else {
      _loginStatus = LoginStatus.logout;
    }

    notifyListeners();
  }

  Future<void> setUserInfoInFirebase(int? userId, String? userName, String? userEmail) async {
    FirebaseAnalytics.instance.setUserId(id: userId.toString());
    FirebaseAnalytics.instance.setUserProperty(name: 'userName', value: userName);
    FirebaseAnalytics.instance.setUserProperty(name: 'userEmail', value: userEmail);
  }

  Future<int> getUserProblemCount() async{
    try{
      final accessToken = await tokenProvider.getAccessToken();
      if (accessToken == null) {
        log('Access token is not available');
        return 0;
      }

      final url = Uri.parse('${AppConfig.baseUrl}/api/user/problemCount');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        int userProblemCount = int.parse(response.body);

        log('user problem count : $userProblemCount');

        return userProblemCount;
      } else {
        throw Exception('Failed to get user problem count');
      }
    } catch(error, stackTrace) {
      log('error in getUserProblemCount() : $error');
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );

      return 0;
    }
  }

  Future<void> updateUser({
    String? email,
    String? name,
    String? identifier,
    String? userType,
  }) async {
    try {
      // Access token 가져오기
      final accessToken = await tokenProvider.getAccessToken();
      if (accessToken == null) {
        throw Exception("Access token is not available");
      }

      // 서버 URL
      final url = Uri.parse('${AppConfig.baseUrl}/api/user');

      // 유저 업데이트 요청을 위한 데이터
      final Map<String, dynamic> requestBody = {};

      // 각 필드가 null이 아닐 때만 requestBody에 포함
      if (email != null) requestBody['email'] = email;
      if (name != null) requestBody['name'] = name;
      if (identifier != null) requestBody['identifier'] = identifier;
      if (userType != null) requestBody['type'] = userType;

      // PATCH 요청
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // 토큰 인증
        },
        body: jsonEncode(requestBody), // JSON으로 직렬화
      );

      // 성공적으로 유저 정보가 업데이트되었을 경우
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
        if (responseBody['userName'] != null) _userName = responseBody['userName'];
        if (responseBody['userEmail'] != null) _userEmail = responseBody['userEmail'];

        log("User info updated successfully: $responseBody");
        notifyListeners(); // 상태 변화 알림
      } else {
        // 업데이트 실패 처리
        log('Failed to update user info: ${response.statusCode}');
        throw Exception('Failed to update user info');
      }
    } catch (error, stackTrace) {
      log('Error updating user info: $error');
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> autoLogin() async {
    _loginStatus = LoginStatus.waiting;
    String? refreshToken = await storage.read(key: 'refreshToken');
    if (refreshToken == null) {
      _loginStatus = LoginStatus.logout;
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

      await FirebaseAnalytics.instance.logEvent(
        name: 'user_logout',
        parameters: {
          'user_id': _userId.toString(), // 유저 ID 등 추가적인 정보도 포함 가능
        },
      );

      resetUserInfo();
    } catch (error, stackTrace) {
      log('Error signing out: $error');
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
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
      // 네이버 회원 탈퇴 로직
      await naverAuthService.revokeNaverSignIn();
    }
    else if (loginMethod == 'guest') {

    } else {

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

        await FirebaseAnalytics.instance.logEvent(
          name: 'user_delete',
          parameters: {
            'user_id': _userId.toString(), // 유저 ID 등 추가적인 정보도 포함 가능
          },
        );

        resetUserInfo();
      } else {
        log('Failed to delete account: ${response.reasonPhrase}');
        throw Exception("Failed to delete account");
      }
    } catch (error, stackTrace) {
      log('Account deletion error: $error');
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> resetUserInfo() async{
    _userId = 0;
    _loginStatus = LoginStatus.logout;
    _userName = '';
    _userEmail = '';
    _problemCount = 0;
    await storage.deleteAll();
    notifyListeners();
  }
}
