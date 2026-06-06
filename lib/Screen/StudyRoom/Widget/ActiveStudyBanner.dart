import 'package:flutter/material.dart';

import '../../../Model/StudyRoom/StudySessionModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class ActiveStudyBanner extends StatelessWidget {
  final List<StudySessionModel> sessions;
  final ThemeHandler themeProvider;

  const ActiveStudyBanner({
    super.key,
    required this.sessions,
    required this.themeProvider,
  });

  String _elapsed(DateTime start) {
    final diff = DateTime.now().difference(start);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: sessions
                  .map(
                    (s) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StandardText(
                          text: s.name,
                          fontSize: 13,
                          color: themeProvider.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        StandardText(
                          text: _elapsed(s.startedAt),
                          fontSize: 12,
                          color: Colors.grey[600]!,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'PretendardLight',
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          StandardText(
            text: '공부 중',
            fontSize: 12,
            color: Colors.green[700]!,
          ),
        ],
      ),
    );
  }
}
