import 'package:flutter/material.dart';

import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Module/User/ProfileAvatar.dart';

class ChallengeProgressBar extends StatelessWidget {
  final int current;
  final int target;
  final ThemeHandler themeProvider;
  final String? label;
  final String? profileImageUrl;

  const ChallengeProgressBar({
    super.key,
    required this.current,
    required this.target,
    required this.themeProvider,
    this.label,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0);
    final isDone = current >= target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (label != null)
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProfileAvatar(
                      imageUrl: profileImageUrl,
                      size: 20,
                      borderColor:
                          themeProvider.primaryColor.withValues(alpha: 0.18),
                      backgroundColor:
                          themeProvider.primaryColor.withValues(alpha: 0.08),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: StandardText(
                        text: label!,
                        fontSize: 12,
                        color: Colors.grey[700]!,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'PretendardBold',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                if (isDone) ...[
                  const Text('✅', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 2),
                ],
                StandardText(
                  text: '$current / $target',
                  fontSize: 12,
                  color:
                      isDone ? themeProvider.primaryColor : Colors.grey[600]!,
                  fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                  fontFamily: isDone ? 'PretendardBold' : 'PretendardLight',
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
            minHeight: 6,
            backgroundColor: Colors.grey[100],
            valueColor: AlwaysStoppedAnimation<Color>(
              isDone
                  ? themeProvider.primaryColor
                  : themeProvider.primaryColor.withOpacity(0.55),
            ),
          ),
        ),
      ],
    );
  }
}
