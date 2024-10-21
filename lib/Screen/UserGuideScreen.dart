import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ono/GlobalModule/Theme/StandardText.dart';

class UserGuideScreen extends StatefulWidget {
  final VoidCallback
      onFinish; // Callback to be called when the user finishes the onboarding

  const UserGuideScreen({required this.onFinish, Key? key}) : super(key: key);

  @override
  _UserGuideScreenState createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final guideScreenLength = 4;

  @override
  Widget build(BuildContext context) {

    double screenHeight = MediaQuery.of(context).size.height; // 화면 높이 가져오기
    double contentPadding = screenHeight * 0.016; // 화면 높이에 따라 패딩 설정

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // Background color of the modal
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.all(contentPadding),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.03), // 아래쪽 여백 추가
            child: StandardText(
              text: 'OnO, 이렇게 사용하세요',
              fontSize: screenHeight * 0.022,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
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
                  imagePath: 'assets/GuideScreen/GuideScreen1.svg',
                  title: 'OnO에 오신걸 환영합니다!',
                  description: 'OnO를 통해 손쉽게\n나만의 오답노트를 작성해보아요!',
                ),
                _buildUserGuidePage(
                  imagePath: 'assets/GuideScreen/GuideScreen2.svg',
                  title: '문제 등록',
                  description: '낙서, 필기를 깔끔하게 지우고\n새로운 문제처럼 등록할 수 있어요.',
                ),
                _buildUserGuidePage(
                  imagePath: 'assets/GuideScreen/GuideScreen3.svg',
                  title: '문제 등록',
                  description: '오답 분석 기능을 사용해\n나의 취약점을 알아보세요.',
                ),
                _buildUserGuidePage(
                  imagePath: 'assets/GuideScreen/GuideScreen4.svg',
                  title: '오답 복습',
                  description: '구분이 쉽도록 여러 개의 오답노트를 만들 수 있어요.',
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
    double screenHeight = MediaQuery.of(context).size.height;
    double imageWidth = screenHeight * 0.35;
    double imageHeight = screenHeight * 0.2; // 화면 높이에 비례하여 이미지 크기 설정
    double titleFontSize = screenHeight * 0.03; // 텍스트 크기 비례 설정
    double descriptionFontSize = screenHeight * 0.02;

    return SingleChildScrollView(
      // SingleChildScrollView 추가
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(imagePath,
              width: imageWidth, height: imageHeight), // Onboarding image
          SizedBox(height: screenHeight * 0.03),
          Text(
            title,
            style: TextStyle(fontSize: screenHeight * 0.022, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            description,
            style: TextStyle(fontSize: screenHeight * 0.016),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    double screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.all(screenHeight * 0.02),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              guideScreenLength,
              (index) => _buildIndicator(index == _currentPage),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          LayoutBuilder(
            builder: (context, constraints) {
              // 다이얼로그 크기의 80%로 버튼 너비를 설정
              double buttonWidth = constraints.maxWidth * 0.8;
              return SizedBox(
                width: buttonWidth, // 다이얼로그의 80% 너비로 버튼 설정
                height: screenHeight * 0.05,
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
                    fontSize: screenHeight * 0.02,
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
