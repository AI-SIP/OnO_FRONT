import 'package:flutter/material.dart';

import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import 'StudyRoomThumbnail.dart';

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
    final emptyImageCircleSize = screenWidth < 360 ? 128.0 : 150.0;
    final imageSize = emptyImageCircleSize * 0.78;
    const assetPath =
        'assets/emoji/${StudyRoomThumbnail.defaultEmojiKey}.png';

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: emptyImageCircleSize,
              height: emptyImageCircleSize,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[200]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  assetPath,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
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
