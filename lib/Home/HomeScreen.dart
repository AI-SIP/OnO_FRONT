import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../GlobalModule/GridPainter.dart'; // GridPainter 클래스 가져오기

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // URL을 여는 함수
  Future<void> _launchURL() async {
    final url =
        Uri.parse('https://semnisem.notion.site/MVP-e104fd6af0064941acf464e6f77eabb3');

    if (await canLaunchUrl(url)) {
      launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 격자무늬
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
        ],
      ),
    );
  }
}
