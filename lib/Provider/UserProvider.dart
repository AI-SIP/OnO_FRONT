import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Module/Debug/DebugLevels.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Model/User/UserRegisterModel.dart';
import 'package:ono/Module/Dialog/LoadingDialog.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/AchievementProvider.dart';
import 'package:ono/Provider/CosmeticProvider.dart';
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

  /// 옷장. 유저 정보를 받을 때마다 레벨을 맞춰 주고 로그아웃 때 비운다.
  ///
  /// 옷장은 **이 사람의 능력치 레벨**을 알아야 무엇이 열렸는지 말할 수 있는데,
  /// 그 다섯은 유저 정보에만 있다. 여기 물려 두지 않으면 옷장이 혼자 떠서
  /// 레벨을 한 번도 못 본다. 앱 밖(테스트 등)에서는 없을 수 있다.
  final CosmeticProvider? cosmeticProvider;

  /// 훈장. 로그인 뒤 한 번 채우고 로그아웃 때 비운다.
  ///
  /// 여기 물려 두지 않으면 훈장은 사용자가 스스로 훈장 화면을 열 때만 채워진다.
  /// 새로 받은 훈장은 **그 조회 한 번에만** 실려 오므로, 아무도 안 물어보는
  /// 동안에는 서른 날을 채운 개근 훈장도 조용히 `earned` 로 바뀌고 만다.
  /// 앱 밖(테스트 등)에서는 없을 수 있다.
  final AchievementProvider? achievementProvider;

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
    this.cosmeticProvider,
    this.achievementProvider,
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
      if (isRegister) _logLoginSuccess(userRegisterModel.platform);

      if (!context.mounted) return;
      LoadingDialog.hide(context);

      if (!isRegister) {
        debugPrint('register failed!, response: ${response.toString()}');
        throw Exception('response: ${response.toString()}');
      }
    } catch (error, stackTrace) {
      debugPrint('[signInWithMember] error occurred: $error');
      AppAnalytics.logEvent('login_fail', {
        'source': 'member',
        'error': error.runtimeType.toString(),
      });
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
    AppAnalytics.logEvent('login_start', {'method': 'guest'});
    try {
      LoadingDialog.show(context, '로그인 중 입니다...');
      final response = await userService.signInWithGuest();

      await saveUserLoginInfo('GUEST');
      bool isRegister = await saveUserToken(response: response);

      await NotificationService.instance.sendTokenToServer();
      await fetchAllData();

      _loginStatus = LoginStatus.login;
      notifyListeners();
      if (isRegister) _logLoginSuccess('GUEST');

      if (!context.mounted) return;
      LoadingDialog.hide(context);

      if (!isRegister) {
        debugPrint('register failed!, response: ${response.toString()}');
        throw Exception('response: ${response.toString()}');
      }
    } catch (error, stackTrace) {
      AppAnalytics.logEvent('login_fail', {
        'source': 'guest',
        'error': error.runtimeType.toString(),
      });
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
    AppAnalytics.logEvent('login_start', {'method': 'google'});
    await signInWithMember(context, googleAuthService.signInWithGoogle);
  }

  Future<void> signInWithApple(BuildContext context) async {
    AppAnalytics.logEvent('login_start', {'method': 'apple'});
    await signInWithMember(context, appleAuthService.signInWithApple);
  }

  Future<void> signInWithKakao(BuildContext context) async {
    AppAnalytics.logEvent('login_start', {'method': 'kakao'});
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
  }

  /// 로그인이 끝까지 성공했을 때 남긴다. 예전에는 토큰을 받기 전에 남겨서
  /// 실패한 로그인도 login 으로 셌다.
  void _logLoginSuccess(String? loginMethod) {
    final method = loginMethod?.toLowerCase();
    // 둘 다 GA4 추천 이벤트라 이름과 파라미터를 그대로 쓴다.
    AppAnalytics.logEvent('login', {'method': method});
    if (AppAnalytics.looksLikeSignUp(_userInfoModel?.createdAt)) {
      AppAnalytics.logEvent('sign_up', {'method': method});
    }
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
    // 옷장에 이 사람의 능력치 레벨을 넘기고, 처음이거나 레벨이 올랐으면
    // 카탈로그를 다시 읽게 한다. 화면이 읽는 쪽(userInfoModel)을 넘기는 것은
    // 디버그 패널로 옮겨 놓은 레벨을 옷장도 함께 보게 하려는 것이다.
    //
    // 기다리지 않는다. 치장은 있으면 좋은 것이지 유저 정보 조회를 붙잡고
    // 있을 것이 아니다.
    unawaited(cosmeticProvider?.syncWithUser(userInfoModel) ?? Future.value());
    // 훈장도 같이 채운다. 이쪽은 레벨을 안 보고 **처음 한 번만** 받아 온다.
    // 열두 가지 조건을 서버가 다시 세는 조회라 유저 정보가 갱신될 때마다
    // 부르면 요청만 늘고, 훈장 화면이 열릴 때마다 어차피 다시 읽는다.
    // 기다리지 않는 이유는 치장과 같다.
    unawaited(
      achievementProvider?.syncWithUser(userInfoModel) ?? Future.value(),
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
      // 서버에 물어보지 못했을 뿐이라 토큰은 지우지 않는다. 다만 로그인으로
      // 치면 데이터를 하나도 못 받은 빈 홈으로 들어가므로, 확인하지 못했다는
      // 상태로 두고 화면이 다시 시도하게 한다.
      debugPrint('자동 로그인 일시 실패: $error');
      await AppErrorReporter.report(
        error,
        stackTrace,
        source: 'auto_login_refresh',
        severity: AppErrorSeverity.warning,
      );
      _loginStatus = LoginStatus.unreachable;
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

  /// 기기에 적어 둔 로그인 방식. 비교하기 좋게 소문자로 맞춰 준다.
  ///
  /// 저장은 소셜 플랫폼 값(`'GOOGLE'`·`'APPLE'`·`'KAKAO'`)과 `'GUEST'` 라 전부
  /// 대문자인데 비교는 소문자로 하고 있어서, 로그아웃과 탈퇴의 분기가 한 번도
  /// 걸리지 않았다. 이미 대문자로 저장된 기기가 있으니 읽는 쪽에서 맞춘다.
  Future<String?> _readLoginMethod() async {
    final loginMethod = await storage.read(key: 'loginMethod');
    return loginMethod?.toLowerCase();
  }

  Future<void> signOut() async {
    String? loginMethod = await _readLoginMethod();

    if (loginMethod == 'guest') {
      // 게스트는 다시 들어올 길이 없어 로그아웃이 곧 탈퇴다.
      // deleteAccount 가 서버 계정과 기기 토큰을 모두 지우므로 여기서 끝낸다.
      // 이어서 로그아웃 요청을 보내면 토큰이 이미 없어 인증 오류가 뜬다.
      await deleteAccount(trigger: 'guest_logout');
      return;
    }

    AppAnalytics.logEvent('logout', {'method': loginMethod});

    try {
      // 소셜 SDK 로그아웃을 서버 요청보다 먼저 한다. 기기 안에서 끝나는 일이라
      // 서버가 무슨 답을 주든 함께 실패하면 안 된다.
      await _signOutFromSocialSdk(loginMethod);

      // 기기에서 토큰을 지우기 전에 보내야 한다. resetUserInfo 뒤에 보내면
      // 실을 토큰이 남아 있지 않다.
      await userService.logoutAccount(refreshToken: await _readRefreshToken());
    } catch (error, stackTrace) {
      // 서버가 로그아웃을 거절해도(인증을 요구하게 된 뒤로는 401 이 온다)
      // 사용자는 로그아웃을 누른 것이다. 여기서 멈추면 기기에 세션이 그대로
      // 남는데, 그게 서버 세션이 남는 것보다 나쁘다.
      debugPrint('로그아웃 요청 실패: $error');
      await AppErrorReporter.report(
        error,
        stackTrace,
        source: 'sign_out',
        severity: AppErrorSeverity.warning,
      );
    } finally {
      // 서버 응답이 어떻든 기기 토큰과 사용자 상태는 반드시 지운다.
      await resetUserInfo();
    }
  }

  /// 소셜 SDK 쪽 로그아웃.
  ///
  /// 여기서 실패해도 서버 로그아웃과 기기 정리는 이어가야 하므로 따로 감싼다.
  Future<void> _signOutFromSocialSdk(String? loginMethod) async {
    try {
      if (loginMethod == 'google') {
        await googleAuthService.logoutGoogleSignIn();
      } else if (loginMethod == 'kakao') {
        await kakaoAuthService.logoutKakaoSignIn();
      }
      // apple 은 별도의 로그아웃 로직이 없습니다.
    } catch (error, stackTrace) {
      debugPrint('소셜 SDK 로그아웃 실패: $error');
      await AppErrorReporter.report(
        error,
        stackTrace,
        source: 'sign_out_social_sdk',
        severity: AppErrorSeverity.warning,
      );
    }
  }

  /// 로그아웃 요청에 실을 리프레시 토큰.
  ///
  /// 못 읽어도 로그아웃 자체는 진행해야 한다. 서버 세션을 못 지우는 것보다
  /// 기기에 토큰이 남는 쪽이 나쁘다. 그래서 실패는 삼키고 null 을 돌려준다.
  Future<String?> _readRefreshToken() async {
    try {
      return await tokenProvider.getRefreshToken();
    } catch (error) {
      debugPrint('로그아웃에 실을 리프레시 토큰을 읽지 못했습니다: $error');
      return null;
    }
  }

  // 회원 탈퇴 함수
  /// 계정을 지운다. [trigger] 는 Analytics 에만 쓴다. 게스트는 로그아웃이
  /// 곧 탈퇴라, 직접 탈퇴한 것과 갈라 보지 않으면 탈퇴가 부풀려 보인다.
  Future<void> deleteAccount({String trigger = 'withdraw'}) async {
    String? loginMethod = await _readLoginMethod();
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
    // 유저 식별을 지우기 전에 남겨야 누가 나갔는지 이어 볼 수 있다.
    AppAnalytics.logEvent('user_delete', {
      'method': loginMethod,
      'trigger': trigger,
    });
    await resetUserInfo();
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
    // 비우지 않으면 다른 계정으로 로그인한 첫 화면의 하단 탭과 프로필에
    // 앞 사람이 꾸며 둔 개구리가 그대로 남는다.
    cosmeticProvider?.clear();
    // 비우지 않으면 다른 계정으로 로그인한 첫 화면에 앞 사람이 받은 훈장의
    // 축하가 뜬다. 기기에 적어 둔 축하거리까지 같이 지운다.
    achievementProvider?.clear();
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
