import 'package:flutter/material.dart';

import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class StudyRoomEmptyState extends StatelessWidget {
  final ThemeHandler themeProvider;
  final VoidCallback onCreateTap;
  final VoidCallback onJoinTap;

  const StudyRoomEmptyState({
    super.key,
    required this.themeProvider,
    required this.onCreateTap,
    required this.onJoinTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group_outlined,
                size: 48,
                color: themeProvider.primaryColor,
              ),
            ),
            SizedBox(height: screenHeight * 0.025),
            const StandardText(
              text: '참여 중인 스터디룸이 없어요',
              fontSize: 18,
              color: Colors.black87,
            ),
            SizedBox(height: screenHeight * 0.01),
            StandardText(
              text: '친구와 함께 공부하며\n서로의 학습 현황을 확인해 보세요!',
              fontSize: 14,
              color: Colors.grey[600]!,
              textAlign: TextAlign.center,
              fontWeight: FontWeight.normal,
              fontFamily: 'PretendardLight',
            ),
            SizedBox(height: screenHeight * 0.04),
            _buildActionButton(
              icon: Icons.add,
              label: '방 만들기',
              onTap: onCreateTap,
              backgroundColor: themeProvider.primaryColor,
              textColor: Colors.white,
              iconColor: Colors.white,
            ),
            SizedBox(height: screenHeight * 0.015),
            _buildActionButton(
              icon: Icons.login,
              label: '코드로 참여하기',
              onTap: onJoinTap,
              backgroundColor: Colors.grey[100]!,
              textColor: Colors.black87,
              iconColor: themeProvider.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            StandardText(text: label, fontSize: 15, color: textColor),
          ],
        ),
      ),
    );
  }
}
