import 'package:flutter/material.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class SettingMenuButtons extends StatelessWidget {
  final ThemeHandler themeProvider;
  final VoidCallback onThemeChangeTap;
  final VoidCallback onGuideTap;
  final VoidCallback onFeedbackTap;
  final VoidCallback onTermsTap;

  const SettingMenuButtons({
    super.key,
    required this.themeProvider,
    required this.onThemeChangeTap,
    required this.onGuideTap,
    required this.onFeedbackTap,
    required this.onTermsTap,
  });

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      padding: EdgeInsets.all(screenHeight * 0.015),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            context: context,
            icon: Icons.palette,
            title: '테마 변경',
            onTap: onThemeChangeTap,
            showThemeColor: true,
          ),
          Divider(height: screenHeight * 0.02, color: Colors.grey[300]),
          _buildMenuItem(
            context: context,
            icon: Icons.help_outline,
            title: 'OnO 가이드',
            onTap: onGuideTap,
          ),
          Divider(height: screenHeight * 0.02, color: Colors.grey[300]),
          _buildMenuItem(
            context: context,
            icon: Icons.feedback_outlined,
            title: '의견 남기기',
            onTap: onFeedbackTap,
          ),
          Divider(height: screenHeight * 0.02, color: Colors.grey[300]),
          _buildMenuItem(
            context: context,
            icon: Icons.description_outlined,
            title: 'OnO 이용약관',
            onTap: onTermsTap,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showThemeColor = false,
  }) {
    double screenHeight = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.008,
          horizontal: screenHeight * 0.01,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: themeProvider.primaryColor,
            ),
            SizedBox(width: screenHeight * 0.015),
            Expanded(
              child: StandardText(
                text: title,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            if (showThemeColor)
              Container(
                width: screenHeight * 0.025,
                height: screenHeight * 0.025,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor,
                  shape: BoxShape.circle,
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}