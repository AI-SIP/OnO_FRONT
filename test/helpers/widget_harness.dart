import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:ono/Provider/ReviewDueProvider.dart';
import 'package:ono/Provider/ScreenIndexProvider.dart';
import 'package:ono/Provider/StudyRoomProvider.dart';
import 'package:ono/Provider/TutorialProvider.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Util/AppSnackBar.dart';
import 'package:provider/provider.dart';

import 'firebase_analytics_stub.dart';
import 'secure_storage_stub.dart';
import 'test_setup.dart';

/// 위젯 테스트 파일의 main() 맨 앞에서 한 번 부른다.
///
/// ```dart
/// void main() {
///   setUpOnoWidgetTest();
///
///   testWidgets('로그인 화면이 뜬다', (tester) async {
///     await pumpOnoWidget(tester, const LoginScreen());
///     expect(find.text('로그인'), findsOneWidget);
///   });
/// }
/// ```
///
/// [setUpOnoTest] 가 하는 일에 더해, 위젯을 그릴 때 플랫폼 채널을 타는 것들을
/// 가짜로 바꿔 끼운다. FirebaseAnalytics 와 FlutterSecureStorage(ThemeHandler 가
/// 생성자에서 색상을 읽는다)가 그 대상이다.
void setUpOnoWidgetTest() {
  setUpOnoTest();
  stubFirebaseAnalytics();
  stubSecureStorage();
}

/// 화면 크기 프리셋. 반응형이 1차 환경이라 둘 다 돌려 보는 게 좋다.
class OnoSurface {
  /// 아이폰 14 세로. 기본값.
  static const phone = Size(390, 844);

  /// 작은 폰. 글자가 넘치는지 볼 때.
  static const smallPhone = Size(320, 640);

  /// 아이패드 세로. 600 이상이면 앱이 태블릿 레이아웃으로 분기한다.
  static const tablet = Size(834, 1194);
}

/// 앱과 같은 Provider 트리와 MaterialApp 으로 감싸서 [child] 를 띄운다.
///
/// Provider 는 넘기지 않으면 진짜 구현을 기본 생성자로 만든다. 그러면 안에서
/// 진짜 Service 가 만들어져 네트워크를 타므로, **화면이 실제로 읽는 Provider 는
/// 반드시 넘겨라.** mock 서비스를 물린 진짜 Provider 를 넘기는 쪽이 편하다.
///
/// ```dart
/// final problemService = MockProblemService();
/// when(() => problemService.getProblemCount())
///     .thenAnswer((_) async => 3);
///
/// await pumpOnoWidget(
///   tester,
///   const SomeScreen(),
///   problemsProvider: ProblemsProvider(problemService: problemService),
/// );
/// ```
Future<void> pumpOnoWidget(
  WidgetTester tester,
  Widget child, {
  ProblemsProvider? problemsProvider,
  FoldersProvider? foldersProvider,
  ProblemPracticeProvider? practiceProvider,
  UserProvider? userProvider,
  StudyRoomProvider? studyRoomProvider,
  ReviewDueProvider? reviewDueProvider,
  TutorialProvider? tutorialProvider,
  ScreenIndexProvider? screenIndexProvider,
  ThemeHandler? themeHandler,
  Size surfaceSize = OnoSurface.phone,
  List<NavigatorObserver> navigatorObservers = const [],
  Map<String, WidgetBuilder> routes = const {},

  /// false 로 두면 pumpAndSettle 대신 pump 한 번만 한다.
  /// 화면에 끝나지 않는 애니메이션(로딩 인디케이터 등)이 있으면 settle 이 타임아웃난다.
  bool settle = true,
}) async {
  await setSurfaceSize(tester, surfaceSize);

  final problems = problemsProvider ?? ProblemsProvider();
  final folders =
      foldersProvider ?? FoldersProvider(problemsProvider: problems);
  final practice =
      practiceProvider ?? ProblemPracticeProvider(problemsProvider: problems);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProblemsProvider>.value(value: problems),
        ChangeNotifierProvider<FoldersProvider>.value(value: folders),
        ChangeNotifierProvider<ProblemPracticeProvider>.value(value: practice),
        ChangeNotifierProvider<UserProvider>.value(
          value: userProvider ?? UserProvider(problems, folders, practice),
        ),
        ChangeNotifierProvider<ThemeHandler>.value(
          value: themeHandler ?? ThemeHandler(),
        ),
        ChangeNotifierProvider<ScreenIndexProvider>.value(
          value: screenIndexProvider ?? ScreenIndexProvider(),
        ),
        ChangeNotifierProvider<ReviewDueProvider>.value(
          value: reviewDueProvider ?? ReviewDueProvider(),
        ),
        ChangeNotifierProvider<TutorialProvider>.value(
          value: tutorialProvider ?? TutorialProvider(),
        ),
        ChangeNotifierProvider<StudyRoomProvider>.value(
          value: studyRoomProvider ?? StudyRoomProvider(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final theme = Provider.of<ThemeHandler>(context);
          return MaterialApp(
            // 앱과 같은 키를 물려야 AppSnackBar.showError 가 실제로 스낵바를 띄운다.
            scaffoldMessengerKey: AppSnackBar.messengerKey,
            navigatorObservers: navigatorObservers,
            routes: routes,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: theme.primaryColor),
              primaryColor: theme.primaryColor,
              useMaterial3: true,
              dialogTheme: const DialogThemeData(
                constraints: BoxConstraints(maxWidth: 420),
              ),
            ),
            debugShowCheckedModeBanner: false,
            home: child,
          );
        },
      ),
    ),
  );

  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// 테스트 화면 크기를 바꾼다. 테스트가 끝나면 자동으로 되돌린다.
Future<void> setSurfaceSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// 1x1 투명 PNG. 네트워크 이미지 응답으로 돌려준다.
final Uint8List kTransparentPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// [body] 안에서 일어나는 모든 네트워크 이미지 요청에 투명 PNG 를 돌려준다.
///
/// `Image.network` 와 `CachedNetworkImage` 는 테스트 환경에서 실제 HTTP 를
/// 시도하고 400 을 받아 `EXCEPTION CAUGHT BY IMAGE RESOURCE SERVICE` 로 테스트를
/// 깨뜨린다. 이미지를 그리는 화면은 이걸로 감싼다.
///
/// ```dart
/// await withMockedNetworkImages(() async {
///   await pumpOnoWidget(tester, const SomeScreen());
/// });
/// ```
Future<T> withMockedNetworkImages<T>(Future<T> Function() body) {
  return HttpOverrides.runZoned(
    body,
    createHttpClient: (_) => _FakeImageHttpClient(),
  );
}

// ── 아래는 네트워크 이미지 가짜 응답 구현 ────────────────────────────

class _FakeImageHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  Duration? connectionTimeout;
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeImageRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeImageRequest();

  @override
  void close({bool force = false}) {}

  @override
  noSuchMethod(Invocation invocation) => throw UnsupportedError(
      '테스트에서 지원하지 않는 HttpClient 호출: ${invocation.memberName}');
}

class _FakeImageRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeImageResponse();

  @override
  Future<HttpClientResponse> get done async => _FakeImageResponse();

  @override
  noSuchMethod(Invocation invocation) => null;
}

class _FakeImageResponse implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => kTransparentPngBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(kTransparentPngBytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  noSuchMethod(Invocation invocation) => null;
}
