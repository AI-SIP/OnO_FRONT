import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Model/StudyRoom/ActivityFeedModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Provider/StudyRoomProvider.dart';
import 'FeedReactionBar.dart';

class ActivityFeedItem extends StatelessWidget {
  final ActivityFeedModel feed;
  final int roomId;

  const ActivityFeedItem({
    super.key,
    required this.feed,
    required this.roomId,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  IconData _eventIcon(String eventType) {
    switch (eventType) {
      case 'problem_registered':
        return Icons.edit_note;
      case 'practice_completed':
        return Icons.chrome_reader_mode_outlined;
      case 'streak_milestone':
        return Icons.local_fire_department_outlined;
      case 'level_up':
        return Icons.trending_up_rounded;
      case 'challenge_cleared':
        return Icons.flag_outlined;
      case 'session_started':
        return Icons.timer_outlined;
      case 'problem_shared':
        return Icons.ios_share_outlined;
      default:
        return Icons.bolt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final provider = Provider.of<StudyRoomProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: themeProvider.primaryColor.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _eventIcon(feed.eventType),
                  size: 18,
                  color: themeProvider.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StandardText(
                      text: feed.displayText,
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 3),
                    StandardText(
                      text: _timeAgo(feed.createdAt),
                      fontSize: 11,
                      color: Colors.grey[500]!,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'PretendardLight',
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (feed.reactions.isNotEmpty || true) ...[
            const SizedBox(height: 6),
            FeedReactionBar(
              reactions: feed.reactions,
              themeProvider: themeProvider,
              onToggle: (emoji) =>
                  provider.toggleFeedReaction(feed.feedId, emoji),
            ),
          ],
        ],
      ),
    );
  }
}
