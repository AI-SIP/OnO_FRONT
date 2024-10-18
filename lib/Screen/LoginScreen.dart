import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../GlobalModule/Theme/StandardText.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../Model/LoginStatus.dart';
import '../Provider/UserProvider.dart';
import '../main.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _showGuestLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const StandardText(
          text: '게스트 로그인 할 경우',
          fontSize: 18,
          color: Colors.red,
        ),
        content: const StandardText(
          text: '기기 간 오답노트 연동이 불가능하며,\n로그아웃 시 모든 정보가 삭제됩니다.',
          fontSize: 14,
          color: Colors.black,
        ),
        actions: <Widget>[
          TextButton(
            child: const StandardText(
              text: '취소',
              fontSize: 14,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: const StandardText(
              text: '확인',
              fontSize: 14,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Provider.of<UserProvider>(context, listen: false)
                  .signInWithGuest(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginImageButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required String assetPath, // 이미지 경로
    required double buttonWidth,
    required double buttonHeight,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Image.asset(
        assetPath,
        width: buttonWidth,
        height: buttonHeight,
        fit: BoxFit.contain, // 이미지를 버튼 크기에 맞게 조정
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final double headerFontSize = screenHeight * 0.03;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: screenHeight * 0.25, // 화면 상단에서 30% 지점
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 이미지 추가
                Image.asset(
                  'assets/Logo/GreenFrog.png',
                  width: screenWidth * 0.4,
                  height: screenHeight * 0.15,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: screenHeight * 0.05), // 이미지와 텍스트 간 간격
                // 텍스트 추가
                StandardText(
                  text: '\"나만의 손쉬운 오답노트, OnO\"',
                  fontSize: headerFontSize,
                  color: themeProvider.primaryColor,
                ),
              ],
            ),
          ),

          Positioned(
            bottom: screenHeight * 0.10, // 화면 하단에서 10% 떨어진 위치에 고정
            left: 0,
            right: 0,
            child: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                double buttonWidth = screenWidth * 0.8; // 화면의 80% 크기
                double buttonHeight = screenHeight * 0.065;

                if (userProvider.loginStatus == LoginStatus.login) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const MyHomePage()),
                    );
                  });
                }

                return Column(
                  children: [
                    // Google 로그인 버튼
                    _buildLoginImageButton(
                      context: context,
                      onPressed: () => userProvider.signInWithGoogle(context),
                      assetPath: 'assets/SocialLogin/GoogleLogin.png',
                      buttonWidth: buttonWidth,
                      buttonHeight: buttonHeight,
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Apple 로그인 버튼
                    if (Platform.isIOS || Platform.isMacOS)
                      _buildLoginImageButton(
                        context: context,
                        onPressed: () => userProvider.signInWithApple(context),
                        assetPath: 'assets/SocialLogin/AppleLogin.png',
                        buttonWidth: buttonWidth,
                        buttonHeight: buttonHeight,
                      ),
                    SizedBox(height: screenHeight * 0.03),

                    // Kakao 로그인 버튼
                    _buildLoginImageButton(
                      context: context,
                      onPressed: () => userProvider.signInWithKakao(context),
                      assetPath: 'assets/SocialLogin/KakaoLogin.png',
                      buttonWidth: buttonWidth,
                      buttonHeight: buttonHeight,
                    ),

                    // 게스트로 로그인 텍스트 버튼
                    SizedBox(height: screenHeight * 0.03),
                    GestureDetector(
                      onTap: () => _showGuestLoginDialog(context),
                      child: const Text(
                        '게스트로 로그인',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
