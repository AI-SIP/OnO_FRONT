import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ono/Model/LoginStatus.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Service/Auth/GuestAuthService.dart';
import 'package:ono/Service/Auth/KakaoAuthService.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../Config/AppConfig.dart';
import '../GlobalModule/Util/HttpService.dart';
import 'TokenProvider.dart';
import '../Service/Auth/AppleAuthService.dart';
import '../Service/Auth/GoogleAuthService.dart';

class UserProvider with ChangeNotifier {
  final storage = const FlutterSecureStorage();
  final FoldersProvider foldersProvider;
  final TokenProvider tokenProvider = TokenProvider();
  final HttpService httpService = HttpService();

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

  Future<void> saveUserToken({Map<String,dynamic>? response, String? loginMethod}) async{
    if(response == null){
      _loginStatus = LoginStatus.logout;
    } else{
      await storage.write(key: 'loginMethod', value: loginMethod);
      await tokenProvider.setAccessToken(response['accessToken']);
      await tokenProvider.setRefreshToken(response['refreshToken']);

      FirebaseAnalytics.instance.logLogin(loginMethod: loginMethod);
      fetchUserInfo();
    }

    notifyListeners();
  }

  Future<void> fetchUserInfo() async {

    try {
      final response = await httpService.sendRequest(
        method: 'GET',
        url: '${AppConfig.baseUrl}/api/user',
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
            id: _userId.toString(),
            username: _userName,
            email: _userEmail,
          ));
        });

        _problemCount = await getUserProblemCount();
        if (_loginStatus == LoginStatus.login) {
          await foldersProvider.fetchRootFolderContents();
        }
      } else {
        _loginStatus = LoginStatus.logout;
      }
    } catch (error, stackTrace) {
      _loginStatus = LoginStatus.logout;
      await Sentry.captureException(error, stackTrace: stackTrace);
    }

    notifyListeners();
  }

  Future<void> setUserInfoInFirebase(int? userId, String? userName, String? userEmail) async {
    FirebaseAnalytics.instance.setUserId(id: userId.toString());
    FirebaseAnalytics.instance.setUserProperty(name: 'userName', value: userName);
    FirebaseAnalytics.instance.setUserProperty(name: 'userEmail', value: userEmail);
  }

  Future<int> getUserProblemCount() async{

    try {
      final response = await httpService.sendRequest(
        method: 'GET',
        url: '${AppConfig.baseUrl}/api/user/problemCount',
      );

      if (response.statusCode == 200) {
        int userProblemCount = int.parse(response.body);
        log('user problem count : $userProblemCount');
        return userProblemCount;
      } else {
        throw Exception('Failed to get user problem count');
      }
    } catch (error, stackTrace) {
      log('error in getUserProblemCount() : $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
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
      final requestBody = {
        if (email != null) 'email': email,
        if (name != null) 'name': name,
        if (identifier != null) 'identifier': identifier,
        if (userType != null) 'type': userType,
      };

      final response = await httpService.sendRequest(
        method: 'PATCH',
        url: '${AppConfig.baseUrl}/api/user',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
        if (responseBody['userName'] != null) _userName = responseBody['userName'];
        if (responseBody['userEmail'] != null) _userEmail = responseBody['userEmail'];

        log("User info updated successfully: $responseBody");
        notifyListeners();
      } else {
        log('Failed to update user info: ${response.statusCode}');
        throw Exception('Failed to update user info');
      }
    } catch (error, stackTrace) {
      log('Error updating user info: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
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
    }
    else if (loginMethod == 'guest') {

    } else {

    }

    try {
      final response = await httpService.sendRequest(
        method: 'DELETE',
        url: '${AppConfig.baseUrl}/api/user',
      );

      if (response.statusCode == 200) {
        log('Account deletion Success!');

        await FirebaseAnalytics.instance.logEvent(
          name: 'user_delete',
          parameters: {
            'user_id': _userId.toString(),
          },
        );

        resetUserInfo();
      } else {
        log('Failed to delete account: ${response.reasonPhrase}');
        throw Exception("Failed to delete account");
      }
    } catch (error, stackTrace) {
      log('Account deletion error: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
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
