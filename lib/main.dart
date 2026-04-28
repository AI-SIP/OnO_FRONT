import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'Config/firebase_options.dart';
import 'Provider/PracticeNoteProvider.dart';
import 'Provider/ProblemsProvider.dart';
import 'Provider/UserProvider.dart';
import 'Screen/Folder/DirectoryScreen.dart';
import 'Screen/PracticeNote/PracticeThumbnailScreen.dart';
import 'Screen/User/MyPageScreen.dart';
import 'Util/AppErrorReporter.dart';
import 'Util/NotificationService.dart';
import 'Util/AppSnackBar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await SentryFlutter.init(
    (options) {
      options.dsn = dotenv.env['SENTRY_DSN'] ?? '';
      options.profilesSampleRate = 0.0;
      options.tracesSampleRate = 1.0;
    },
    appRunner: () {
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

      runZonedGuarded<Future<void>>(
        _bootstrapApp,
        (error, stackTrace) async {
          await AppErrorReporter.report(
            error,
            stackTrace,
            source: 'zoned_guarded',
            severity: AppErrorSeverity.fatal,
          );
        },
      );
    },
  );
}

Future<void> _bootstrapApp() async {
  await AppConfig.load();

  if (Firebase.apps.where((app) => app.name == 'OnO').isEmpty) {
    await Firebase.initializeApp(
      name: 'OnO',
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await NotificationService.instance.init();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final kakaoNativeAppKey = dotenv.env['KAKAO_NATIVE_APP_KEY']?.trim();
  if (kakaoNativeAppKey == null || kakaoNativeAppKey.isEmpty) {
    log('KAKAO_NATIVE_APP_KEY is not configured.');
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
  static const List<Widget> _widgetOptions = <Widget>[
    DirectoryScreen(),
    PracticeThumbnailScreen(),
    ProblemRegisterScreen(problemModel: null, isEditMode: false),
    //TemplateSelectionScreen(),
    SettingScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

    return Scaffold(
      body: IndexedStack(
        index: screenIndexProvider.screenIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final standardTextStyle = const StandardText(text: '').getTextStyle();
    final screenIndexProvider = Provider.of<ScreenIndexProvider>(context);
    double screenHeight = MediaQuery.of(context).size.height;

    return BottomNavigationBar(
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      items: _bottomNavigationItems(),
      currentIndex: screenIndexProvider.screenIndex,
      selectedItemColor: themeProvider.primaryColor,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: standardTextStyle.copyWith(
        color: themeProvider.primaryColor,
        fontSize: screenHeight * 0.015,
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
          icon: Icon(Icons.menu_book, size: 20), label: '노트 관리'),
      BottomNavigationBarItem(
          icon: Icon(Icons.history, size: 20), label: '오답 복습'),
      BottomNavigationBarItem(
          icon: Icon(
            Icons.edit,
            size: 20,
          ),
          label: '오답노트 작성'),
      BottomNavigationBarItem(
          icon: Icon(
            Icons.person,
            size: 20,
          ),
          label: '마이 페이지'),
    ];
  }
}
