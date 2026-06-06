import 'package:flutter/material.dart';

import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class GoalProgressBar extends StatelessWidget {
  final int current;
  final int goal;
  final ThemeHandler themeProvider;

  const GoalProgressBar({
    super.key,
    required this.current,
    required this.goal,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0);
    final isComplete = current >= goal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StandardText(
              text: '목표 달성률',
              fontSize: 11,
              color: Colors.grey[500]!,
              fontWeight: FontWeight.normal,
              fontFamily: 'PretendardLight',
            ),
            Row(
              children: [
                if (isComplete) const Text('✅', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 2),
                StandardText(
                  text: '$current / ${goal}문제',
                  fontSize: 11,
                  color: isComplete
                      ? themeProvider.primaryColor
                      : Colors.grey[600]!,
                  fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
                  fontFamily: isComplete ? 'PretendardBold' : 'PretendardLight',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: Colors.grey[100],
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete
                  ? themeProvider.primaryColor
                  : themeProvider.primaryColor.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }
}
