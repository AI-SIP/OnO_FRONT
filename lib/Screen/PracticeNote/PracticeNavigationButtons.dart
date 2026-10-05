import 'package:flutter/material.dart';
import '../../Module/Dialog/UnsavedChangesScope.dart';
import 'package:ono/Screen/PracticeNote/PracticeCompletionScreen.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreen.dart';
import 'package:ono/Screen/ProblemSolve/ProblemSolveEntry.dart';

import '../../Provider/PracticeNoteProvider.dart';
import '../../Module/Motion/TossPageRoute.dart';

/// 마치기를 기다리는 중인지. 두 번 눌리면 완료 화면이 이 화면이 아니라 먼저
/// 뜬 완료 화면을 갈아 끼워서, 닫을 때 한 화면이 남았다.
bool _openingCompletion = false;

/// 복습 세트의 이번 회차를 마친다. 넘기기만 해도 마칠 수 있어서, 하나도
/// 저장하지 않았으면 한 번 묻는다.
Future<void> finishPracticeSession(
    BuildContext context, ProblemPracticeProvider practiceProvider) async {
  // 완료 화면으로 바뀌는 중에 한 번 더 눌려도 다시 열지 않는다.
  if (_openingCompletion || !(ModalRoute.of(context)?.isCurrent ?? true)) {
    return;
  }
  _openingCompletion = true;
  try {
    if (practiceProvider.sessionResults.isEmpty) {
      final finish = await confirmLeave(
        context,
        source: 'practice_finish_without_solve',
        title: '아직 저장한 복습이 없어요',
        description: '그래도 이번 회차를 마칠까요?',
        stayLabel: '더 풀기',
        leaveLabel: '마치기',
      );
      if (!finish || !context.mounted) return;
    }
    openPracticeCompletion(context, practiceProvider);
  } finally {
    _openingCompletion = false;
  }
}

/// 복습 세트의 다른 문제로 넘어간다. 아래 이전/다음 버튼과 `다음 문제 풀까요`
/// 시트가 같이 쓴다. [autoStartMode] 를 넘기면 넘어가자마자 그 방식으로 푼다.
void openPracticeProblem(
  BuildContext context,
  int problemId, {
  required bool isNext,
  ProblemSolveMode? autoStartMode,
}) {
  Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ProblemDetailScreen(
        problemId: problemId,
        isPractice: true,
        autoStartMode: autoStartMode,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Offset begin =
            isNext ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        // 회전 효과는 이 화면에만 있어서 뺐다. 옆으로 미는 것만 남긴다.
        return SlideTransition(position: offsetAnimation, child: child);
      },
    ),
  );
}

/// 복습 세트를 마치고 완료 화면으로 간다.
void openPracticeCompletion(
    BuildContext context, ProblemPracticeProvider practiceProvider) {
  final practiceId = practiceProvider.currentPracticeNote!.practiceId;
  final totalProblems = practiceProvider.sessionProblems.length;
  final results = practiceProvider.sessionResults.values.toList();
  final matchingPractices = practiceProvider.practices
      .where((practice) => practice.practiceId == practiceId);
  final practiceRound =
      matchingPractices.isNotEmpty ? matchingPractices.first.practiceCount : 0;

  Navigator.of(context).pushReplacement(
    TossPageRoute(
      builder: (context) => PracticeCompletionScreen(
        practiceId: practiceId,
        totalProblems: totalProblems,
        practiceRound: practiceRound + 1,
        sessionResults: results,
      ),
    ),
  );
}
