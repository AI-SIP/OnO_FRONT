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
  }
}
