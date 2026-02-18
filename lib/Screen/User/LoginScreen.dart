import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../Model/Common/LoginStatus.dart';
import '../../Module/Text/HandWriteText.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/GridPainter.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/UserProvider.dart';
import '../../main.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final double headerFontSize = screenHeight * 0.035;
    bool isNavigated = false;

    return Scaffold(
      body: Stack(
        children: [
          CustomPaint(
            size: Size(screenWidth, screenHeight),
            painter: GridPainter(
              gridColor: themeProvider.primaryColor, // 원하는 그리드 색상 설정
              isSpring: true, // 스프링 제본 여부 설정
            ),
          ),
          Positioned(
            top: screenHeight * 0.25, // 화면 상단에서 30% 지점
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 이미지 추가
                SvgPicture.asset(
                  'assets/Logo/GreenFrog.svg',
                  width: screenWidth * 0.4,
                  height: screenHeight * 0.15,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: screenHeight * 0.05), // 이미지와 텍스트 간 간격
                // 텍스트 추가
                HandWriteText(
                  text: '\"나만의 진정한 오답노트, OnO\"',
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

                if (userProvider.loginStatus == LoginStatus.login &&
                    !isNavigated) {
                  isNavigated = true;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const MyHomePage(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0); // 오른쪽에서 왼쪽으로 슬라이드
                          const end = Offset.zero;
                          const curve = Curves.ease;

                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          var offsetAnimation = animation.drive(tween);

                          return SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          );
                        },
                      ),
                    );
                  });
                }
                return Column(
                  children: [
                    // Google 로그인 버튼
                    _buildLoginImageButton(
                      context: context,
                      onPressed: () => userProvider.signInWithGoogle(context),
                      assetPath: 'assets/SocialLogin/GoogleLogin.svg',
                      buttonWidth: buttonWidth,
                      buttonHeight: buttonHeight,
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Apple 로그인 버튼
                    if (Platform.isIOS || Platform.isMacOS) ...[
                      _buildLoginImageButton(
                        context: context,
                        onPressed: () => userProvider.signInWithApple(context),
                        assetPath: 'assets/SocialLogin/AppleLogin.svg',
                        buttonWidth: buttonWidth,
                        buttonHeight: buttonHeight,
                      ),
                      SizedBox(height: screenHeight * 0.03),
                    ],

                    // Kakao 로그인 버튼
                    _buildLoginImageButton(
                      context: context,
                      onPressed: () => userProvider.signInWithKakao(context),
                      assetPath: 'assets/SocialLogin/KakaoLogin.svg',
                      buttonWidth: buttonWidth,
                      buttonHeight: buttonHeight,
                    ),
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

  void _showGuestLoginDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.red.withValues(alpha: 0.14),
                      themeProvider.primaryColor.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: StandardText(
                        text: '게스트 로그인 안내',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StandardText(
                        text: '• 기기 간 오답노트 연동이 불가능해요.',
                        fontSize: 14,
                        color: Colors.grey[800]!,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StandardText(
                        text: '• 로그아웃 시 모든 정보가 삭제돼요.',
                        fontSize: 14,
                        color: Colors.grey[800]!,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const StandardText(
                          text: '취소',
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Provider.of<UserProvider>(context, listen: false)
                              .signInWithGuest(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const StandardText(
                          text: '확인',
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      child: SvgPicture.asset(
        assetPath,
        width: buttonWidth,
        height: buttonHeight,
        fit: BoxFit.contain,
      ),
    );
  }
}
