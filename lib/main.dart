import 'package:flutter/material.dart';
import 'package:mvp_front/Service/AuthService.dart';
import 'package:provider/provider.dart';
import 'Home/HomeScreen.dart';
import 'Directory/DirectoryScreen.dart';
import 'ProblemRegister/ProblemRegisterScreen.dart';
import 'Service/ProblemService.dart';
import 'Setting/SettingScreen.dart';
import 'AppbarWithLogo.dart';

/*
  메인 함수
*/

void main() {
  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => AuthService()),
      Provider(create: (_) => ProblemService()), // ProblemService를 Provider로 추가
    ], child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
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
    //ProblemDetailScreen(),
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
      // 여기에 오류 처리 로직을 추가할 수 있습니다.
      print('Auto login failed: $e');
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
      appBar: AppBarWithLogo(),
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
          /*
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: '오답노트 복습',
          ),

           */
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
        selectedItemColor: Colors.green,
        onTap: _onItemTapped,
      ),
    );
  }
}
