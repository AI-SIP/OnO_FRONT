import 'package:flutter/material.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Text/mobile_font_size.dart';
import '../ProblemSolve/ProblemSolveEntry.dart';

/// 복습 세트에서 한 문제를 저장하고 돌아왔을 때 무엇을 할지.
enum PracticeContinueChoice {
  /// 다음 문제로 넘어가면서 같은 방식으로 바로 푼다.
  solveNext,

  /// 다음 문제 상세로만 넘어간다.
  viewNext,

  /// 지금 문제에 머문다. 시트를 그냥 닫아도 이것이다.
  stop,

  /// 마지막 문제였고 복습을 마친다.
  finish,
}

extension PracticeContinueChoiceName on PracticeContinueChoice {
  /// 애널리틱스에 남기는 값.
  String get analyticsName => switch (this) {
        PracticeContinueChoice.solveNext => 'solve_next',
        PracticeContinueChoice.viewNext => 'view_next',
        PracticeContinueChoice.stop => 'stop',
        PracticeContinueChoice.finish => 'finish',
      };
}

/// 복습 세트에서 한 문제를 저장하고 돌아오면 다음 문제를 바로 풀지 묻는다.
///
/// [solvedPosition] 은 방금 푼 문제가 세트에서 몇 번째인지(1부터)다. [next] 가
/// null 이면 마지막 문제였다는 뜻이라 복습을 마칠지 묻는다.
///
/// 추천 복습에서도 같은 시트를 쓴다. 그때는 마지막 문제에서 묻는 말과 버튼을
/// [finishQuestion], [finishLabel], [finishDescription] 으로 바꾼다.
Future<PracticeContinueChoice> showPracticeContinueSheet(
  BuildContext context, {
  required int solvedPosition,
  required int total,
  required ProblemModel? next,
  required ProblemSolveMode mode,
  required Color accentColor,
  String finishQuestion = '복습 세트를 마칠까요?',
  String finishLabel = '복습 마치기',
  String finishDescription = '이번 회차를 마쳐요.',
}) async {
  final choice = await showModalBottomSheet<PracticeContinueChoice>(
    context: context,
    sheetAnimationStyle: AppMotion.sheetStyle,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _PracticeContinueSheet(
      solvedPosition: solvedPosition,
      total: total,
      next: next,
      mode: mode,
      accentColor: accentColor,
      finishQuestion: finishQuestion,
      finishLabel: finishLabel,
      finishDescription: finishDescription,
    ),
  );
  return choice ?? PracticeContinueChoice.stop;
}

/// `다시 풀기 방식 선택` 시트와 같은 모양이다. 왼쪽 아이콘 상자와 제목, 아래
/// 선택 카드, 맨 아래 글자 버튼.
class _PracticeContinueSheet extends StatelessWidget {
  final int solvedPosition;
  final int total;
  final ProblemModel? next;
  final ProblemSolveMode mode;
  final Color accentColor;
  final String finishQuestion;
  final String finishLabel;
  final String finishDescription;

  const _PracticeContinueSheet({
    required this.solvedPosition,
    required this.total,
    required this.next,
    required this.mode,
    required this.accentColor,
    required this.finishQuestion,
    required this.finishLabel,
    required this.finishDescription,
  });

  String get _nextTitle {
    final reference = next?.reference?.trim() ?? '';
    return reference.isEmpty ? '제목 없는 문제' : reference;
  }

  @override
  Widget build(BuildContext context) {
    final finished = next == null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Icon(
                  finished ? Icons.emoji_events_outlined : Icons.task_alt,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StandardText(
                      text: finished
                          ? '마지막 문제까지 풀었어요'
                          : '$solvedPosition / $total 복습 끝!',
                      fontSize: MobileFontSize.reduced(context, 20),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    // 이 시트는 세트의 몇 문제를 실제로 풀었는지 모른다. 마지막
                    // 문제라는 것만 알아서 '모두 복습했다' 고 말하지 않는다.
                    StandardText(
                      text: finished ? finishQuestion : '다음 문제도 이어서 풀까요?',
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (finished)
            _ChoiceTile(
              icon: Icons.flag_outlined,
              title: finishLabel,
              description: finishDescription,
              accentColor: accentColor,
              highlighted: true,
              onTap: () =>
                  Navigator.pop(context, PracticeContinueChoice.finish),
            )
          else ...[
            _ChoiceTile(
              icon: Icons.play_arrow_rounded,
              title: '다음 문제 바로 풀기',
              description: _nextTitle,
              accentColor: accentColor,
              highlighted: true,
              onTap: () =>
                  Navigator.pop(context, PracticeContinueChoice.solveNext),
            ),
            const SizedBox(height: 10),
            _ChoiceTile(
              icon: Icons.visibility_outlined,
              title: '문제 먼저 볼게요',
              description: '다음 문제를 먼저 살펴보고 풀어요.',
              accentColor: accentColor,
              onTap: () =>
                  Navigator.pop(context, PracticeContinueChoice.viewNext),
            ),
          ],
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.pop(context, PracticeContinueChoice.stop),
              style: TextButton.styleFrom(minimumSize: const Size(88, 44)),
              child: StandardText(
                text: finished ? '닫기' : '그만할게요',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `다시 풀기 방식 선택` 의 선택 카드와 같은 모양. [highlighted] 면 권하는
/// 쪽이라 테두리와 바탕을 테마 색으로 조금 더 칠한다.
class _ChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final VoidCallback onTap;
  final bool highlighted;

  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: PressableScale(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: highlighted
                ? accentColor.withValues(alpha: 0.06)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: accentColor.withValues(alpha: highlighted ? 0.4 : 0.18),
              width: highlighted ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      accentColor.withValues(alpha: highlighted ? 0.16 : 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(icon, color: accentColor, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StandardText(
                      text: title,
                      fontSize: MobileFontSize.reduced(context, 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    const SizedBox(height: 4),
                    StandardText(
                      text: description,
                      fontSize: 13,
                      color: Colors.black54,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }
}
