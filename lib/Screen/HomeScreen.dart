import 'dart:io' show Platform;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/Screen/UserGuideScreen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Config/AppConfig.dart';
import '../GlobalModule/Theme/HandWriteText.dart';
import '../GlobalModule/Theme/GridPainter.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../Model/LoginStatus.dart';
import '../Provider/UserProvider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  bool modalShown = false;

  @override
  void initState() {
    super.initState();
    // Post frame callback을 사용해 모달을 제어
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isFirstLogin && !modalShown) {
        modalShown = true;
        _showUserGuideModal();
      }
    });
  }

  void _showUserGuideModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 스크롤 가능 모달 설정
      backgroundColor: Colors.transparent, // 투명 배경
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.5, // 화면 높이의 50% 차지
          child: UserGuideScreen(
            onFinish: () {
              Navigator.of(context).pop(); // 모달 닫기
            },
          ),
        );
      },
    );
  }

  Future<void> _launchURL() async {
    final url = Uri.parse(AppConfig.guidePageUrl);

    if (await canLaunchUrl(url)) {
      launchUrl(url);
      FirebaseAnalytics.instance.logEvent(name: 'ono_guide_button_click', parameters: {
        'url': AppConfig.guidePageUrl,
      });
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final double headerFontSize = screenHeight * 0.04;
    final double buttonFontSize = screenHeight * 0.025;
    final double welcomeFontSize = screenHeight * 0.03;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomPaint(
        painter: GridPainter(gridColor: themeProvider.primaryColor),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.1),
              HandWriteText(
                text: '\"OnO, 이제는 나도 오답한다\"',
                fontSize: headerFontSize,
                color: themeProvider.primaryColor,
              ),
              SizedBox(height: screenHeight * 0.03),
              ElevatedButton(
                onPressed: _launchURL,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.07,
                    vertical: screenHeight * 0.015,
                  ),
                  backgroundColor: themeProvider.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0), // 둥근 버튼 모양
                  ),
                  shadowColor: Colors.black.withOpacity(0.5), // 그림자 추가
                  elevation: 10, // 그림자 깊이
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, color: Colors.white, size: buttonFontSize), // 아이콘 추가
                    const SizedBox(width: 10),
                    HandWriteText(
                      text: 'OnO 사용 가이드',
                      fontSize: buttonFontSize,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.06),
              Consumer<UserProvider>(
                builder: (context, authService, child) {

                  if (authService.isLoggedIn == LoginStatus.login) {
                    return Padding(
                      padding: EdgeInsets.only(top: screenHeight * 0.05),
                      child: HandWriteText(
                        text: '${authService.userName}님 환영합니다!',
                        fontSize: welcomeFontSize,
                        color: themeProvider.primaryColor,
                      ),
                    );
                  } else {
                    return const Column();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
