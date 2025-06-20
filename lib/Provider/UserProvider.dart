import 'dart:core';
import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Model/User/UserRegisterModel.dart';
import 'package:ono/Module/Dialog/LoadingDialog.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Service/Api/Problem/ProblemService.dart';
import 'package:ono/Service/Api/User/UserService.dart';
import 'package:ono/Service/SocialLogin//KakaoAuthService.dart';
import 'package:ono/Util/NotificationService.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../Module/Text/StandardText.dart';
import '../Service/Api/HttpService.dart';
import '../Service/SocialLogin//AppleAuthService.dart';
import '../Service/SocialLogin//GoogleAuthService.dart';
import 'ProblemsProvider.dart';
import 'TokenProvider.dart';

class UserProvider with ChangeNotifier {
  final storage = const FlutterSecureStorage();
  final ProblemsProvider problemsProvider;
  final FoldersProvider foldersProvider;
  final ProblemPracticeProvider practiceProvider;
  final TokenProvider tokenProvider = TokenProvider();
  final httpService = HttpService();
  final userService = UserService();
  final problemService = ProblemService();
  final AppleAuthService appleAuthService = AppleAuthService();
  final GoogleAuthService googleAuthService = GoogleAuthService();
  final KakaoAuthService kakaoAuthService = KakaoAuthService();
  UserInfoModel? userInfoModel;

  UserProvider(
      this.problemsProvider, this.foldersProvider, this.practiceProvider);

  LoginStatus _loginStatus = LoginStatus.waiting;
  bool _isFirstLogin = true;
  LoginStatus get isLoggedIn => _loginStatus;
  LoginStatus? get loginStatus => _loginStatus;
  bool get isFirstLogin => _isFirstLogin;

  Future<void> signInWithMember(BuildContext context,
      Future<UserRegisterModel?> Function(BuildContext) socialLogin) async {
    try {
      LoadingDialog.show(context, '로그인 중 입니다...');
      final userRegisterModel = await socialLogin(context);
      final response = await userService.signInWithMember(userRegisterModel);

      saveUserLoginInfo(userRegisterModel?.platform);
      bool isRegister = await saveUserToken(response: response);

      await NotificationService.instance.sendTokenToServer();
      await fetchAllData();
      LoadingDialog.hide(context);

      _loginStatus = LoginStatus.login;
      notifyListeners();

      if (!isRegister) {
        log('register failed!, response: ${response.toString()}');
        throw Exception('response: ${response.toString()}');
      }
    } catch (error, stackTrace) {
      _handleGeneralError(context, error, stackTrace);
    }
  }

  Future<void> signInWithGuest(BuildContext context) async {
    try {
      LoadingDialog.show(context, '로그인 중 입니다...');
      final response = await userService.signInWithGuest();

      saveUserLoginInfo("GUEST");
      bool isRegister = await saveUserToken(response: response);

      await fetchAllData();
      LoadingDialog.hide(context);

      _loginStatus = LoginStatus.login;
      notifyListeners();

      if (!isRegister) {
        log('register failed!, response: ${response.toString()}');
        throw Exception('response: ${response.toString()}');
      }
    } catch (error, stackTrace) {
      _handleGeneralError(context, error, stackTrace);
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    await signInWithMember(context, googleAuthService.signInWithGoogle);
  }

  Future<void> signInWithApple(BuildContext context) async {
    await signInWithMember(context, appleAuthService.signInWithApple);
  }

  Future<void> signInWithKakao(BuildContext context) async {
    await signInWithMember(context, kakaoAuthService.signInWithKakao);
  }

  // 일반 오류 처리 메서드
  void _handleGeneralError(
      BuildContext context, Object error, StackTrace stackTrace) async {
    await resetUserInfo();
    await Sentry.captureException(error, stackTrace: stackTrace);

    LoadingDialog.hide(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: StandardText(
          text: '로그인 과정에서 오류가 발생했습니다.',
          color: Colors.white,
          fontSize: 14,
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void changeIsFirstLogin() {
    _isFirstLogin = false;
    notifyListeners();
  }

  Future<void> saveUserLoginInfo(String? loginMethod) async {
    await storage.write(key: 'loginMethod', value: loginMethod);
    FirebaseAnalytics.instance.logLogin(loginMethod: loginMethod);
  }

  Future<bool> saveUserToken({dynamic? response}) async {
    if (response == null) {
      _loginStatus = LoginStatus.logout;
      await resetUserInfo();

      return false;
    }

    String? accessToken = response['accessToken'] as String?;
    String? refreshToken = response['refreshToken'] as String?;

    if (accessToken == null || refreshToken == null) {
      _loginStatus = LoginStatus.logout;
      await resetUserInfo();
      return false;
    }

    // 나머지 저장 로직은 그대로
    await tokenProvider.setAccessToken(accessToken);
    await tokenProvider.setRefreshToken(refreshToken);

    return true;
  }

  Future<void> fetchAllData() async {
    await fetchUserInfo();
    await problemsProvider.fetchAllProblems();
    await foldersProvider.fetchAllFolderContents();
    await practiceProvider.fetchAllPracticeContents();

    notifyListeners();
  }

  Future<void> fetchUserInfo() async {
    userInfoModel = await userService.fetchUserInfo();
    notifyListeners();
  }

  Future<void> updateUser({
    String? email,
    String? name,
    String? identifier,
  }) async {
    final UserRegisterModel updateUserRegisterModel = UserRegisterModel(
      email: email,
      name: name,
      identifier: identifier,
      platform: null,
    );

    await userService.updateUserProfile(updateUserRegisterModel);
    await fetchUserInfo();
  }

  Future<void> autoLogin() async {
    try {
      String? refreshToken = await tokenProvider.getRefreshToken();

      if (refreshToken == null) {
        _loginStatus = LoginStatus.logout;
      } else {
        await tokenProvider.refreshAccessToken();
        await fetchAllData();
        _isFirstLogin = false;
        _loginStatus = LoginStatus.login;
      }
    } catch (error) {
      _loginStatus = LoginStatus.logout;
      notifyListeners();
      throw Exception("자동 로그인 실패, error: ${error.toString()}");
    } finally {
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    String? loginMethod = await storage.read(key: 'loginMethod');
    if (loginMethod == 'google') {
      googleAuthService.logoutGoogleSignIn();
    } else if (loginMethod == 'apple') {
      // apple 은 별도의 로그아웃 로직이 없습니다.
    } else if (loginMethod == 'kakao') {
      await kakaoAuthService.logoutKakaoSignIn();
    } else if (loginMethod == 'guest') {
      deleteAccount();
    }

    await resetUserInfo();
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
    } else if (loginMethod == 'kakao') {
      // 카카오 회원 탈퇴 로직
      await kakaoAuthService.revokeKakaoSignIn();
    } else if (loginMethod == 'guest') {
    } else {}

    userService.deleteAccount();
    await resetUserInfo();

    await FirebaseAnalytics.instance.logEvent(
      name: 'user_delete',
    );
  }

  Future<void> resetUserInfo() async {
    _loginStatus = LoginStatus.logout;
    _isFirstLogin = true;
    userInfoModel = null;
    notifyListeners();

    await storage.deleteAll();
  }
}
