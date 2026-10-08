import 'package:flutter/material.dart';

import '../../../../Model/LearningReport/LearningOverviewModel.dart';
import '../../../../Module/Design/AppColors.dart';
import '../../../../Module/Motion/AnimatedCountText.dart';
import '../../../../Module/Motion/AnimatedGauge.dart';
import '../../../../Module/Motion/AppMotion.dart';
import '../../../../Module/Motion/AppearTransition.dart';
import '../../../../Module/Text/StandardText.dart';
import 'ReportCard.dart';
import 'ReportPalette.dart';
import 'ReportWording.dart';

/// 오답노트 전체가 지금 어떤 상태인지. 확실히 아는 문제, 헷갈리는 문제,
/// 안 풀어본 문제 세 단계로 나눈다.
///
/// 기간과 상관없이 오늘 기준이다. 지난 주를 넘겨 봐도 같은 숫자가 나온다.
class NoteStatusCard extends StatelessWidget {
  final LearningNoteStatus status;
  final ReportWording wording;
  final Duration delay;

  const NoteStatusCard({
    super.key,
    required this.status,
    required this.wording,
    this.delay = Duration.zero,
  });

  /// 카드가 거의 다 올라온 뒤에 숫자와 막대가 차오르기 시작한다.
  static final Duration _gaugeDelay = AppMotion.stagger * 2.5;

  @override
  Widget build(BuildContext context) {
    if (status.totalCount <= 0) {
      return const ReportCard(
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: StandardText(
          text: '아직 등록한 오답노트가 없어요',
          fontSize: 15,
          height: 1.4,
          color: AppColors.textPrimary,
        ),
      );
    }

    final levels = [
      _Level(
        label: '확실히 아는 문제',
        description: '연달아 ${status.knownThreshold}번 맞힌 문제',
        count: status.knownCount,
        color: ReportPalette.green,
      ),
      _Level(
        label: '헷갈리는 문제',
        description: '맞혔다 틀렸다 하는 문제',
        count: status.unsureCount,
        color: ReportPalette.orange,
      ),
      _Level(
        label: '안 풀어본 문제',
        description: '등록만 하고 아직 안 푼 문제',
        count: status.unsolvedCount,
        color: ReportPalette.gray,
      ),
    ];

    // 전체는 지금까지 확실히 알게 된 수와 같아져서 따로 적을 게 없다.
    final showNewlyKnown = status.newlyKnownCount > 0 && !wording.isTotal;

    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReportCardTitle('오답노트 상태'),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 36),
                child: ReportTracking(
                  letterSpacing: -1,
                  child: AnimatedCountText(
                    value: status.knownCount,
                    fontSize: 32,
                    height: 1.2,
                    color: ReportPalette.greenInk,
                    delay: delay + _gaugeDelay,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: StandardText(
                  text: '/ ${status.totalCount}문제 확실히 알아요',
                  fontSize: 15,
                  height: 1.3,
                  fontFamily: 'PretendardLight',
                  fontWeight: FontWeight.w300,
                  color: ReportPalette.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _StackedBar(levels: levels, delay: delay + _gaugeDelay),
          const SizedBox(height: 18),
          ...AppearTransition.stagger(
            [
              for (var i = 0; i < levels.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 16),
                  child: _LevelRow(level: levels[i], total: status.totalCount),
                ),
            ],
            initialDelay: delay + _gaugeDelay + AppMotion.stagger,
          ),
          if (showNewlyKnown) ...[
            const SizedBox(height: 18),
            _NewlyKnownRow(
              text: wording.inThisPeriod,
              count: status.newlyKnownCount,
            ),
          ],
        ],
      ),
    );
  }
}

class _Level {
  final String label;
  final String description;
  final int count;
  final Color color;

  const _Level({
    required this.label,
    required this.description,
    required this.count,
    required this.color,
  });
}

/// 세 단계를 한 줄로 이은 막대. 왼쪽에서 오른쪽으로 차오른다.
class _StackedBar extends StatelessWidget {
  final List<_Level> levels;
  final Duration delay;

  const _StackedBar({required this.levels, required this.delay});

  @override
  Widget build(BuildContext context) {
    // 0 인 칸은 빼야 칸 사이 틈이 두 겹으로 보이지 않는다.
    final visible = levels.where((l) => l.count > 0).toList();
    const radius = BorderRadius.all(Radius.circular(6));

    return Container(
      height: 12,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: ReportPalette.divider,
        borderRadius: radius,
      ),
      child: AnimatedGaugeValue(
        value: 1,
        delay: delay,
        builder: (context, progress) => Align(
          alignment: Alignment.centerLeft,
          // 막대 전체를 그려 두고 보이는 폭만 넓힌다. 칸 폭을 같이 키우면
          // 차오르는 동안 칸 사이 비율이 흔들린다.
          child: ClipRRect(
            borderRadius: radius,
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Row(
                children: [
                  for (var i = 0; i < visible.length; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      flex: visible[i].count,
                      child: Container(
                        decoration: BoxDecoration(
                          color: visible[i].color,
                          borderRadius: radius,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  final _Level level;
  final int total;

  const _LevelRow({required this.level, required this.total});

  @override
  Widget build(BuildContext context) {
    final percent = total <= 0 ? 0 : (level.count / total * 100).round();

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: level.color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReportTracking(
                letterSpacing: -0.2,
                child: StandardText(
                  text: level.label,
                  fontSize: 15,
                  height: 1.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              StandardText(
                text: level.description,
                fontSize: 13,
                height: 1.3,
                fontFamily: 'PretendardLight',
                fontWeight: FontWeight.w300,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StandardText(
              text: '${level.count}',
              fontSize: 15,
              height: 1.3,
              color: AppColors.textPrimary,
            ),
            const SizedBox(height: 2),
            StandardText(
              text: '$percent%',
              fontSize: 12,
              height: 1.3,
              fontFamily: 'PretendardLight',
              fontWeight: FontWeight.w300,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ],
    );
  }
}

/// `이번 주에 3문제가 확실히 아는 문제가 됐어요`.
///
/// 그 문제들을 모아 보여 줄 화면이 아직 없어서 누를 수 없는 줄로 둔다.
/// 화살표를 달면 눌러 보고 아무 일도 없어서 고장 난 것처럼 보인다.
class _NewlyKnownRow extends StatelessWidget {
  /// `이번 주에`, `이 달에` 처럼 앞에 붙는 말.
  final String text;
  final int count;

  const _NewlyKnownRow({required this.text, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
      decoration: BoxDecoration(
        color: ReportPalette.greenSoft,
        borderRadius: BorderRadius.circular(ReportPalette.buttonRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: ReportPalette.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$text '),
                  TextSpan(
                    text: '$count문제',
                    style: const TextStyle(
                      fontFamily: 'PretendardBold',
                      fontWeight: FontWeight.w700,
                      color: ReportPalette.greenInk,
                    ),
                  ),
                  const TextSpan(text: '가 확실히 아는 문제가 됐어요'),
                ],
              ),
              style: const TextStyle(
                fontFamily: 'PretendardLight',
                fontWeight: FontWeight.w300,
                fontSize: 14,
                height: 1.4,
                // 폰 폭에서 `됐어요` 의 마지막 글자 하나만 다음 줄로 넘어가서
                // 자간을 조금 좁혀 한 줄에 넣는다.
                letterSpacing: -0.3,
                color: ReportPalette.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
