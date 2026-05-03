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
import 'package:ono/Service/SocialLogin/KakaoAuthService.dart';
import 'package:ono/Util/AppErrorReporter.dart';
import 'package:ono/Util/NotificationService.dart';

import '../Exception/ApiException.dart';
import '../Module/Text/StandardText.dart';
import '../Service/Api/HttpService.dart';
import '../Service/SocialLogin/AppleAuthService.dart';
import '../Service/SocialLogin/GoogleAuthService.dart';
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
      this.problemsProvider, this.foldersProvider, this.practiceProvider) {
    TokenProvider.registerAuthFailureHandler(_handleAuthFailure);
  }

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
      log('[signInWithMember] userRegisterModel: $userRegisterModel');

      final response = await userService.signInWithMember(userRegisterModel);
      log('[signInWithMember] response received');

      await saveUserLoginInfo(userRegisterModel?.platform);
      bool isRegister = await saveUserToken(response: response);
      log('[signInWithMember] isRegister: $isRegister');

      await NotificationService.instance.sendTokenToServer();
      log('[signInWithMember] notification token sent');

      await fetchAllData();
      log('[signInWithMember] all data fetched');

      _loginStatus = LoginStatus.login;
      notifyListeners();
      log('[signInWithMember] login status set to login');

      if (!context.mounted) return;
      LoadingDialog.hide(context);

      if (!isRegister) {
        log('register failed!, response: ${response.toString()}');
        throw Exception('response: ${response.toString()}');
      }
    } catch (error, stackTrace) {
      log('[signInWithMember] error occurred: $error');
      if (!context.mounted) {
        await AppErrorReporter.report(
          error,
          stackTrace,
          source: 'login',
          severity: AppErrorSeverity.error,
        );
        return;
      }
      await _handleGeneralError(context, error, stackTrace, source: 'login');
    }
  }

  Future<void> signInWithGuest(BuildContext context) async {
    try {
      LoadingDialog.show(context, '로그인 중 입니다...');
      final response = await userService.signInWithGuest();

      await saveUserLoginInfo('GUEST');
      bool isRegister = await saveUserToken(response: response);

      await NotificationService.instance.sendTokenToServer();
      await fetchAllData();

      _loginStatus = LoginStatus.login;
      notifyListeners();

      if (!context.mounted) return;
      LoadingDialog.hide(context);

      if (!isRegister) {
        log('register failed!, response: ${response.toString()}');
        throw Exception('response: ${response.toString()}');
      }
    } catch (error, stackTrace) {
      if (!context.mounted) {
        await AppErrorReporter.report(
          error,
          stackTrace,
          source: 'guest_login',
          severity: AppErrorSeverity.error,
        );
        return;
      }
      await _handleGeneralError(
        context,
        error,
        stackTrace,
        source: 'guest_login',
      );
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
  Future<void> _handleGeneralError(
    BuildContext context,
    Object error,
    StackTrace stackTrace, {
    String source = 'login',
  }) async {
    await resetUserInfo();
    await AppErrorReporter.report(
      error,
      stackTrace,
      source: source,
      severity: AppErrorSeverity.error,
    );

    if (!context.mounted) {
      return;
    }

    LoadingDialog.hide(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: StandardText(
          text: _mapLoginErrorMessage(error),
          color: Colors.white,
          fontSize: 14,
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _mapLoginErrorMessage(Object error) {
    if (error is UnauthorizedException) {
      return '로그인 정보가 만료되었어요. 다시 시도해주세요.';
    }
    if (error is NetworkException || error is TimeoutException) {
      return '네트워크가 불안정해 로그인에 실패했어요. 잠시 후 다시 시도해주세요.';
    }
    if (error is ServerException) {
      return '서버 상태가 불안정해요. 잠시 후 다시 시도해주세요.';
    }
    if (error is BadRequestException) {
      return '로그인 요청을 처리하지 못했어요. 다시 시도해주세요.';
    }
    if (error is ApiException) {
      return '로그인 처리 중 문제가 발생했어요. 다시 시도해주세요.';
    }
    return '로그인 과정에서 오류가 발생했습니다. 다시 시도해주세요.';
  }

  void changeIsFirstLogin() {
    _isFirstLogin = false;
    notifyListeners();
  }

  Future<void> saveUserLoginInfo(String? loginMethod) async {
    await storage.write(key: 'loginMethod', value: loginMethod);
    FirebaseAnalytics.instance.logLogin(loginMethod: loginMethod);
  }

  Future<bool> saveUserToken({dynamic response}) async {
    log('Response type: ${response.runtimeType}');

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

    // 루트 폴더 정보 로드
    await foldersProvider.fetchRootFolder();
    await foldersProvider.moveToRootFolder();

    // 무한 스크롤 방식으로 첫 페이지만 로드
    await practiceProvider.loadInitialPracticeThumbnails();

    notifyListeners();
  }

  Future<void> fetchUserInfo({bool showErrorSnackBar = true}) async {
    userInfoModel = await userService.fetchUserInfo(
      showErrorSnackBar: showErrorSnackBar,
    );
    notifyListeners();
  }

  Future<void> updateNotificationSettings(bool enabled) async {
    if (userInfoModel == null) return;
    final previous = userInfoModel!.notificationEnabled;
    userInfoModel!.notificationEnabled = enabled;
    notifyListeners();
    try {
      await userService.updateNotificationSettings(enabled);
    } catch (e, stackTrace) {
      userInfoModel!.notificationEnabled = previous;
      notifyListeners();
      await AppErrorReporter.report(
        e,
        stackTrace,
        source: 'notification_settings_update',
        severity: AppErrorSeverity.warning,
      );
      rethrow;
    }
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
    await _runPostMutationRefresh(
      () => fetchUserInfo(showErrorSnackBar: false),
      source: 'user_update_info_refresh',
    );
  }

  Future<void> autoLogin() async {
    String? refreshToken = await tokenProvider.getRefreshToken();

    if (refreshToken == null) {
      _loginStatus = LoginStatus.logout;
      notifyListeners();
      return;
    }

    try {
      await tokenProvider.refreshAccessToken();
      _isFirstLogin = false;
      _loginStatus = LoginStatus.login;

      try {
        await fetchAllData();
      } catch (error, stackTrace) {
        // 데이터 로딩 실패만으로 세션을 끊지 않음
        log('자동 로그인 후 데이터 로딩 실패: $error');
        await AppErrorReporter.report(
          error,
          stackTrace,
          source: 'auto_login_fetch_data',
          severity: AppErrorSeverity.warning,
        );
      }
    } on UnauthorizedException catch (error, stackTrace) {
      log('자동 로그인 실패(인증 만료): $error');
      await AppErrorReporter.report(
        error,
        stackTrace,
        source: 'auto_login_unauthorized',
        severity: AppErrorSeverity.warning,
      );
      await _handleAuthFailure();
    } catch (error, stackTrace) {
      // 일시적인 네트워크 오류 등은 로그인 상태 유지
      log('자동 로그인 일시 실패: $error');
      await AppErrorReporter.report(
        error,
        stackTrace,
        source: 'auto_login_refresh',
        severity: AppErrorSeverity.warning,
      );
      _isFirstLogin = false;
      _loginStatus = LoginStatus.login;
    } finally {
      notifyListeners();
    }
  }

  Future<void> maintainSessionOnResume() async {
    final refreshToken = await tokenProvider.getRefreshToken();
    if (refreshToken == null) return;

    try {
      await tokenProvider.refreshAccessTokenIfNeeded();
    } on UnauthorizedException catch (error, stackTrace) {
      log('앱 복귀 중 인증 만료: $error');
      await AppErrorReporter.report(
        error,
        stackTrace,
        source: 'session_resume_unauthorized',
        severity: AppErrorSeverity.warning,
      );
      await _handleAuthFailure();
    } catch (error, stackTrace) {
      // 복귀 순간 네트워크 이슈로는 세션을 끊지 않음
      log('앱 복귀 중 세션 갱신 일시 실패: $error');
      await AppErrorReporter.report(
        error,
        stackTrace,
        source: 'session_resume_refresh',
        severity: AppErrorSeverity.warning,
      );
    }
  }

  Future<void> signOut() async {
    String? loginMethod = await storage.read(key: 'loginMethod');
    if (loginMethod == 'google') {
      await googleAuthService.logoutGoogleSignIn();
    } else if (loginMethod == 'apple') {
      // apple 은 별도의 로그아웃 로직이 없습니다.
    } else if (loginMethod == 'kakao') {
      await kakaoAuthService.logoutKakaoSignIn();
    } else if (loginMethod == 'guest') {
      await deleteAccount();
    }

    await userService.logoutAccount();
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

    await userService.deleteAccount();
    await resetUserInfo();

    await FirebaseAnalytics.instance.logEvent(
      name: 'user_delete',
    );
  }

  Future<void> resetUserInfo() async {
    _loginStatus = LoginStatus.logout;
    _isFirstLogin = true;
    userInfoModel = null;

    await storage.delete(key: "accessToken");
    await storage.delete(key: "refreshToken");
    await storage.delete(key: 'loginMethod');

    problemsProvider.clear();
    foldersProvider.clear();
    practiceProvider.clear();
    notifyListeners();
  }

  Future<void> _runPostMutationRefresh(
    Future<void> Function() refresh, {
    required String source,
  }) async {
    try {
      await refresh();
    } catch (e, stackTrace) {
      log('Post-mutation refresh failed ($source): $e');
      await AppErrorReporter.report(
        e,
        stackTrace,
        source: source,
        severity: AppErrorSeverity.warning,
      );
    }
  }

  Future<void> _handleAuthFailure() async {
    if (_loginStatus == LoginStatus.logout) return;
    await resetUserInfo();
  }
}
