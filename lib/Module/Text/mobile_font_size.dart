import 'package:flutter/material.dart';

class MobileFontSize {
  static double reduced(BuildContext context, double fontSize) {
    final isMobile = MediaQuery.sizeOf(context).shortestSide < 600;
    return isMobile ? fontSize - 1 : fontSize;
  }
}
