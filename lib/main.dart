import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:ono/GlobalModule/Theme/ThemeHandler.dart';
import 'package:ono/Model/LoginStatus.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Screen/SplashScreen.dart';
import 'package:ono/Screen/TemplateSelectionScreen.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'Provider/UserProvider.dart';
import 'Screen/HomeScreen.dart';
import 'Screen/DirectoryScreen.dart';
import 'Screen/ProblemRegisterScreen.dart';
import 'Screen/SettingScreen.dart';
import 'GlobalModule/Theme/AppbarWithLogo.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  KakaoSdk.init(nativeAppKey: '7fd2fa49895af63319fd6b11e084d0d5');

  await SentryFlutter.init(
          (options) {
        options.dsn = 'https://ef02bb2a25f04c4141b3edb8c51ff128@o4507978249273344.ingest.us.sentry.io/4507978250911744';
        options.tracesSampleRate = 1.0;
        options.profilesSampleRate = 1.0;
      },
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FoldersProvider()),
        ChangeNotifierProvider(
          create: (context) => UserProvider(
            Provider.of<FoldersProvider>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
            create: (context) => ThemeHandler()..loadColors()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Flutter Demo',
      theme: _buildThemeData(context),
      navigatorObservers: <NavigatorObserver>[observer],
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver{
  int _selectedIndex = 0;
  final secureStorage = const FlutterSecureStorage();
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    TemplateSelectionScreen(),
    //ProblemRegisterScreen(),
    DirectoryScreen(),
    SettingScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    autoLogin();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  Future<void> autoLogin() async {
    try {
      await Provider.of<UserProvider>(context, listen: false).autoLogin();
    } catch (e) {
      log('Auto login failed: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // 탭된 아이템에 따른 스크린 뷰 기록
    switch (index) {
      case 0:
        _sendScreenView('HomeScreen');
        break;
      case 1:
        _sendScreenView('ProblemRegisterScreen');
        break;
      case 2:
        _sendScreenView('DirectoryScreen');
        break;
      case 3:
        _sendScreenView('SettingScreen');
        break;
    }
  }

  // FirebaseAnalytics에 스크린 뷰를 기록하는 함수
  Future<void> _sendScreenView(String screenName) async {
    FirebaseAnalytics.instance.logScreenView(
      screenName: screenName,
    );
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
        final difference = DateTime.now().millisecondsSinceEpoch - int.parse(lastPaused);
        final minutes = difference / 1000 / 60;
        if (minutes > 1) {
          _resetAppState();
        }
      }
    }
  }

  void _resetAppState() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final foldersProvider = Provider.of<FoldersProvider>(context, listen: false);

    if(userProvider.loginStatus == LoginStatus.login){
      setState(() {
        _selectedIndex = 2;
      });
      foldersProvider.fetchRootFolderContents();
    } else{
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (_selectedIndex == 1 || _selectedIndex == 2)
          ? null // DirectoryScreen을 위한 조건 (index 2일 경우 AppBar를 제거)
          : const AppBarWithLogo(), // 다른 화면에서는 AppBar 표시
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: _bottomNavigationItems(),
      currentIndex: _selectedIndex,
      selectedItemColor: themeProvider.primaryColor,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: _selectedLabelStyle(),
      unselectedLabelStyle: _unselectedLabelStyle(),
      onTap: _onItemTapped,
    );
  }

  List<BottomNavigationBarItem> _bottomNavigationItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: '메인',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.add),
        label: '오답노트 등록',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.folder),
        label: '폴더',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: '설정',
      ),
    ];
  }

  TextStyle _selectedLabelStyle() {
    return const TextStyle(
      fontSize: 18,
      fontFamily: 'HandWrite',
      fontWeight: FontWeight.bold,
    );
  }

  TextStyle _unselectedLabelStyle() {
    return const TextStyle(
      fontSize: 16,
      fontFamily: 'HandWrite',
      fontWeight: FontWeight.bold,
    );
  }
}
