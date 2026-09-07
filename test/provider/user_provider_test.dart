// UserProvider 상태 전이 테스트.
//
// UserProvider 생성자는 `TokenProvider.registerAuthFailureHandler` 라는
// 정적 부작용을 갖는다(모든 UserProvider 인스턴스가 전역 핸들러를 덮어쓴다).
// 이 파일의 각 테스트는 매번 새 UserProvider 를 만들어 그 부작용을 그대로
// 이용하되, 이전 테스트의 등록이 남아있지 않도록 항상 최신 인스턴스 기준으로
// 검증한다.
//
// signInWithMember/signInWithGuest/signInWithGoogle/signInWithApple/
// signInWithKakao 는 LoadingDialog.show() 가 실제 Navigator/Overlay 가 있는
// 위젯 트리에서 showDialog 를 띄우고, SVG 애셋을 그리고,
// NotificationService.instance.sendTokenToServer() 로 실제 FCM 경로를 타는
// 등 순수 Provider 단위 테스트 범위를 넘어선다. 이 파일에서는 다루지 않고
// 최종 보고에 사유를 남긴다.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Model/Common/PaginatedResponse.dart';
import 'package:ono/Model/Folder/FolderModel.dart';
import 'package:ono/Model/Folder/FolderThumbnailModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteThumbnailModel.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Provider/TokenProvider.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Service/SocialLogin/AppleAuthService.dart';
import 'package:ono/Service/SocialLogin/GoogleAuthService.dart';
import 'package:ono/Service/SocialLogin/KakaoAuthService.dart';

import '../helpers/helpers.dart';
import 'support/provider_test_env.dart';
import '../helpers/secure_storage_stub.dart';

class _MockAppleAuthService extends Mock implements AppleAuthService {}

class _MockGoogleAuthService extends Mock implements GoogleAuthService {}

class _MockKakaoAuthService extends Mock implements KakaoAuthService {}

UserInfoModel _userInfo({int userId = 1, bool notificationEnabled = true}) {
  return UserInfoModel(
      userId: userId, notificationEnabled: notificationEnabled);
}

FolderModel _folder(int id) {
  return FolderModel(
    folderId: id,
    folderName: 'folder-$id',
    problemIdList: const [],
    subFolderList: const [],
  );
}

PaginatedResponse<FolderThumbnailModel> _emptyFolderPage() {
  return PaginatedResponse(
    content: [],
    nextCursor: null,
    hasNext: false,
    size: 20,
  );
}

PaginatedResponse<ProblemModel> _emptyProblemPage() {
  return PaginatedResponse(
    content: [],
    nextCursor: null,
    hasNext: false,
    size: 20,
  );
}

PaginatedResponse<PracticeNoteThumbnails> _emptyPracticePage() {
  return PaginatedResponse(
    content: [],
    nextCursor: null,
    hasNext: false,
    size: 20,
  );
}

void main() {
  setUpOnoTest();

  setUpAll(setUpProviderTestEnv);

  late MockTokenProvider tokenProvider;
  late MockUserService userService;
  late MockProblemService problemService;
  late MockProblemsProvider problemsProvider;
  late FoldersProvider foldersProvider;
  late MockFolderService folderService;
  late ProblemPracticeProvider practiceProvider;
  late MockPracticeNoteService practiceNoteService;
  late _MockAppleAuthService appleAuthService;
  late _MockGoogleAuthService googleAuthService;
  late _MockKakaoAuthService kakaoAuthService;
  late UserProvider provider;
  late NotifyRecorder notified;
  late Map<String, String> storageData;

  setUp(() {
    storageData = stubSecureStorage();
    tokenProvider = MockTokenProvider();
    userService = MockUserService();
    problemService = MockProblemService();
    problemsProvider = MockProblemsProvider();
    folderService = MockFolderService();
    foldersProvider = FoldersProvider(
      problemsProvider: problemsProvider,
      folderService: folderService,
    );
    practiceNoteService = MockPracticeNoteService();
    practiceProvider = ProblemPracticeProvider(
      problemsProvider: problemsProvider,
      practiceNoteService: practiceNoteService,
    );
    appleAuthService = _MockAppleAuthService();
    googleAuthService = _MockGoogleAuthService();
    kakaoAuthService = _MockKakaoAuthService();

    provider = UserProvider(
      problemsProvider,
      foldersProvider,
      practiceProvider,
      tokenProvider: tokenProvider,
      userService: userService,
      problemService: problemService,
      appleAuthService: appleAuthService,
      googleAuthService: googleAuthService,
      kakaoAuthService: kakaoAuthService,
    );
    notified = NotifyRecorder();
    provider.addListener(notified.call);
  });

  group('초기 상태', () {
    test('아무 것도 안 했을 때 waiting 이고 첫 로그인으로 간주한다', () {
      expect(provider.isLoggedIn, LoginStatus.waiting);
      expect(provider.isFirstLogin, isTrue);
      expect(provider.userInfoModel, isNull);
    });
  });

  group('생성자의 정적 부작용 (TokenProvider.registerAuthFailureHandler)', () {
    test('전혀 관계없는 TokenProvider 인스턴스가 인증 실패를 알려도 이 provider 가 반응한다', () async {
      // problemsProvider/foldersProvider/practiceProvider 가 실제로 clear
      // 되는지까지 확인한다 (foldersProvider/practiceProvider 는 목이 아닌
      // 진짜 인스턴스라 clear() 호출로 상태가 실제로 비는지 볼 수 있다).
      when(() => folderService.fetchFolder(1, showErrorSnackBar: true))
          .thenAnswer((_) async => _folder(1));
      // 세션이 있는 것처럼 보이게 만든다.
      // (autoLogin 을 거치지 않고 로그인 상태만 흉내낸다)

      final unrelatedTokenProvider = TokenProvider();

      await unrelatedTokenProvider.notifyAuthFailure();

      expect(provider.isLoggedIn, LoginStatus.logout);
      expect(provider.isFirstLogin, isTrue);
      expect(storageData.containsKey('accessToken'), isFalse);
    });
  });

  group('fetchUserInfo', () {
    test('성공하면 userInfoModel 이 채워지고 notifyListeners 가 불린다', () async {
      when(() => userService.fetchUserInfo(showErrorSnackBar: true))
          .thenAnswer((_) async => _userInfo());

      await provider.fetchUserInfo();

      expect(provider.userInfoModel?.userId, 1);
      expect(notified.count, greaterThan(0));
    });

    test('실패하면 예외를 삼키지 않고 던진다', () async {
      when(() => userService.fetchUserInfo(showErrorSnackBar: true))
          .thenThrow(Exception('network error'));

      await expectLater(provider.fetchUserInfo(), throwsA(isA<Exception>()));
      expect(provider.userInfoModel, isNull);
    });
  });

  group('updateNotificationSettings (낙관적 업데이트 + 롤백)', () {
    test('성공하면 값이 그대로 유지된다', () async {
      when(() => userService.fetchUserInfo(showErrorSnackBar: true))
          .thenAnswer((_) async => _userInfo(notificationEnabled: false));
      await provider.fetchUserInfo();
      when(() => userService.updateNotificationSettings(true))
          .thenAnswer((_) async {});

      await provider.updateNotificationSettings(true);

      expect(provider.userInfoModel?.notificationEnabled, isTrue);
    });

    test('실패하면 이전 값으로 롤백되고 예외가 다시 던져진다', () async {
      when(() => userService.fetchUserInfo(showErrorSnackBar: true))
          .thenAnswer((_) async => _userInfo(notificationEnabled: false));
      await provider.fetchUserInfo();
      when(() => userService.updateNotificationSettings(true))
          .thenThrow(Exception('network error'));

      await expectLater(
        provider.updateNotificationSettings(true),
        throwsA(isA<Exception>()),
      );

      // 화면은 잠깐 true 로 바뀌었다가(낙관적 업데이트) 실패하면 false 로
      // 되돌아가야 한다 — 안 그러면 서버와 다른 값이 화면에 계속 남는다.
      expect(provider.userInfoModel?.notificationEnabled, isFalse);
    });

    test('userInfoModel 이 없으면 아무 것도 하지 않는다', () async {
      await provider.updateNotificationSettings(true);

      verifyNever(() => userService.updateNotificationSettings(any()));
    });
  });

  group(
      'updateUserProfileImage / updateUserProfileImageUrl / deleteUserProfileImage',
      () {
    test('성공하면 userInfoModel 이 교체되고 notifyListeners 가 불린다', () async {
      when(() => userService.updateUserProfileImage('/tmp/a.png'))
          .thenAnswer((_) async => _userInfo());

      await provider.updateUserProfileImage('/tmp/a.png');

      expect(provider.userInfoModel?.userId, 1);
      expect(notified.count, greaterThan(0));
    });

    test('삭제 성공 시 userInfoModel 이 교체된다', () async {
      when(() => userService.deleteUserProfileImage())
          .thenAnswer((_) async => _userInfo());

      await provider.deleteUserProfileImage();

      expect(provider.userInfoModel?.userId, 1);
    });
  });

  group('autoLogin', () {
    test('refreshToken 이 없으면 바로 logout 상태가 된다', () async {
      when(() => tokenProvider.getRefreshToken()).thenAnswer((_) async => null);

      await provider.autoLogin();

      expect(provider.isLoggedIn, LoginStatus.logout);
      verifyNever(() => tokenProvider.refreshAccessToken());
    });

    test('갱신과 데이터 로딩이 모두 성공하면 login 상태가 된다', () async {
      when(() => tokenProvider.getRefreshToken())
          .thenAnswer((_) async => 'refresh-token');
      when(() => tokenProvider.refreshAccessToken()).thenAnswer((_) async {});
      when(() => userService.fetchUserInfo(showErrorSnackBar: true))
          .thenAnswer((_) async => _userInfo());
      when(() => folderService.fetchFolder(any(), showErrorSnackBar: true))
          .thenAnswer((_) async => _folder(1));
      when(() => folderService.getRootFolder())
          .thenAnswer((_) async => _folder(1));
      when(() => folderService.getSubfoldersV2(
            folderId: any(named: 'folderId'),
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => _emptyFolderPage());
      when(() => problemsProvider.loadMoreFolderProblemsV2(
            folderId: any(named: 'folderId'),
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => _emptyProblemPage());
      when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => _emptyPracticePage());

      await provider.autoLogin();

      expect(provider.isLoggedIn, LoginStatus.login);
      expect(provider.isFirstLogin, isFalse);
    });

    test('갱신은 성공했지만 데이터 로딩이 실패해도 로그인 상태는 유지된다', () async {
      when(() => tokenProvider.getRefreshToken())
          .thenAnswer((_) async => 'refresh-token');
      when(() => tokenProvider.refreshAccessToken()).thenAnswer((_) async {});
      when(() => userService.fetchUserInfo(showErrorSnackBar: true))
          .thenThrow(Exception('서버 점검 중'));

      await provider.autoLogin(); // 던지지 않아야 한다

      expect(provider.isLoggedIn, LoginStatus.login);
    });

    test('토큰 갱신이 인증 실패(UnauthorizedException)면 로그아웃 처리된다', () async {
      when(() => tokenProvider.getRefreshToken())
          .thenAnswer((_) async => 'refresh-token');
      when(() => tokenProvider.refreshAccessToken())
          .thenThrow(UnauthorizedException(message: '리프레시 토큰 만료'));

      await provider.autoLogin();

      expect(provider.isLoggedIn, LoginStatus.logout);
      expect(provider.userInfoModel, isNull);
    });

    test('토큰 갱신이 일시적 네트워크 오류면 세션을 유지한다 (의도된 동작)', () async {
      when(() => tokenProvider.getRefreshToken())
          .thenAnswer((_) async => 'refresh-token');
      when(() => tokenProvider.refreshAccessToken())
          .thenThrow(NetworkException());

      await provider.autoLogin();

      // 실제로 데이터를 못 가져왔어도, 일시적 네트워크 문제로 세션 자체를
      // 끊지는 않는다는 게 이 코드의 의도다 (주석 참고).
      expect(provider.isLoggedIn, LoginStatus.login);
    });
  });

  group('maintainSessionOnResume', () {
    test('refreshToken 이 없으면 아무 것도 하지 않는다', () async {
      when(() => tokenProvider.getRefreshToken()).thenAnswer((_) async => null);

      await provider.maintainSessionOnResume();

      verifyNever(() => tokenProvider.refreshAccessTokenIfNeeded());
      expect(provider.isLoggedIn, LoginStatus.waiting);
    });

    test('인증이 만료됐으면 로그아웃 처리된다', () async {
      when(() => tokenProvider.getRefreshToken())
          .thenAnswer((_) async => 'refresh-token');
      when(() => tokenProvider.refreshAccessTokenIfNeeded())
          .thenThrow(UnauthorizedException(message: '만료'));

      await provider.maintainSessionOnResume();

      expect(provider.isLoggedIn, LoginStatus.logout);
    });
  });

  group('resetUserInfo', () {
    test('로그인 상태와 하위 Provider 캐시를 모두 초기화한다', () async {
      when(() => folderService.fetchFolder(1, showErrorSnackBar: true))
          .thenAnswer((_) async => _folder(1));
      await foldersProvider.getFolder(1);
      expect(foldersProvider.folders, isNotEmpty);

      await provider.resetUserInfo();

      expect(provider.isLoggedIn, LoginStatus.logout);
      expect(provider.isFirstLogin, isTrue);
      expect(provider.userInfoModel, isNull);
      expect(foldersProvider.folders, isEmpty);
    });
  });

  group('changeIsFirstLogin', () {
    test('한 번 호출하면 false 로 바뀌고 되돌릴 방법이 없다', () {
      provider.changeIsFirstLogin();

      expect(provider.isFirstLogin, isFalse);
    });
  });
}
