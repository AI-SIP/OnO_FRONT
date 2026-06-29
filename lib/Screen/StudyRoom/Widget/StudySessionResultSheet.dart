import 'package:flutter/material.dart';

import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class StudySessionResultSheet extends StatelessWidget {
  final int minutes;
  final ThemeHandler themeProvider;

  const StudySessionResultSheet({
    super.key,
    required this.minutes,
    required this.themeProvider,
  });

  static Future<void> show(
    BuildContext context,
    int minutes,
    ThemeHandler themeProvider,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StudySessionResultSheet(
        minutes: minutes,
        themeProvider: themeProvider,
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes분';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '$h시간 $m분' : '$h시간';
  }

  @override
  Widget build(BuildContext context) {
    final primary = themeProvider.primaryColor;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    minutes >= 30 ? '🎉' : '📚',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const StandardText(
                text: '공부 세션 종료!',
                fontSize: 20,
                color: Colors.black87,
              ),
              const SizedBox(height: 8),
              StandardText(
                text: '${_formatDuration(minutes)} 동안 집중했어요',
                fontSize: 15,
                color: primary,
              ),
              const SizedBox(height: 6),
              StandardText(
                text: '스터디룸 멤버들에게 공개됩니다',
                fontSize: 13,
                color: Colors.grey[500]!,
                fontWeight: FontWeight.normal,
                fontFamily: 'PretendardLight',
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const StandardText(
                    text: '확인',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
