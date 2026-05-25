import 'package:flutter/material.dart';

import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class ThemeChangeButton extends StatelessWidget {
  final ThemeHandler themeProvider;
  final VoidCallback onTap;
  final double horizontalMarginFactor;
  final bool compact;

  const ThemeChangeButton({
    super.key,
    required this.themeProvider,
    required this.onTap,
    this.horizontalMarginFactor = 0.04,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * horizontalMarginFactor,
        vertical: screenHeight * 0.01,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(screenHeight * 0.018),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.palette,
                  color: themeProvider.primaryColor,
                  size: 15,
                ),
              ),
              SizedBox(width: screenHeight * 0.015),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StandardText(
                      text: compact ? '테마\n변경' : '테마 변경',
                      fontSize: 14,
                      color: themeProvider.primaryColor,
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 1),
                      StandardText(
                        text: '오답노트의 템플릿 색상을 변경하세요',
                        fontSize: 12,
                        color: Colors.grey[600]!,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: screenHeight * 0.035,
                height: screenHeight * 0.035,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
