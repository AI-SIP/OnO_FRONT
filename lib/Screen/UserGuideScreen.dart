import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/StandardText.dart';

class UserGuideScreen extends StatefulWidget {
  final VoidCallback onFinish; // Callback to be called when the user finishes the onboarding

  const UserGuideScreen({required this.onFinish, Key? key}) : super(key: key);

  @override
  _UserGuideScreenState createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final guideScreenLength = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // Background color of the modal
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildUserGuidePage(
                  imagePath: 'assets/GuideScreen/GuideScreen1.png',
                  title: '나의 노트',
                  description: '구분이 쉽도록 여러 개의\n오답노트를 만들 수 있어요.',
                ),
                _buildUserGuidePage(
                  imagePath: 'assets/GuideScreen/GuideScreen2.png',
                  title: '복습',
                  description: '문제와 노트를 묶어 루틴을 만들고\n처음 보는 문제처럼 풀어봐요.',
                ),
                _buildUserGuidePage(
                  imagePath: 'assets/GuideScreen/GuideScreen3.png',
                  title: '문제 등록',
                  description: '낙서, 필기를 깔끔하게 지우고\n새로운 문제처럼 등록할 수 있어요.',
                ),
              ],
            ),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildUserGuidePage({
    required String imagePath,
    required String title,
    required String description,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(imagePath, width: 200, height: 200), // Onboarding image
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              guideScreenLength,
                  (index) => _buildIndicator(index == _currentPage),
            ),
          ),
          const SizedBox(height: 30),
          LayoutBuilder(
            builder: (context, constraints) {
              // 다이얼로그 크기의 80%로 버튼 너비를 설정
              double buttonWidth = constraints.maxWidth * 0.8;
              return SizedBox(
                width: buttonWidth, // 다이얼로그의 80% 너비로 버튼 설정
                child: ElevatedButton(
                  onPressed: _currentPage == guideScreenLength - 1
                      ? widget.onFinish
                      : () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // 둥근 모서리 설정
                    ),
                  ),
                  child: StandardText(
                    text: _currentPage == guideScreenLength - 1 ? '확인' : '다음',
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      width: isActive ? 12.0 : 8.0,
      height: 8.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.grey,
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }
}