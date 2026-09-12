import 'dart:async';
import 'dart:core';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Module/Debug/DebugLevels.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Model/User/UserRegisterModel.dart';
import 'package:ono/Module/Dialog/LoadingDialog.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/MissionProvider.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Service/Api/Problem/ProblemService.dart';
import 'package:ono/Service/Api/User/UserService.dart';
import 'package:ono/Service/SocialLogin/KakaoAuthService.dart';
import 'package:ono/Util/AppErrorReporter.dart';
import 'package:ono/Util/AppAnalytics.dart';
import 'package:ono/Util/AppNavigator.dart';
import 'package:ono/Util/NotificationService.dart';

import '../Exception/ApiException.dart';
import '../Screen/Onboarding/LoginScreen.dart';
import '../Module/Motion/TossPageRoute.dart';
import '../Service/Api/HttpService.dart';
import '../Service/SocialLogin/AppleAuthService.dart';
import '../Service/SocialLogin/GoogleAuthService.dart';
import 'ProblemsProvider.dart';
import 'TokenProvider.dart';
import '../Module/Design/AppToast.dart';

class UserProvider with ChangeNotifier {
  final storage = const FlutterSecureStorage();
  final ProblemsProvider problemsProvider;
  final FoldersProvider foldersProvider;
  final ProblemPracticeProvider practiceProvider;

  /// 로그아웃 때 함께 비운다. 앱 밖(테스트 등)에서는 없을 수 있다.
  final MissionProvider? missionProvider;
  final TokenProvider tokenProvider;
  final HttpService httpService;
  final UserService userService;
  final ProblemService problemService;
  final AppleAuthService appleAuthService;
  final GoogleAuthService googleAuthService;
  final KakaoAuthService kakaoAuthService;

  /// 서버가 준 유저 정보 원본. **디버그 레벨이 섞이지 않은 값이다.**
  ///
  /// 화면이 읽는 것은 [userInfoModel] 이고 그쪽에만 디버그 레벨이 얹힌다.
  /// 원본과 화면용을 갈라 두지 않으면 디버그로 올린 레벨이 다음 저장 요청에
  /// 실려 나가거나 재조회 결과와 뒤섞인다.
  UserInfoModel? _userInfoModel;

  /// 화면이 읽는 유저 정보.
  ///
  /// **디버그 빌드에서 꾸미기 화면의 디버그 패널을 만졌으면** 능력치 레벨을
  /// 그 값으로 갈아 낀 사본이 나온다. 안 만졌으면 서버가 준 값 그대로다.
  /// 릴리즈에서는 [DebugLevels.applyTo] 가 받은 것을 그대로 돌려주므로 이
  /// 경로가 통째로 사라진다.
  ///
  /// 레벨을 읽는 화면이 테마 다이얼로그 · 옷장 탭 스탯창 · 꾸미기 해금 판정 ·
  /// 마이페이지로 흩어져 있어서, 값을 **내주는 이 한 자리**에서 갈아 끼운다.
  /// 화면마다 디버그 여부를 따져 묻게 하면 언젠가 한 곳이 빠진다.
  UserInfoModel? get userInfoModel => DebugLevels.applyTo(_userInfoModel);

  set userInfoModel(UserInfoModel? value) => _userInfoModel = value;

  UserProvider(
    this.problemsProvider,
    this.foldersProvider,
    this.practiceProvider, {
    this.missionProvider,
    TokenProvider? tokenProvider,
    HttpService? httpService,
    UserService? userService,
    ProblemService? problemService,
    AppleAuthService? appleAuthService,
    GoogleAuthService? googleAuthService,
    KakaoAuthService? kakaoAuthService,
  })  : tokenProvider = tokenProvider ?? TokenProvider(),
        httpService = httpService ?? HttpService(),
        userService = userService ?? UserService(),
        problemService = problemService ?? ProblemService(),
        appleAuthService = appleAuthService ?? AppleAuthService(),
        googleAuthService = googleAuthService ?? GoogleAuthService(),
        kakaoAuthService = kakaoAuthService ?? KakaoAuthService() {
    TokenProvider.registerAuthFailureHandler(_handleAuthFailure);
    // 디버그 패널에서 레벨을 옮기면 이쪽을 보고 있는 화면들도 다시 그려야
    // 한다. 패널이 부르는 것은 CosmeticProvider 인데 테마 다이얼로그는
    // 이쪽을 보고 있어서, 값이 바뀐 것을 여기가 따로 알아야 한다.
    if (kDebugMode) DebugLevels.listenable.addListener(notifyListeners);
  }

  @override
  void dispose() {
    if (kDebugMode) DebugLevels.listenable.removeListener(notifyListeners);
    super.dispose();
  }

  LoginStatus _loginStatus = LoginStatus.waiting;
  bool _isFirstLogin = true;
  bool _handlingAuthFailure = false;
  LoginStatus get isLoggedIn => _loginStatus;
  LoginStatus? get loginStatus => _loginStatus;
  bool get isFirstLogin => _isFirstLogin;

  Future<void> signInWithMember(BuildContext context,
      Future<UserRegisterModel?> Function(BuildContext) socialLogin) async {
    try {
      LoadingDialog.show(context, '로그인 중 입니다...');
      final userRegisterModel = await socialLogin(context);
      debugPrint('[signInWithMember] userRegisterModel: $userRegisterModel');

      // 소셜 로그인 창을 사용자가 닫은 경우 null 이 온다. 실패 원인이 있는 경우는
      // 각 AuthService 에서 이미 보고하므로, 여기서 다시 에러로 만들지 않는다.
      // (Sentry FLUTTER-VK/T8/VH "잘못된 유저 정보입니다" 노이즈)
      if (userRegisterModel == null) {
        debugPrint('[signInWithMember] social login cancelled');
        if (context.mounted) {
          LoadingDialog.hide(context);
        }
        return;
      }

      final response = await userService.signInWithMember(userRegisterModel);
      debugPrint('[signInWithMember] response received');

      await saveUserLoginInfo(userRegisterModel.platform);
      bool isRegister = await saveUserToken(response: response);
      debugPrint('[signInWithMember] isRegister: $isRegister');

      await NotificationService.instance.sendTokenToServer();
      debugPrint('[signInWithMember] notification token sent');

      await fetchAllData();
      debugPrint('[signInWithMember] all data fetched');

      _loginStatus = LoginStatus.login;
      notifyListeners();
      debugPrint('[signInWithMember] login status set to login');

      if (!context.mounted) return;
      LoadingDialog.hide(context);

      if (!isRegister) {
        debugPrint('register failed!, response: ${response.toString()}');
        throw Exception('response: ${response.toString()}');
      }
    } catch (error, stackTrace) {
      debugPrint('[signInWithMember] error occurred: $error');
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
        debugPrint('register failed!, response: ${response.toString()}');
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

    AppToast.error(_mapLoginErrorMessage(error));
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
    debugPrint('Response type: ${response.runtimeType}');

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
    _userInfoModel = await userService.fetchUserInfo(
      showErrorSnackBar: showErrorSnackBar,
    );
    // 유저 정보를 새로 받아올 때마다 Analytics 쪽 유저 속성도 맞춘다.
    // 로그인 직후, 자동 로그인, 프로필 수정 뒤가 모두 여기를 지난다.
    unawaited(
      AppAnalytics.identify(
        // 원본을 보낸다. 디버그로 옮겨 놓은 레벨이 통계에 섞이면 안 된다.
        _userInfoModel,
        loginMethod: await storage.read(key: 'loginMethod'),
      ),
    );
    notifyListeners();
  }

  Future<void> updateNotificationSettings(bool enabled) async {
    if (_userInfoModel == null) return;
    final previous = _userInfoModel!.notificationEnabled;
    _userInfoModel!.notificationEnabled = enabled;
    notifyListeners();
    try {
      await userService.updateNotificationSettings(enabled);
    } catch (e, stackTrace) {
      _userInfoModel!.notificationEnabled = previous;
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

  Future<void> updateUserProfileImage(String imagePath) async {
    _userInfoModel = await userService.updateUserProfileImage(imagePath);
    notifyListeners();
  }

  Future<void> updateUserProfileImageUrl(String profileImageUrl) async {
    _userInfoModel =
        await userService.updateUserProfileImageUrl(profileImageUrl);
    notifyListeners();
  }

  Future<void> deleteUserProfileImage() async {
    _userInfoModel = await userService.deleteUserProfileImage();
    notifyListeners();
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
        debugPrint('자동 로그인 후 데이터 로딩 실패: $error');
        await AppErrorReporter.report(
          error,
          stackTrace,
          source: 'auto_login_fetch_data',
          severity: AppErrorSeverity.warning,
        );
      }
    } on UnauthorizedException catch (error, stackTrace) {
      debugPrint('자동 로그인 실패(인증 만료): $error');
      await AppErrorReporter.report(
        error,
        stackTrace,
        source: 'auto_login_unauthorized',
        severity: AppErrorSeverity.warning,
      );
      await _handleAuthFailure();
    } catch (error, stackTrace) {
      // 일시적인 네트워크 오류 등은 로그인 상태 유지
      debugPrint('자동 로그인 일시 실패: $error');
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
      debugPrint('앱 복귀 중 인증 만료: $error');
      await AppErrorReporter.report(
        error,
        stackTrace,
        source: 'session_resume_unauthorized',
        severity: AppErrorSeverity.warning,
      );
      await _handleAuthFailure();
    } catch (error, stackTrace) {
      // 복귀 순간 네트워크 이슈로는 세션을 끊지 않음
      debugPrint('앱 복귀 중 세션 갱신 일시 실패: $error');
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
    _userInfoModel = null;

    // 지우지 않으면 같은 기기에서 다른 계정으로 로그인했을 때 앞 사람의
    // 유저 속성이 그대로 남아 통계가 섞인다.
    unawaited(AppAnalytics.clear());

    await storage.delete(key: "accessToken");
    await storage.delete(key: "refreshToken");
    await storage.delete(key: 'loginMethod');

    problemsProvider.clear();
    foldersProvider.clear();
    practiceProvider.clear();
    // 비우지 않으면 다른 계정으로 로그인한 첫 화면에 앞 사람의 미션 진행도와
    // 받기 배지가 그대로 뜬다.
    missionProvider?.clear();
    notifyListeners();
  }

  Future<void> _runPostMutationRefresh(
    Future<void> Function() refresh, {
    required String source,
  }) async {
    try {
      await refresh();
    } catch (e, stackTrace) {
      debugPrint('Post-mutation refresh failed ($source): $e');
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
    if (_handlingAuthFailure) return;

    _handlingAuthFailure = true;
    final shouldNavigateToLogin = _loginStatus == LoginStatus.login;
    try {
      await resetUserInfo();
    } finally {
      _handlingAuthFailure = false;
    }

    if (!shouldNavigateToLogin) return;
    _navigateToLoginAfterAuthFailure();
  }

  void _navigateToLoginAfterAuthFailure({int retryCount = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = AppNavigator.navigatorKey.currentState;
      if (navigator == null) {
        if (retryCount < 2) {
          Future<void>.delayed(const Duration(milliseconds: 100), () {
            _navigateToLoginAfterAuthFailure(retryCount: retryCount + 1);
          });
          return;
        }

        unawaited(
          AppErrorReporter.report(
            StateError('Navigator is not ready for auth failure redirect.'),
            StackTrace.current,
            source: 'auth_failure_navigation',
            severity: AppErrorSeverity.warning,
          ),
        );
        return;
      }

      navigator.pushAndRemoveUntil(
        TossPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });
  }
}
