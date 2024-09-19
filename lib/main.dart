import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:ono/GlobalModule/Theme/ThemeHandler.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Screen/SplashScreen.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'Screen/HomeScreen.dart';
import 'Screen/DirectoryScreen.dart';
import 'Screen/ProblemRegisterScreen.dart';
import 'Screen/SettingScreen.dart';
import 'GlobalModule/Theme/AppbarWithLogo.dart';
import 'Provider/UserProvider.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  KakaoSdk.init(nativeAppKey: '7fd2fa49895af63319fd6b11e084d0d5');

  await SentryFlutter.init(
          (options) {
        options.dsn = 'https://ef02bb2a25f04c4141b3edb8c51ff128@o4507978249273344.ingest.us.sentry.io/4507978250911744';
        // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
        // We recommend adjusting this value in production.
        options.tracesSampleRate = 1.0;
        // The sampling rate for profiling is relative to tracesSampleRate
        // Setting to 1.0 will profile 100% of sampled transactions:
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: _buildThemeData(context),
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
    ProblemRegisterScreen(),
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
    final foldersProvider = Provider.of<FoldersProvider>(context, listen: false);

    setState(() {
      _selectedIndex = 0;
    });

    foldersProvider.fetchRootFolderContents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 2
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
      fontFamily: 'font1',
      fontWeight: FontWeight.bold,
    );
  }

  TextStyle _unselectedLabelStyle() {
    return const TextStyle(
      fontSize: 16,
      fontFamily: 'font1',
      fontWeight: FontWeight.bold,
    );
  }
}
