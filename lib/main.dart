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
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        if (settings.name == '/problemRegister') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
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
  bool _didPrepareTutorial = false;
  int? _lastSyncedTutorialStepIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareInitialTutorial();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onItemTapped(int index) {
    Provider.of<ScreenIndexProvider>(
      context,
      listen: false,
    ).setSelectedIndex(index);
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
          body: IndexedStack(
            index: screenIndexProvider.screenIndex,
            children: widgetOptions,
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
    final selectedLabelFontSize =
        screenHeight * 0.015 - (isMobile ? 1.0 : 0.0);

    return BottomNavigationBar(
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      items: _bottomNavigationItems(),
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

  List<BottomNavigationBarItem> _bottomNavigationItems() {
    return const [
      BottomNavigationBarItem(
          icon: Icon(Icons.menu_book, size: 20), label: '오답노트 관리'),
      BottomNavigationBarItem(
          icon: Icon(Icons.history, size: 20), label: '복습 세트'),
      BottomNavigationBarItem(icon: Icon(Icons.group, size: 20), label: '스터디룸'),
      BottomNavigationBarItem(
          icon: Icon(
            Icons.person,
            size: 20,
          ),
          label: '마이 페이지'),
    ];
  }
}
