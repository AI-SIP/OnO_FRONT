import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ono/GlobalModule/Theme/ThemeHandler.dart';
import 'package:provider/provider.dart';
import 'Screen/HomeScreen.dart';
import 'Screen/DirectoryScreen.dart';
import 'Screen/ProblemRegisterScreen.dart';
import 'Provider/ProblemsProvider.dart';
import 'Screen/SettingScreen.dart';
import 'GlobalModule/Theme/AppbarWithLogo.dart';
import 'Service/Auth/AuthService.dart';

void main() async {
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProblemsProvider()),
        ChangeNotifierProvider(
          create: (context) => AuthService(
              Provider.of<ProblemsProvider>(context, listen: false)),
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
      home: const MyHomePage(),
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

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ProblemRegisterScreen(),
    DirectoryScreen(),
    SettingScreen(),
  ];

  @override
  void initState() {
    autoLogin();
    super.initState();
  }

  Future<void> autoLogin() async {
    try {
      await Provider.of<AuthService>(context, listen: false).autoLogin();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithLogo(),
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
