import 'package:flutter/material.dart';

import '../../Text/StandardText.dart';

class ImageCoordinateGuideDialog {
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final primaryColor = Theme.of(context).primaryColor;

        return AlertDialog(
          backgroundColor: Colors.white,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          contentPadding: const EdgeInsets.all(20),
          titlePadding: const EdgeInsets.only(left: 20, top: 20, right: 20),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StandardText(
                text: '필기 제거 방법',
                fontSize: 20,
                color: primaryColor,
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0), // 이미지와 테두리 사이의 패딩
                    child: Container(
                      height: screenHeight * 0.45, // 화면 높이의 50%
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: primaryColor.withOpacity(0.7)),
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
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0), // 좌우 패딩 추가
                    child: StandardText(
                      text: "-  영역 추가 버튼을 누른 후, 사진처럼 필기 부분을 박스로 선택하면 끝이에요!",
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.normal,
                      textAlign: TextAlign.start,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0), // 좌우 패딩 추가
                    child: StandardText(
                      text: "(문제와 겹치는 필기는 선택하지 않아도 돼요! OnO가 제거하니까요!)",
                      fontSize: 15,
                      color: Colors.red,
                      fontWeight: FontWeight.normal,
                      textAlign: TextAlign.start,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0), // 좌우 패딩 추가
                    child: StandardText(
                      text: "-  문제에 필기가 없다구요? 바로 완료를 누르면 돼요!",
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.normal,
                      textAlign: TextAlign.start,
                    ),
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
                text: '확인',
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
