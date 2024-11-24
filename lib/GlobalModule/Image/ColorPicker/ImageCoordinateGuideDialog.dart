import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../Theme/StandardText.dart';

class ImageCoordinateGuideDialog {
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final primaryColor = Theme.of(context).primaryColor;

        return AlertDialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          contentPadding: const EdgeInsets.all(20),
          titlePadding: const EdgeInsets.only(left: 20, top: 20, right: 20),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StandardText(
                text: '사용 방법',
                fontSize: 20,
                color: primaryColor,
              ),
              SvgPicture.asset(
                'assets/GuideScreen/ImageCoordinateGuide.svg', // SVG 경로
                width: 40,
                height: 40,
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0), // 이미지와 테두리 사이의 패딩
                    child: Container(
                      height: screenHeight * 0.5, // 화면 높이의 50%
                      decoration: BoxDecoration(
                        border: Border.all(color: primaryColor.withOpacity(0.5)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0), // 이미지 내부 패딩
                        child: Image.asset(
                          'assets/GuideScreen/ImageCoordinateGuide.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const StandardText(
                    text: "-  영역 선택 버튼을 누른 후, 사진처럼 문제 아래에 있는 필기를 선택하면 끝이에요!\n\n"
                        "-  문제 아래에 필기가 없다구요? 건너뛰기를 하고 계속 등록하시면 됩니다!\n",
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.normal,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: StandardText(
                text: '닫기',
                fontSize: 16,
                color: primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }
}