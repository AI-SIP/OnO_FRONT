import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:ono/Module/Text/StandardText.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Provider/ScreenIndexProvider.dart';
import 'package:ono/Screen/ProblemRegister/ProblemRegisterScreen.dart';
import 'package:ono/Screen/User/SplashScreen.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'Config/firebase_options.dart';
import 'Provider/UserProvider.dart';
import 'Screen/Folder/DirectoryScreen.dart';
import 'Screen/PracticeNote/PracticeThumbnailScreen.dart';
import 'Screen/User/SettingScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  KakaoSdk.init(nativeAppKey: '7fd2fa49895af63319fd6b11e084d0d5');

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://ef02bb2a25f04c4141b3edb8c51ff128@o4507978249273344.ingest.us.sentry.io/4507978250911744';
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
    },
  );

  // 1) Flutter 프레임워크 예외 (동기 빌드 에러 등) 잡기
  FlutterError.onError = (FlutterErrorDetails details) {
    // 콘솔에도 출력
    FlutterError.dumpErrorToConsole(details);

    print(details);

    // Sentry에 보고
    Sentry.captureException(
      details.exception,
      stackTrace: details.stack,
    );
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FoldersProvider()),
        ChangeNotifierProvider(create: (_) => ProblemPracticeProvider()),
        ChangeNotifierProvider(
          create: (context) => UserProvider(
            Provider.of<FoldersProvider>(context, listen: false),
            Provider.of<ProblemPracticeProvider>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
            create: (context) => ThemeHandler()..loadColors()),
        ChangeNotifierProvider(create: (_) => ScreenIndexProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OnO',
      theme: _buildThemeData(context),
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
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final secureStorage = const FlutterSecureStorage();
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
    Provider.of<ScreenIndexProvider>(context, listen: false)
        .setSelectedIndex(index);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      // 앱이 백그라운드로 전환될 때 시간 저장
      await secureStorage.write(
        key: 'lastPaused',
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } else if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 전환될 때 시간 비교
      String? lastPaused = await secureStorage.read(key: 'lastPaused');
      if (lastPaused != null) {
        final difference =
            DateTime.now().millisecondsSinceEpoch - int.parse(lastPaused);
        final minutes = difference / 1000 / 60;
        if (minutes > 1) {
          _resetAppState();
        }
      }
    }
  }

  void _resetAppState() {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    userProvider.autoLogin();
    //userProvider.fetchAllData();
    //foldersProvider.fetchAllFolderContents();
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
        fontSize: screenHeight * 0.013,
      ),
      onTap: _onItemTapped,
    );
  }

  List<BottomNavigationBarItem> _bottomNavigationItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.menu_book),
        label: '오답 관리',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: '오답 복습',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.edit),
        label: '오답노트 작성',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: '설정',
      ),
    ];
  }
}
