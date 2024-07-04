import 'package:flutter/material.dart';

/*
  상단에 로고를 출력해주는 클래스
*/

class AppBarWithLogo extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  AppBarWithLogo({Key? key})
      : preferredSize = Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      /*
      title: Row(
        children: [
          Image.asset(
            'assets/logo.png', // 로고 이미지 파일 경로
            height: 30,
          ),
        ],
      ),
      backgroundColor: Colors.green[50],
    );
       */
      title: Padding(
        padding: const EdgeInsets.only(left: 12.0), // 왼쪽 여백 추가
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'OnO',
            style: TextStyle(
              fontFamily: 'Arial', // 원하는 폰트 패밀리 설정
              fontSize: 25, // 폰트 크기 설정
              fontWeight: FontWeight.bold, // 폰트 두께 설정
              color: Colors.green, // 텍스트 색상 설정
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      centerTitle: false,
    );
  }
}
