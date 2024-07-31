import 'package:flutter/material.dart';

class AppBarWithLogo extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  const AppBarWithLogo({super.key})
      : preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Padding(
        padding: EdgeInsets.only(left: 10.0), // 왼쪽 여백 추가
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'OnO',
            style: TextStyle(
                color: Colors.green,
                fontSize: 26,
                fontFamily: 'font1',
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      centerTitle: false,
    );
  }
}
