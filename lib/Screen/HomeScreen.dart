import 'dart:io' show Platform;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/Model/LoginStatus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Config/AppConfig.dart';
import '../GlobalModule/Theme/HandWriteText.dart';
import '../GlobalModule/Theme/GridPainter.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../Provider/UserProvider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

  void _showGuestLoginDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const HandWriteText(
          text: '게스트 로그인 할 경우',
          fontSize: 24,
          color: Colors.redAccent,
        ),
        content: const HandWriteText(
          text: '기기 간 오답노트 연동이 불가능하며\n로그아웃 시 모든 정보가 삭제됩니다.',
          fontSize: 18,
          color: Colors.redAccent,
        ),
        actions: <Widget>[
          TextButton(
            child: const HandWriteText(
              text: '취소',
              fontSize: 20,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: const HandWriteText(
              text: '확인',
              fontSize: 20,
              color: Colors.redAccent,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Provider.of<UserProvider>(context, listen: false)
                  .signInWithGuest();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required String text,
    required String assetPath,
    required Color textColor,
    required double buttonWidth,
    required double buttonHeight,
    required double logoSize,
    required double textSize,
    required Color backgroundColor,
    required bool fontBold,
  }) {
    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            assetPath.isNotEmpty
                ? Image.asset(assetPath, height: logoSize)
                : Icon(Icons.person_outline,
                    size: logoSize, color: Colors.black87),
            SizedBox(width: buttonWidth * 0.02),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: textSize,
                fontWeight: fontBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final double headerFontSize = screenHeight * 0.04;
    final double buttonFontSize = screenHeight * 0.025;
    final double welcomeFontSize = screenHeight * 0.03;

    return Scaffold(
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
                    horizontal: screenWidth * 0.1,
                    vertical: screenHeight * 0.018,
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
                  double buttonWidth = screenWidth * 0.7;
                  double buttonHeight = screenHeight * 0.05;
                  double logoSize = screenHeight * 0.02; // Dynamic logo size
                  double textSize = screenHeight * 0.015; // Dynamic text size

                  if (authService.isLoggedIn == LoginStatus.waiting) {
                    return CircularProgressIndicator(
                        color: themeProvider.primaryColor);
                  } else if (authService.isLoggedIn == LoginStatus.login) {
                    return Padding(
                      padding: EdgeInsets.only(top: screenHeight * 0.05),
                      child: HandWriteText(
                        text: '${authService.userName}님 환영합니다!',
                        fontSize: welcomeFontSize,
                        color: themeProvider.primaryColor,
                      ),
                    );
                  } else {
                    return Column(
                      children: [
                        _buildLoginButton(
                          context: context,
                          onPressed: () => _showGuestLoginDialog(context),
                          text: '게스트로 로그인',
                          assetPath:
                              '', // Icon will be used instead of asset image
                          textColor: Colors.black87,
                          buttonWidth: buttonWidth,
                          buttonHeight: buttonHeight,
                          logoSize: logoSize,
                          textSize: textSize,
                          backgroundColor: Colors.white,
                          fontBold: false,
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        _buildLoginButton(
                          context: context,
                          onPressed: () => authService.signInWithGoogle(),
                          text: '  Google로 로그인',
                          assetPath: 'assets/GoogleLogo.png',
                          textColor: Colors.black87,
                          buttonWidth: buttonWidth,
                          buttonHeight: buttonHeight,
                          logoSize: logoSize,
                          textSize: textSize,
                          backgroundColor: Colors.white,
                          fontBold: false,
                        ),
                        if (Platform.isIOS || Platform.isMacOS)
                          SizedBox(height: screenHeight * 0.03),
                        if (Platform.isIOS || Platform.isMacOS)
                          _buildLoginButton(
                            context: context,
                            onPressed: () =>
                                authService.signInWithApple(context),
                            text: 'Apple로 로그인',
                            assetPath: 'assets/AppleLogo.png',
                            textColor: Colors.black87,
                            buttonWidth: buttonWidth,
                            buttonHeight: buttonHeight,
                            logoSize: logoSize,
                            textSize: textSize,
                            backgroundColor: Colors.white,
                            fontBold: false,
                          ),
                        SizedBox(height: screenHeight * 0.03),
                        _buildLoginButton(
                          context: context,
                          onPressed: () => authService.signInWithKakao(),
                          text: ' 카카오 로그인',
                          assetPath: 'assets/KakaoLogo.png', // 카카오 로고 경로
                          textColor: Colors.black87,
                          buttonWidth: buttonWidth,
                          buttonHeight: buttonHeight,
                          logoSize: logoSize,
                          textSize: textSize,
                          backgroundColor: const Color(0xFFFEE500),
                          fontBold: true,
                        ),
                      ],
                    );
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
