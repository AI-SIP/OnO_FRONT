import 'package:flutter/material.dart';
import 'package:ono/Model/Problem/ReviewDueProblemModel.dart';
import 'package:ono/Service/Api/Problem/ProblemService.dart';
import 'package:ono/Util/AppErrorReporter.dart';
import 'package:ono/Util/PendingDeletion.dart';

class ReviewDueProvider with ChangeNotifier {
  final ProblemService _problemService;

  ReviewDueProvider({ProblemService? problemService})
      : _problemService = problemService ?? ProblemService() {
    PendingDeletion.instance.addListener(notifyListeners);
  }

  ReviewDueResponse? _data;
  bool _isLoading = false;
  bool _hasError = false;

  /// 받아 둔 추천에서 지우는 중이거나 지운 문제를 뺀 것.
  ///
  /// 전에는 오답노트를 지우고 되돌리기를 기다리는 동안에도 추천 목록과 홈의
  /// 추천 개수에 그 문제가 남아 있었다.
  ReviewDueResponse? get data {
    final data = _data;
    if (data == null) return null;
    final pending = PendingDeletion.instance;
    final hidden =
        data.problems.where((p) => pending.isProblemHidden(p.problemId));
    if (hidden.isEmpty) return data;

    final today = DateUtils.dateOnly(DateTime.now());
    final hiddenOverdue = hidden.where((p) {
      final next = p.nextReviewAt;
      return next != null && DateUtils.dateOnly(next).isBefore(today);
    }).length;
    return ReviewDueResponse(
      dueCount: (data.dueCount - hidden.length).clamp(0, data.dueCount),
      overdueCount:
          (data.overdueCount - hiddenOverdue).clamp(0, data.overdueCount),
      requiredCorrectCount: data.requiredCorrectCount,
      problems: data.problems
          .where((p) => !pending.isProblemHidden(p.problemId))
          .toList(),
    );
  }

  bool get isLoading => _isLoading;

  /// 마지막 조회가 실패했는지. 받아 둔 목록이 없을 때 실패를 빈 목록과 구분한다.
  bool get hasError => _hasError;
  int get dueCount => data?.dueCount ?? 0;

  Future<void> fetchReviewDue() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      _data = await _problemService.getReviewDueProblems();
      _hasError = false;
    } catch (e, stackTrace) {
      _hasError = true;
      debugPrint('ReviewDueProvider fetchReviewDue error: $e');
      await AppErrorReporter.report(
        e,
        stackTrace,
        source: 'review_due_fetch',
        severity: AppErrorSeverity.warning,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    PendingDeletion.instance.removeListener(notifyListeners);
    super.dispose();
  }

  void clear() {
    _data = null;
    _hasError = false;
    notifyListeners();
  }
}
