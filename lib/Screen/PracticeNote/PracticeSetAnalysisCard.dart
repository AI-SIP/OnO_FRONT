import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Model/Problem/AnswerStatus.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Motion/Skeleton.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Text/mobile_font_size.dart';
import '../ProblemDetail/Widget/ReviewStatusStyle.dart';
import 'PracticeSetAnalysis.dart';

/// 결과마다 색과 이름. 아직 안 푼 문제는 회색이다.
abstract final class PracticeResultStyle {
  static Color color(PracticeProblemResult result) {
    switch (result) {
      case PracticeProblemResult.correct:
        return ReviewStatusStyle.color(AnswerStatus.CORRECT);
      case PracticeProblemResult.partial:
        return ReviewStatusStyle.color(AnswerStatus.PARTIAL);
      case PracticeProblemResult.wrong:
        return ReviewStatusStyle.color(AnswerStatus.WRONG);
      case PracticeProblemResult.unsolved:
        return Colors.grey.shade300;
    }
  }

  static Color textColor(PracticeProblemResult result) {
    switch (result) {
      case PracticeProblemResult.correct:
        return ReviewStatusStyle.textColor(AnswerStatus.CORRECT);
      case PracticeProblemResult.partial:
        return ReviewStatusStyle.textColor(AnswerStatus.PARTIAL);
      case PracticeProblemResult.wrong:
        return ReviewStatusStyle.textColor(AnswerStatus.WRONG);
      case PracticeProblemResult.unsolved:
        return Colors.grey.shade600;
    }
  }

  static String label(PracticeProblemResult result) {
    switch (result) {
      case PracticeProblemResult.correct:
        return '정답';
      case PracticeProblemResult.partial:
        return '부분 정답';
      case PracticeProblemResult.wrong:
        return '오답';
      case PracticeProblemResult.unsolved:
        return '안 풂';
    }
  }
}

/// 복습 세트 상세 맨 위에 놓는 세트 분석이다.
///
/// 세트 정보(복습 횟수, 마지막 복습, 평균 풀이 시간)를 두고, 그 아래에 문제마다
/// 최근 결과를 모아 보여 준다. 제목이나 바깥 테두리 없이 화면에 바로 놓는다.
class PracticeSetAnalysisCard extends StatelessWidget {
  /// 아직 받는 중이면 null.
  final PracticeSetAnalysis? analysis;

  /// 세트 정보. 예전에는 화면 맨 위에 따로 줄을 두었는데 여기로 옮겼다.
  final int practiceCount;
  final DateTime? lastSolvedAt;
  final Color accentColor;

  const PracticeSetAnalysisCard({
    super.key,
    required this.analysis,
    required this.practiceCount,
    required this.lastSolvedAt,
    required this.accentColor,
  });

  static double _body(BuildContext c) => MobileFontSize.reduced(c, 15);
  static double _sub(BuildContext c) => MobileFontSize.reduced(c, 13);
  static const double _tiny = 12;

  /// 덩어리 사이 세로 간격.
  static const double _sectionGap = 28;

  @override
  Widget build(BuildContext context) {
    // 바깥 카드로 한 번 더 감싸면 안쪽 칸들과 여백이 두 겹이 되어 답답했다.
    // 화면 좌우 여백만 두고 바로 놓는다.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStats(context),
        const SizedBox(height: _sectionGap),
        if (analysis == null) _buildLoading() else _buildBody(context),
      ],
    );
  }

  /// 복습 횟수, 마지막 복습, 평균 풀이 시간을 세 칸으로 나란히 둔다.
  Widget _buildStats(BuildContext context) {
    final last = lastSolvedAt;
    final average = analysis?.averageSeconds;
    final items = [
      ('복습 횟수', '$practiceCount회'),
      (
        '마지막 복습',
        last == null ? '기록 없음' : DateFormat('yyyy/MM/dd').format(last)
      ),
      // 기록을 받는 중이거나 시간이 남은 기록이 없으면 비워 둔다.
      ('평균 풀이 시간', average == null ? '-' : formatDuration(average)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Container(width: 1, height: 28, color: AppColors.border),
            Expanded(
              child: Column(
                children: [
                  StandardText(
                    text: items[i].$1,
                    fontSize: _tiny,
                    color: Colors.grey[600]!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StandardText(
                      text: items[i].$2,
                      fontSize: _body(context),
                      color: AppColors.textPrimary,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkeletonBox(height: 20),
        SizedBox(height: 12),
        SkeletonBox(height: 12),
        SizedBox(height: 12),
        SkeletonBox(height: 40),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final analysis = this.analysis!;
    final content = _buildSummary(context, analysis);

    if (!analysis.partiallyFailed) return content;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        const SizedBox(height: 10),
        StandardText(
          text: '일부 문제의 기록을 불러오지 못했어요',
          fontSize: _tiny,
          color: Colors.grey[600]!,
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context, PracticeSetAnalysis analysis) {
    final total = analysis.total;
    final headline = total == 0
        ? '아직 불러온 기록이 없어요'
        : '$total문제 중 ${analysis.correctCount}문제를 최근에 맞혔어요';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StandardText(
          text: headline,
          fontSize: _body(context),
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        if (total > 0) ...[
          const SizedBox(height: 16),
          _buildBar(analysis),
          const SizedBox(height: 12),
          _buildLegend(context, analysis),
        ],
      ],
    );
  }

  Widget _buildBar(PracticeSetAnalysis analysis) {
    final segments = [
      for (final result in PracticeProblemResult.values)
        if (analysis.countOf(result) > 0)
          (result: result, count: analysis.countOf(result)),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                flex: segments[i].count,
                child: Container(
                  color: PracticeResultStyle.color(segments[i].result),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, PracticeSetAnalysis analysis) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final result in PracticeProblemResult.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: PracticeResultStyle.color(result),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              StandardText(
                text:
                    '${PracticeResultStyle.label(result)} ${analysis.countOf(result)}',
                fontSize: _sub(context),
                color: Colors.grey[700]!,
              ),
            ],
          ),
      ],
    );
  }

  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    if (minutes == 0) return '$rest초';
    if (rest == 0) return '$minutes분';
    return '$minutes분 $rest초';
  }
}
