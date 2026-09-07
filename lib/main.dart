import 'dart:async';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:ono/Module/Text/StandardText.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/ScreenIndexProvider.dart';
import 'package:ono/Screen/ProblemRegister/ProblemRegisterScreen.dart';
import 'package:ono/Screen/User/SplashScreen.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'Config/AppConfig.dart';
import 'Provider/PracticeNoteProvider.dart';
import 'Provider/ProblemsProvider.dart';
import 'Provider/ReviewDueProvider.dart';
import 'Provider/StudyRoomProvider.dart';
import 'Provider/UserProvider.dart';
import 'Provider/TutorialProvider.dart';
import 'Screen/Folder/DirectoryScreen.dart';
import 'Screen/PracticeNote/PracticeThumbnailScreen.dart';
import 'Screen/StudyRoom/StudyRoomListScreen.dart';
import 'Screen/Tutorial/TutorialOverlay.dart';
import 'Screen/Tutorial/TutorialTargets.dart';
import 'Screen/User/MyPageScreen.dart';
import 'Util/AppErrorReporter.dart';
import 'Util/AppNavigator.dart';
import 'Util/AppSnackBar.dart';
import 'Util/NotificationService.dart';
import 'Module/Notice/ServiceNoticeDialog.dart';
import 'Service/Api/Notice/NoticeService.dart';
import 'Module/Motion/AppHaptic.dart';
import 'Module/Motion/AppScrollBehavior.dart';
import 'Module/Motion/BouncyNavIcon.dart';
import 'Module/Motion/TabSwitchFade.dart';
import 'Module/Motion/TossPageRoute.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: '.env');

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        unawaited(
          AppErrorReporter.report(
            details.exception,
            details.stack ?? StackTrace.current,
            source: 'flutter_error',
            severity: AppErrorSeverity.fatal,
          ),
        );
      };

      PlatformDispatcher.instance.onError = (error, stackTrace) {
        unawaited(
          AppErrorReporter.report(
            error,
            stackTrace,
            source: 'platform_dispatcher',
            severity: AppErrorSeverity.fatal,
          ),
        );
        return true;
      };

      await SentryFlutter.init(
        (options) {
          options.dsn = dotenv.env['SENTRY_DSN'] ?? '';
          options.profilesSampleRate = 0.0;
          options.tracesSampleRate = 1.0;
        },
        appRunner: _bootstrapApp,
      );
    },
    (error, stackTrace) async {
      await AppErrorReporter.report(
        error,
        stackTrace,
        source: 'zoned_guarded',
        severity: AppErrorSeverity.fatal,
      );
    },
  );
}

Future<void> _bootstrapApp() async {
  await AppConfig.load();

  await initializeOnOFirebaseApp();

  await NotificationService.instance.init();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final kakaoNativeAppKey = dotenv.env['KAKAO_NATIVE_APP_KEY']?.trim();
  if (kakaoNativeAppKey == null || kakaoNativeAppKey.isEmpty) {
    debugPrint('KAKAO_NATIVE_APP_KEY is not configured.');
  } else {
    KakaoSdk.init(nativeAppKey: kakaoNativeAppKey);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProblemsProvider()),
        ChangeNotifierProvider(
          create: (context) => FoldersProvider(
            problemsProvider: Provider.of<ProblemsProvider>(
              context,
              listen: false,
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ProblemPracticeProvider(
            problemsProvider: Provider.of<ProblemsProvider>(
              context,
              listen: false,
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => UserProvider(
            Provider.of<ProblemsProvider>(context, listen: false),
            Provider.of<FoldersProvider>(context, listen: false),
            Provider.of<ProblemPracticeProvider>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeHandler()..loadColors(),
        ),
        ChangeNotifierProvider(create: (_) => ScreenIndexProvider()),
        ChangeNotifierProvider(create: (_) => ReviewDueProvider()),
        ChangeNotifierProvider(create: (_) => TutorialProvider()),
        ChangeNotifierProvider(create: (_) => StudyRoomProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: analytics,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OnO',
      theme: _buildThemeData(context),
      scaffoldMessengerKey: AppSnackBar.messengerKey,
      navigatorKey: AppNavigator.navigatorKey,
      navigatorObservers: <NavigatorObserver>[observer],
      scrollBehavior: const AppScrollBehavior(),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        if (settings.name == '/problemRegister') {
          final args = settings.arguments as Map<String, dynamic>;
          return TossPageRoute(
            builder: (context) {
              return ProblemRegisterScreen(
                problemModel: args['problemModel'],
                isEditMode: args['isEditMode'],
              );
              /*
              return ProblemRegisterScreen(
                problemModel: args['problemModel'],
                isEditMode: args['isEditMode'],
                colorPickerResult: args['colorPickerResult'],
                coordinatePickerResult: args['coordinatePickerResult'],
              );
               */
            },
          );
        }
        return null; // Other routes can be handled here
      },
    );
  }

  ThemeData _buildThemeData(BuildContext context) {
    final themeHandler = Provider.of<ThemeHandler>(context);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: themeHandler.primaryColor),
      primaryColor: themeHandler.primaryColor,
      useMaterial3: true,
      // 물결 효과를 앱 전체에서 끈다. 눌림은 PressableScale 의 축소로
      // 표현하는데, 아직 남아 있는 TextButton 과 IconButton 이 물결을
      // 그리면 같은 앱 안에서 두 가지 반응이 섞인다.
      // 화면마다 회색이거나 테마색이거나 두께가 달랐다. 기본값을 맞춰 두면
      // 색을 따로 넘기지 않은 곳도 같은 모양이 된다.
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: themeHandler.primaryColor,
        circularTrackColor: Colors.transparent,
        linearTrackColor: Colors.grey[200],
        strokeWidth: 3,
      ),
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      dialogTheme: const DialogThemeData(
        constraints: BoxConstraints(maxWidth: 420),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final TutorialTargets _tutorialTargets = TutorialTargets();
  final NoticeService _noticeService = NoticeService();
  bool _didPrepareTutorial = false;
  bool _didHandleNotice = false;
  int? _lastSyncedTutorialStepIndex;

  /// 튜토리얼이 끝나기를 기다리는 동안 붙여 둔 리스너다. 기다리는 도중에
  /// 화면이 사라지면 dispose 에서 떼야 해서 들고 있는다.
  TutorialProvider? _watchedTutorialProvider;
  VoidCallback? _tutorialFinishListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _prepareInitialTutorial();
      await _prepareServiceNotice();
    });
  }

  @override
  void dispose() {
    _detachTutorialFinishListener();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onItemTapped(int index) {
    final provider = Provider.of<ScreenIndexProvider>(context, listen: false);
    // 이미 보고 있는 탭을 다시 눌렀을 때까지 진동을 주면 손이 피곤하다.
    if (provider.screenIndex != index) AppHaptic.selection();
    provider.setSelectedIndex(index);
  }

  Future<void> _prepareInitialTutorial() async {
    if (_didPrepareTutorial || !mounted) return;
    _didPrepareTutorial = true;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final tutorialProvider =
        Provider.of<TutorialProvider>(context, listen: false);
    await tutorialProvider.showAutoIntroIfNeeded(
      userInfo: userProvider.userInfoModel,
      isFirstLogin: userProvider.isFirstLogin,
    );
    userProvider.changeIsFirstLogin();
  }

  /// 메인에 들어온 뒤 서비스 공지가 있으면 한 번 띄운다.
  ///
  /// 공지는 있으면 좋은 것이라 실패해도 앱 진입을 막지 않는다. 조회와
  /// 숨기기 모두 [NoticeService] 안에서 예외를 삼키고 null 또는 false 를
  /// 돌려준다.
  Future<void> _prepareServiceNotice() async {
    if (_didHandleNotice || !mounted) return;
    _didHandleNotice = true;

    final tutorialProvider =
        Provider.of<TutorialProvider>(context, listen: false);
    // 튜토리얼이 떠 있는데 공지를 겹쳐 띄우면, 처음 들어온 사용자가 튜토리얼
    // 위에 덮인 팝업부터 만나게 된다. 튜토리얼이 끝난 뒤로 미룬다.
    if (tutorialProvider.isVisible) {
      await _waitForTutorialToFinish(tutorialProvider);
      if (!mounted) return;
    }

    final notice = await _noticeService.getActiveNotice();
    if (notice == null || !mounted) return;

    final result = await ServiceNoticeDialog.show(context, notice);
    if (result == NoticeDialogResult.dismissed) {
      await _noticeService.dismissNotice(notice.noticeId);
    }
  }

  Future<void> _waitForTutorialToFinish(TutorialProvider provider) {
    final completer = Completer<void>();

    void listener() {
      if (provider.isVisible) return;
      _detachTutorialFinishListener();
      if (!completer.isCompleted) completer.complete();
    }

    _watchedTutorialProvider = provider;
    _tutorialFinishListener = listener;
    provider.addListener(listener);
    return completer.future;
  }

  void _detachTutorialFinishListener() {
    final listener = _tutorialFinishListener;
    if (listener != null) {
      _watchedTutorialProvider?.removeListener(listener);
    }
    _watchedTutorialProvider = null;
    _tutorialFinishListener = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.maintainSessionOnResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenIndexProvider = Provider.of<ScreenIndexProvider>(context);
    final tutorialProvider = Provider.of<TutorialProvider>(context);
    _syncTutorialTab(tutorialProvider, screenIndexProvider);

    final widgetOptions = <Widget>[
      DirectoryScreen(tutorialTargets: _tutorialTargets),
      PracticeThumbnailScreen(tutorialTargets: _tutorialTargets),
      StudyRoomListScreen(tutorialTargets: _tutorialTargets),
      SettingScreen(tutorialTargets: _tutorialTargets),
    ];

    return Stack(
      children: [
        Scaffold(
          body: TabSwitchFade(
            index: screenIndexProvider.screenIndex,
            child: IndexedStack(
              index: screenIndexProvider.screenIndex,
              children: widgetOptions,
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(context),
        ),
        TutorialOverlay(targets: _tutorialTargets),
      ],
    );
  }

  void _syncTutorialTab(
    TutorialProvider tutorialProvider,
    ScreenIndexProvider screenIndexProvider,
  ) {
    if (!tutorialProvider.isRunning) {
      _lastSyncedTutorialStepIndex = null;
      return;
    }

    final stepIndex = tutorialProvider.currentStepIndex;
    final targetTabIndex = tutorialProvider.currentStep.tabIndex;
    if (_lastSyncedTutorialStepIndex == stepIndex &&
        screenIndexProvider.screenIndex == targetTabIndex) {
      return;
    }

    _lastSyncedTutorialStepIndex = stepIndex;
    if (screenIndexProvider.screenIndex == targetTabIndex) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<ScreenIndexProvider>(context, listen: false)
          .setSelectedIndex(targetTabIndex);
    });
  }

  BottomNavigationBar _buildBottomNavigationBar(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final standardTextStyle = const StandardText(text: '').getTextStyle();
    final screenIndexProvider = Provider.of<ScreenIndexProvider>(context);
    double screenHeight = MediaQuery.of(context).size.height;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final selectedLabelFontSize = screenHeight * 0.015 - (isMobile ? 1.0 : 0.0);

    return BottomNavigationBar(
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      items: _bottomNavigationItems(
        themeProvider.primaryColor,
        screenIndexProvider.screenIndex,
      ),
      currentIndex: screenIndexProvider.screenIndex,
      selectedItemColor: themeProvider.primaryColor,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: standardTextStyle.copyWith(
        color: themeProvider.primaryColor,
        fontSize: selectedLabelFontSize,
      ),
      unselectedLabelStyle: standardTextStyle.copyWith(
        color: Colors.grey,
        fontSize: screenHeight * 0.012,
      ),
      onTap: _onItemTapped,
    );
  }

  /// 아이콘을 [BouncyNavIcon] 으로 감싸서 선택될 때 한 번 튀어오르게 한다.
  /// 선택 여부를 아이콘이 직접 알아야 해서 `activeIcon` 을 쓰지 않는다.
  List<BottomNavigationBarItem> _bottomNavigationItems(
    Color activeColor,
    int currentIndex,
  ) {
    const specs = <({IconData icon, IconData activeIcon, String label})>[
      (
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book,
        label: '오답노트 관리'
      ),
      (icon: Icons.history_outlined, activeIcon: Icons.history, label: '복습 세트'),
      (icon: Icons.group_outlined, activeIcon: Icons.group, label: '스터디룸'),
      (icon: Icons.person_outline, activeIcon: Icons.person, label: '마이 페이지'),
    ];

    return List<BottomNavigationBarItem>.generate(specs.length, (index) {
      final spec = specs[index];
      return BottomNavigationBarItem(
        icon: BouncyNavIcon(
          icon: spec.icon,
          activeIcon: spec.activeIcon,
          selected: currentIndex == index,
          activeColor: activeColor,
          inactiveColor: Colors.grey,
        ),
        label: spec.label,
      );
    });
  }
}
