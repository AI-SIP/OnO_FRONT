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
        title: const Text('게스트 로그인 경고', style: const TextStyle(
            fontSize: 24,
            color: Colors.green,
            fontFamily: 'font1',
            fontWeight: FontWeight.bold)),
        content: const Text('게스트로 로그인 할 경우,\n기기 간 오답노트 연동이 불가능하며,\n로그아웃 시 모든 정보가 삭제됩니다.', style: const TextStyle(
            fontSize: 22,
            color: Colors.green,
            fontFamily: 'font1',
            fontWeight: FontWeight.bold)),
        actions: <Widget>[
          TextButton(
            child: const Text('취소', style: const TextStyle(
                fontSize: 20,
                color: Colors.green,
                fontFamily: 'font1',
                fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: const Text('확인', style: const TextStyle(
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

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(),
            ),
          ),
          Positioned(
            top: screenHeight * 0.3,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'OnO, 이제는 나도 오답한다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.green,
                      fontSize: 35,
                      fontFamily: 'font1',
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _launchURL, // 버튼을 누르면 URL을 여는 함수 호출
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // 버튼 배경색
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 18, // 버튼 글씨 크기
                      color: Colors.white,
                    ),
                  ),
                  child: const Text(
                    'OnO 사용 가이드 →',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'font1',
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: screenHeight * 0.5, // 화면 높이의 50% 위치에 배치
            left: 20,
            right: 20,
            child: Consumer<AuthService>(
              builder: (context, authService, child) {

                double buttonWidth = MediaQuery.of(context).size.width * 0.7;

                if (authService.isLoggedIn) {
                  return Column(
                    children: [
                      Text(
                        '${authService.userName}님 환영합니다!',
                        style: const TextStyle(
                            color: Colors.green,
                            fontSize: 24,
                            fontFamily: 'font1',
                            fontWeight: FontWeight.bold),
                      ), // 사용자 이름 출력
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      SizedBox(
                        width: buttonWidth,
                        child: ElevatedButton(
                          onPressed: () => _showGuestLoginDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50), // 높이만 50으로 설정
                            elevation: 1.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_outline, size: 24, color: Colors.black87),
                              SizedBox(width: 10),
                              Text(
                                '게스트로 로그인',
                                style: TextStyle(
                                    color: Colors.black87, fontSize: 16.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: buttonWidth,
                        child: ElevatedButton(
                          onPressed: () => authService.signInWithGoogle(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50), // 높이만 50으로 설정
                            elevation: 1.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/GoogleLogo.png', // 로고 이미지 파일 경로
                                height: 24,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Google 계정으로 로그인',
                                style: TextStyle(
                                    color: Colors.black87, fontSize: 16.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20), // 간격 추가
                      if (!Platform.isAndroid)
                        SizedBox(
                          width: buttonWidth,
                          child: ElevatedButton(
                            onPressed: () => authService.signInWithApple(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              minimumSize:
                              const Size.fromHeight(50), // 높이만 50으로 설정
                              elevation: 1.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/AppleLogo.png', // 로고 이미지 파일 경로
                                  height: 24,
                                ),
                                const Text(
                                  'Apple로 로그인',
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 16.0),
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
          ),
        ],
      ),
    );
  }
}
