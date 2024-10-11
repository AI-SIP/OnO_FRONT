import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/HandWriteText.dart';

import '../main.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2), () {});
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MyHomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFCBEAB7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/Logo.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  '\"OnO, 이제는 나도 오답한다\"',
                  textStyle: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontFamily: 'HandWrite', // 손글씨 느낌의 폰트 사용
                    fontWeight: FontWeight.bold,
                  ),
                  speed: const Duration(milliseconds: 75), // 타이핑 속도 조절
                  cursor: '', // 커서를 빈 문자열로 설정하여 깜빡임을 없앰
                ),
              ],
              isRepeatingAnimation: false, // 한 번만 실행되도록 설정
            ),
          ],
        ),
      ),
    );
  }
}