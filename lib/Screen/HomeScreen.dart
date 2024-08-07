import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Config/AppConfig.dart';
import '../GlobalModule/GridPainter.dart';
import '../Service/AuthService.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _launchURL() async {
    final url = Uri.parse(AppConfig.guidePageUrl);

    if (await canLaunchUrl(url)) {
      launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showGuestLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('게스트 로그인 경고',
            style: TextStyle(
                fontSize: 24,
                color: Colors.green,
                fontFamily: 'font1',
                fontWeight: FontWeight.bold)),
        content: const Text(
            '게스트로 로그인 할 경우,\n기기 간 오답노트 연동이 불가능하며,\n로그아웃 시 모든 정보가 삭제됩니다.',
            style: TextStyle(
                fontSize: 22,
                color: Colors.green,
                fontFamily: 'font1',
                fontWeight: FontWeight.bold)),
        actions: <Widget>[
          TextButton(
            child: const Text('취소',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.green,
                    fontFamily: 'font1',
                    fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: const Text('확인',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.green,
                    fontFamily: 'font1',
                    fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(ctx).pop();
              Provider.of<AuthService>(context, listen: false).signInWithGuest();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Define dynamic font sizes based on screen dimensions
    final double headerFontSize = screenHeight * 0.04; // 5% of screen height
    final double buttonFontSize = screenHeight * 0.025; // 2.5% of screen height
    final double welcomeFontSize = screenHeight * 0.03; // 3% of screen height

    return Scaffold(
      body: CustomPaint(
        painter: GridPainter(),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.1),
              Text(
                'OnO, 이제는 나도 오답한다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: headerFontSize,
                  fontFamily: 'font1',
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              ElevatedButton(
                onPressed: _launchURL,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.1,
                    vertical: screenHeight * 0.02,
                  ),
                  textStyle: TextStyle(
                    fontSize: buttonFontSize,
                    color: Colors.white,
                  ),
                ),
                child: Text(
                  'OnO 사용 가이드 →',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: buttonFontSize,
                    fontFamily: 'font1',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.06),
              Consumer<AuthService>(
                builder: (context, authService, child) {
                  double buttonWidth = screenWidth * 0.7;
                  double buttonHeight = screenHeight * 0.05;
                  double logoSize = screenHeight * 0.02; // Dynamic logo size
                  double textSize = screenHeight * 0.015; // Dynamic text size

                  if (authService.isLoggedIn) {
                    return Padding(
                      padding: EdgeInsets.only(top: screenHeight * 0.05),
                      child: Text(
                        '${authService.userName}님 환영합니다!',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: welcomeFontSize,
                          fontFamily: 'font1',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else {
                    return Column(
                      children: [
                        SizedBox(
                          width: buttonWidth,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: () => _showGuestLoginDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 1.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: logoSize,
                                  color: Colors.black87,
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Text(
                                  '게스트로 로그인',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: textSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        SizedBox(
                          width: buttonWidth,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: () => authService.signInWithGoogle(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 1.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/GoogleLogo.png',
                                  height: logoSize,
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Text(
                                  'Google 계정으로 로그인',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: textSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        if (!Platform.isAndroid)
                          SizedBox(
                            width: buttonWidth,
                            height: buttonHeight,
                            child: ElevatedButton(
                              onPressed: () =>
                                  authService.signInWithApple(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                elevation: 1.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/AppleLogo.png',
                                    height: logoSize,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Apple로 로그인',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: textSize,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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