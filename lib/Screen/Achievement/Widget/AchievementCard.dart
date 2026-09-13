import 'package:flutter/material.dart';

import '../../../Model/Achievement/AchievementModel.dart';
import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Design/AppSpacing.dart';
import '../../../Module/Motion/AnimatedGauge.dart';
import '../../../Module/Text/StandardText.dart';
import 'AchievementMedal.dart';

/// 훈장 한 줄이다.
///
/// 상태가 셋이고 한눈에 갈라져야 한다. 옷장 격자와 같은 규칙을 가로로 편 것이다.
///
/// - **방금 받음**: 흰 카드 위에 테마색을 옅게 깔고 `NEW` 를 단다
/// - **받음**: 흰 카드, 그림은 제 색
/// - **아직**: 눌러 둔 면에 흑백 그림, 아래에 얼마나 남았는지
///
/// 맨 아래 한 줄은 상태마다 말이 다르다.
///
/// | 상태 | 아래 줄 | 눈금 |
/// |---|---|---|
/// | 받음 | `9월 14일에 받았어요` | 없음 |
/// | 아직 · 진행도 있음 | `87 / 100` | 있음 |
/// | 아직 · 진행도 없음 | `한 번만 해내면 받아요` | 없음 |
///
/// **눈금은 아직 못 받은 것에만 둔다.** 받은 것에도 가득 찬 눈금을 세우면 열두
/// 줄이 전부 눈금이 되어, 정작 코앞에 온 하나가 그 속에 묻힌다. 받았다는 것은
/// 제 색을 되찾은 그림이 이미 말하고 있다.
///
/// **진행도가 없는 둘(불사조·첫 걸음)에는 눈금을 안 만든다.** 서버가
/// `current` 와 `target` 을 null 로 준다. 둘 다 0 아니면 1이라 눈금을 세우면
/// 늘 텅 비어 있게 되는데, 빈 눈금은 "아직 하나도 못 했다"로 읽힌다. 불사조는
/// 틀린 문제를 한 번 다시 맞히기만 하면 되는 한 번짜리라 그 말이 사실과 다르다.
/// 눈금 대신 **한 번이면 된다는 것을 글로 적는다.** 자리를 비워 두지 않는 것은,
/// 열두 줄 중 두 줄만 아래가 허전하면 그 둘이 덜 만들어진 것처럼 보이기 때문이다.
class AchievementCard extends StatelessWidget {
  final AchievementModel achievement;

  /// 이번에 새로 받은 것인지. `NEW` 가 붙는다.
  final bool isNew;

  /// 강조색. 사용자가 테마에서 고른 색이다.
  final Color color;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.isNew,
    required this.color,
  });

  /// 훈장 그림 한 변.
  ///
  /// 고정값인 것은 **그림이 줄마다 같은 크기로 서야 목록이 줄로 읽히기**
  /// 때문이다. 카드의 가로는 화면을 따라 늘고 줄지만 이 한 변은 그대로 둔다.
  /// 글자를 키운 기기에서는 옆의 글 덩어리가 세로로 늘어나고 그림은 위에
  /// 붙어 있는다.
  static const double _medalSize = 64.0;

  bool get _earned => achievement.earned;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _faceColor,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: isNew ? color.withValues(alpha: 0.45) : AppColors.border,
          width: isNew ? 1.6 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AchievementMedal(
            imageUrl: achievement.imageUrl,
            size: _medalSize,
            locked: !_earned,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNameRow(),
                StandardText(
                  text: achievement.descriptionKo,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _earned
                      ? AppColors.textSecondary
                      : AppColors.textTertiary,
                  height: 1.4,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildStatusLine(),
                if (_showGauge) ...[
                  const SizedBox(height: 6),
                  AnimatedLinearGauge(
                    value: achievement.progressRatio,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.16),
                    height: 5,
                    borderRadius: 3,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 받은 것은 흰 면, 아직인 것은 한 단계 눌러 둔 면이다. 방금 받은 것만
  /// 테마색을 옅게 섞어 목록에서 먼저 눈에 띈다.
  Color get _faceColor {
    if (isNew) {
      return Color.alphaBlend(color.withValues(alpha: 0.08), Colors.white);
    }
    return _earned ? AppColors.surface : AppColors.surfaceMuted;
  }

  bool get _showGauge => !_earned && achievement.hasProgress;

  Widget _buildNameRow() {
    return Row(
      children: [
        Flexible(
          child: StandardText(
            text: achievement.nameKo,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _earned ? AppColors.textPrimary : AppColors.textDisabled,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            height: 1.4,
          ),
        ),
        if (isNew) ...[
          const SizedBox(width: AppSpacing.sm),
          _buildNewBadge(),
        ],
      ],
    );
  }

  /// 방금 받은 것에 붙는 표시. 옷장 격자가 쓰는 것과 같은 모양이다.
  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: const StandardText(
        text: 'NEW',
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        maxLines: 1,
        height: 1.4,
      ),
    );
  }

  /// 맨 아래 한 줄. 세 상태가 이 자리에서 갈린다.
  Widget _buildStatusLine() {
    return StandardText(
      text: statusTextOf(achievement),
      fontSize: 11,
      fontWeight: _showGauge ? FontWeight.w700 : FontWeight.w500,
      color: _showGauge ? color : AppColors.textTertiary,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      height: 1.4,
    );
  }

  /// 아래 줄에 적을 말. 화면 테스트가 같은 것을 보므로 밖에서도 부를 수 있게 둔다.
  static String statusTextOf(AchievementModel achievement) {
    if (achievement.earned) {
      final at = achievement.earnedAt;
      if (at == null) return '받았어요';
      return '${at.year}년 ${at.month}월 ${at.day}일에 받았어요';
    }

    if (achievement.hasProgress) {
      return '${achievement.current} / ${achievement.target}';
    }

    // 0 아니면 1인 훈장. 눈금을 세울 것이 없어서 한 번이면 된다고 적는다.
    return '한 번만 해내면 받아요';
  }
}
