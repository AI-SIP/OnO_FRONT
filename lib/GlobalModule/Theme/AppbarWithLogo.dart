import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'HandWriteText.dart';
import 'ThemeHandler.dart';

class AppBarWithLogo extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  const AppBarWithLogo({super.key})
      : preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final themeProvider = Provider.of<ThemeHandler>(context);

    return AppBar(
      title: Padding(
        padding: EdgeInsets.only(left: screenHeight * 0.01), // 왼쪽 여백 추가
        child: Align(
            alignment: Alignment.centerLeft,
            child: HandWriteText(
              text: 'OnO',
              fontSize: screenHeight * 0.025,
              color: themeProvider.primaryColor,
              fontWeight: FontWeight.bold,
            )),
      ),
      backgroundColor: Colors.white,
      centerTitle: false,
    );
  }
}
