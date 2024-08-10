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

import 'Service/AuthService.dart';

void main() async {
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProblemsProvider()),
        ChangeNotifierProvider(
            create: (context) => AuthService(
                Provider.of<ProblemsProvider>(context, listen: false))),
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
    final themeHandler = Provider.of<ThemeHandler>(context);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: themeHandler.primaryColor),
        primaryColor: themeHandler.primaryColor,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
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
    super.initState();
    autoLogin();
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
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      appBar: const AppBarWithLogo(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
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
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: themeProvider.primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontSize: 18,
          fontFamily: 'font1',
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontFamily: 'font1',
          fontWeight: FontWeight.bold,
        ),
        onTap: _onItemTapped,
      ),
    );
  }
}
