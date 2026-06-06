import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Model/StudyRoom/SharedProblemModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Provider/StudyRoomProvider.dart';
import 'FeedReactionBar.dart';

class SharedProblemCard extends StatelessWidget {
  final SharedProblemModel problem;

  const SharedProblemCard({super.key, required this.problem});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final provider = Provider.of<StudyRoomProvider>(context, listen: false);
    final primary = themeProvider.primaryColor;
    final p = problem;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 17,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StandardText(
                        text: p.sharedByName,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      StandardText(
                        text: _timeAgo(p.sharedAt),
                        fontSize: 11,
                        color: Colors.grey[400]!,
                        fontWeight: FontWeight.normal,
                        fontFamily: 'PretendardLight',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.055),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primary.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProblemPreview(primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StandardText(
                          text: p.reference,
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        StandardText(
                          text: '눌러서 같이 풀어보기',
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
            ),
          ),
          if (p.comment != null && p.comment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: StandardText(
                text: p.comment!,
                fontSize: 13,
                color: Colors.grey[700]!,
                fontWeight: FontWeight.normal,
                fontFamily: 'PretendardLight',
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
            child: FeedReactionBar(
              reactions: p.reactions,
              themeProvider: themeProvider,
              onToggle: (emoji) => provider.toggleSharedProblemReaction(
                  p.sharedProblemId, emoji),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemPreview(Color primary) {
    return Container(
      width: 46,
      height: 56,
      padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withValues(alpha: 0.18), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 5,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Container(
                height: 3,
                width: index == 2 ? 18 : 28,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: index == 0 ? 0.35 : 0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
