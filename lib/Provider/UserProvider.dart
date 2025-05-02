import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'dart:io' show Platform, SocketException;
import 'package:http/http.dart' as http;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ono/GlobalModule/Dialog/LoadingDialog.dart';
import 'package:ono/GlobalModule/Dialog/SnackBarDialog.dart';
import 'package:ono/Model/LoginStatus.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/ProblemPracticeProvider.dart';
import 'package:ono/Service/Auth/GuestAuthService.dart';
import 'package:ono/Service/Auth/KakaoAuthService.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../Config/AppConfig.dart';
import '../GlobalModule/Text/StandardText.dart';
import '../Service/Network/HttpService.dart';
import 'TokenProvider.dart';
import '../Service/Auth/AppleAuthService.dart';
import '../Service/Auth/GoogleAuthService.dart';

class UserProvider with ChangeNotifier {
  final storage = const FlutterSecureStorage();
  final FoldersProvider foldersProvider;
  final ProblemPracticeProvider practiceProvider;
  final TokenProvider tokenProvider = TokenProvider();
  final HttpService httpService = HttpService();

  UserProvider(this.foldersProvider, this.practiceProvider);

  LoginStatus _loginStatus = LoginStatus.waiting;
  int? _userId = 0;
  int? _problemCount = 0;
  String? _userName = '';
  String? _userEmail = '';
  bool _isLoading = true;
  bool _isFirstLogin = false;

  set isFirstLogin(bool value) {
    _isFirstLogin = value;
    notifyListeners(); // 상태 변경 시 화면 업데이트
  }

  LoginStatus get isLoggedIn => _loginStatus;
  int? get userId => _userId;
  int? get problemCount => _problemCount;
  LoginStatus? get loginStatus => _loginStatus;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isLoading => _isLoading;
  bool get isFirstLogin => _isFirstLogin;

  final GuestAuthService guestAuthService = GuestAuthService();
  final AppleAuthService appleAuthService = AppleAuthService();
  final GoogleAuthService googleAuthService = GoogleAuthService();
  final KakaoAuthService kakaoAuthService = KakaoAuthService();

  Future<void> signIn(BuildContext context, Future<Map<String, dynamic>?> Function(BuildContext) signInMethod, String loginMethod) async {
    try {
      LoadingDialog.show(context, '로그인 중 입니다...');
      final response = await signInMethod(context);
      bool isRegister = await saveUserToken(response: response, loginMethod: loginMethod);
      LoadingDialog.hide(context);

      if (!isRegister) {
        log('register failed!, response: ${response.toString()}');
        throw Exception('response: ${response.toString()}');
      }
    } catch (error, stackTrace) {
      _handleGeneralError(context, error, stackTrace);
    }
  }

  Future<void> signInWithGuest(BuildContext context) async {
    await signIn(context, guestAuthService.signInWithGuest, 'guest');
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    await signIn(context, googleAuthService.signInWithGoogle, 'google');
  }

  Future<void> signInWithApple(BuildContext context) async {
    await signIn(context, appleAuthService.signInWithApple, 'apple');
  }

  Future<void> signInWithKakao(BuildContext context) async {
    await signIn(context, kakaoAuthService.signInWithKakao, 'kakao');
  }

  // 일반 오류 처리 메서드
  void _handleGeneralError(BuildContext context, Object error, StackTrace stackTrace) async {
    await resetUserInfo();
    await Sentry.captureException(error, stackTrace: stackTrace);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: StandardText(text: '로그인 과정에서 오류가 발생했습니다.', color: Colors.white, fontSize: 14,),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<bool> saveUserToken({Map<String,dynamic>? response, String? loginMethod}) async{
    if(response == null){
      _loginStatus = LoginStatus.logout;
      await resetUserInfo();

      return false;
    } else{
      String? accessToken = response['accessToken'];
      String? refreshToken = response['refreshToken'];

      if(accessToken == null || refreshToken == null){
        _loginStatus = LoginStatus.logout;
        await resetUserInfo();

        return false;
      }

      await storage.write(key: 'loginMethod', value: loginMethod);
      await tokenProvider.setAccessToken(accessToken);
      await tokenProvider.setRefreshToken(refreshToken);
      _isFirstLogin = true;

      FirebaseAnalytics.instance.logLogin(loginMethod: loginMethod);
      return await fetchUserInfo();
    }
  }

  Future<bool> fetchUserInfo() async {
    try {
      final response = await httpService.sendRequest(
        method: 'GET',
        url: '${AppConfig.baseUrl}/api/user',
      );

      if (response.statusCode == 200) {
        await _processUserInfoResponse(response);
        _problemCount = await getUserProblemCount();

        if (_loginStatus == LoginStatus.login) {
          //await foldersProvider.fetchRootFolderContents();
          await foldersProvider.fetchAllFolderContents();
          await practiceProvider.fetchAllPracticeContents();
        }
        return true;
      } else {
        return _handleFetchError();
      }
    } catch (error, stackTrace) {
      return _handleFetchError(error: error, stackTrace: stackTrace);
    } finally {
      notifyListeners();
    }
  }

  Future<void> _processUserInfoResponse(http.Response response) async {
    final responseBody = await jsonDecode(utf8.decode(response.bodyBytes));
    _userId = responseBody['userId'] ?? 0;
    _userName = responseBody['userName'] ?? '이름 없음';
    _userEmail = responseBody['userEmail'];
    _loginStatus = LoginStatus.login;

    await FirebaseAnalytics.instance.logLogin();
    await setUserInfoInFirebase(_userId, _userName, _userEmail);

    await Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: _userId.toString(),
        username: _userName,
        email: _userEmail,
      ));
    });

    await FirebaseAnalytics.instance.logEvent(name: 'fetch_user_info');
  }

  Future<bool> _handleFetchError({Object? error, StackTrace? stackTrace}) async {
    _loginStatus = LoginStatus.logout;
    if (error != null) {
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
    return false;
  }

  Future<void> setUserInfoInFirebase(int? userId, String? userName, String? userEmail) async {
    await FirebaseAnalytics.instance.setUserId(id: userId.toString());
    await FirebaseAnalytics.instance.setUserProperty(name: 'userName', value: userName);
    await FirebaseAnalytics.instance.setUserProperty(name: 'userEmail', value: userEmail);
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
    String? refreshToken = await tokenProvider.getRefreshToken();

    _isLoading = false;
    _isFirstLogin = false;
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

      await resetUserInfo();
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

        await resetUserInfo();
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
    _isFirstLogin = false;
    notifyListeners();

    await storage.deleteAll();
  }
}
