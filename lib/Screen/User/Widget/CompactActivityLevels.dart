import 'package:flutter/material.dart';
import '../../../Model/User/UserInfoModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class CompactActivityLevels extends StatelessWidget {
  final UserInfoModel? userInfo;
  final ThemeHandler themeProvider;

  const CompactActivityLevels({
    super.key,
    required this.userInfo,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    if (userInfo == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      padding: EdgeInsets.all(screenHeight * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StandardText(
            text: '활동 레벨',
            fontSize: 18,
            color: themeProvider.primaryColor,
          ),
          SizedBox(height: screenHeight * 0.015),
          _buildActivityRow(
            icon: Icons.check_circle,
            category: '출석',
            level: userInfo!.attendanceLevel,
            point: userInfo!.attendancePoint,
            color: Colors.pink[300]!,
            screenHeight: screenHeight,
          ),
          SizedBox(height: screenHeight * 0.012),
          _buildActivityRow(
            icon: Icons.edit_note,
            category: '오답노트 작성',
            level: userInfo!.noteWriteLevel,
            point: userInfo!.noteWritePoint,
            color: Colors.purple[300]!,
            screenHeight: screenHeight,
          ),
          SizedBox(height: screenHeight * 0.012),
          _buildActivityRow(
            icon: Icons.quiz,
            category: '오답노트 복습',
            level: userInfo!.problemPracticeLevel,
            point: userInfo!.problemPracticePoint,
            color: Colors.green[400]!,
            screenHeight: screenHeight,
          ),
          SizedBox(height: screenHeight * 0.012),
          _buildActivityRow(
            icon: Icons.book,
            category: '복습노트 복습',
            level: userInfo!.notePracticeLevel,
            point: userInfo!.notePracticePoint,
            color: Colors.blue[300]!,
            screenHeight: screenHeight,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow({
    required IconData icon,
    required String category,
    required int level,
    required int point,
    required Color color,
    required double screenHeight,
  }) {
    int requiredPoint = level * 100;
    double progress = requiredPoint > 0 ? point / requiredPoint : 0;

    return Row(
      children: [
        // 아이콘
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        SizedBox(width: screenHeight * 0.012),
        // 카테고리명
        SizedBox(
          width: 100,
          child: StandardText(
            text: category,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        SizedBox(width: screenHeight * 0.008),
        // 레벨
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: StandardText(
            text: 'Lv.$level',
            fontSize: 11,
            color: Colors.white,
          ),
        ),
        SizedBox(width: screenHeight * 0.008),
        // 프로그레스 바
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        SizedBox(width: screenHeight * 0.008),
        // 포인트
        SizedBox(
          width: 50,
          child: StandardText(
            text: '$point/$requiredPoint',
            fontSize: 10,
            color: Colors.grey[600]!,
          ),
        ),
      ],
    );
  }
}