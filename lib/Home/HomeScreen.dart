import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../GlobalModule/GridPainter.dart'; // GridPainter 클래스 가져오기
import '../Service/AuthService.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // URL을 여는 함수
  Future<void> _launchURL() async {
    final url = Uri.parse(
        'https://semnisem.notion.site/MVP-e104fd6af0064941acf464e6f77eabb3');

    if (await canLaunchUrl(url)) {
      launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 배경 격자무늬
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(),
            ),
          ),
          // 텍스트와 OnO 사용 가이드 버튼을 중앙에 배치
          Positioned(
            top: screenHeight * 0.3, // 화면 높이의 30% 위치에 배치
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'OnO, 이제는 나도 오답한다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30, // 큰 글씨 크기
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
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
                      fontSize: 18, // 텍스트 크기
                      color: Colors.white, // 텍스트 색상
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 소셜 로그인 버튼을 아래에 배치
          Positioned(
            top: screenHeight * 0.5, // 화면 높이의 50% 위치에 배치
            left: 20,
            right: 20,
            child: Consumer<AuthService>(
              builder: (context, authService, child) {
                if (authService.isLoggedIn) {
                  return Column(
                    children: [
                      Text(
                        '${authService.userName}님 환영합니다!',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ), // 사용자 이름 출력
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      ElevatedButton(
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
                      const SizedBox(height: 20), // 간격 추가
                      ElevatedButton(
                        onPressed: () => authService.signInWithApple(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
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
                              'assets/AppleLogo.png', // 로고 이미지 파일 경로
                              height: 24,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Apple 계정으로 로그인',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16.0),
                            ),
                          ],
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