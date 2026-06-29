import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Model/StudyRoom/StudyRoomMemberModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class MemberRankCard extends StatelessWidget {
  final int rank;
  final StudyRoomMemberModel member;
  final bool isMe;
  final bool isHost;
  final bool canKick;
  final VoidCallback? onKick;

  const MemberRankCard({
    super.key,
    required this.rank,
    required this.member,
    required this.isMe,
    required this.isHost,
    this.canKick = false,
    this.onKick,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final m = member;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.005,
      ),
      child: Container(
        padding: EdgeInsets.all(screenHeight * 0.016),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isMe
                ? themeProvider.primaryColor.withValues(alpha: 0.35)
                : Colors.grey[300]!,
            width: isMe ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatar(m, themeProvider),
            SizedBox(width: screenHeight * 0.012),
            Expanded(child: _buildMemberInfo(m, themeProvider)),
            _buildStats(m, themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(
    StudyRoomMemberModel m,
    ThemeHandler themeProvider,
  ) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white
            : themeProvider.primaryColor.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: isMe
              ? themeProvider.primaryColor
              : themeProvider.primaryColor.withValues(alpha: 0.18),
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: Icon(
          isMe ? Icons.person : Icons.person_outline,
          size: 19,
          color: themeProvider.primaryColor,
        ),
      ),
    );
  }

  Widget _buildMemberInfo(StudyRoomMemberModel m, ThemeHandler themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: StandardText(
                text: m.name,
                fontSize: 15,
                color: Colors.black87,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: themeProvider.primaryColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: StandardText(
                  text: '나',
                  fontSize: 11,
                  color: themeProvider.primaryColor,
                ),
              ),
            ],
            if (isHost) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.workspace_premium_outlined,
                size: 13,
                color: themeProvider.primaryColor,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.star, size: 12, color: themeProvider.primaryColor),
            const SizedBox(width: 3),
            StandardText(
              text: 'Lv.${m.totalStudyLevel}',
              fontSize: 12,
              color: Colors.grey[600]!,
              fontWeight: FontWeight.normal,
              fontFamily: 'PretendardLight',
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.local_fire_department_rounded,
              size: 12,
              color: Colors.deepOrange[300],
            ),
            const SizedBox(width: 3),
            StandardText(
              text: '${m.currentStreak}일',
              fontSize: 12,
              color: Colors.grey[600]!,
              fontWeight: FontWeight.normal,
              fontFamily: 'PretendardLight',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(StudyRoomMemberModel m, ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StandardText(
            text: '${m.weeklyProblemCount}',
            fontSize: 16,
            color: themeProvider.primaryColor,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
          ),
          StandardText(
            text: '문제',
            fontSize: 10,
            color: Colors.grey[600]!,
            fontWeight: FontWeight.normal,
            fontFamily: 'PretendardLight',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
