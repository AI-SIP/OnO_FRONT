import 'package:flutter/material.dart';

import '../../../../Module/Design/AppColors.dart';
import '../../../../Module/Text/StandardText.dart';
import 'ReportCard.dart';
import 'ReportPalette.dart';

/// 오늘 복습할 문제 카드. 보고서를 보고 나서 바로 할 일을 하나 준다.
///
/// 숫자는 추천 복습 화면과 같은 `ReviewDueProvider` 에서 온다. 보고서 API 에
/// 따로 두면 두 화면의 개수가 어긋날 수 있다.
class ReviewDueCard extends StatelessWidget {
  final int dueCount;

  /// 목록 맨 앞(가장 밀린) 문제의 복습 예정일.
  final DateTime? oldestNextReviewAt;

  final DateTime today;
  final ReportPalette palette;
  final VoidCallback onStart;

  const ReviewDueCard({
    super.key,
    required this.dueCount,
    required this.oldestNextReviewAt,
    required this.today,
    required this.palette,
    required this.onStart,
  });

  /// 둘째 줄 문구. 예정일을 모르면 null 이라 줄을 비운다.
  ///
  /// N 은 문제를 푼 날이 아니라 복습할 날에서 며칠 밀렸는지라서, 푼 날로 읽히는
  /// 말("N일 전에 풀었던")을 쓰지 않는다.
  static String? subtitleFor(DateTime? oldestNextReviewAt, DateTime today) {
    if (oldestNextReviewAt == null) return null;
    final days = DateUtils.dateOnly(today)
        .difference(DateUtils.dateOnly(oldestNextReviewAt))
        .inDays;
    if (days <= 0) return '오늘 복습할 차례예요';
    return '$days일째 밀린 문제도 있어요';
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = subtitleFor(oldestNextReviewAt, today);

    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: palette.deep,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReportTracking(
                      letterSpacing: -0.3,
                      child: StandardText(
                        text: '오늘 복습할 문제 $dueCount개',
                        fontSize: 17,
                        height: 1.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      StandardText(
                        text: subtitle,
                        fontSize: 13,
                        height: 1.3,
                        fontFamily: 'PretendardLight',
                        fontWeight: FontWeight.w300,
                        color: ReportPalette.textMuted,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ReportPrimaryButton(label: '복습하기', onTap: onStart),
        ],
      ),
    );
  }
}
