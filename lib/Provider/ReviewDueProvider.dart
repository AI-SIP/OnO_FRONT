import 'package:flutter/material.dart';
import 'package:ono/Model/Problem/ReviewDueProblemModel.dart';
import 'package:ono/Service/Api/Problem/ProblemService.dart';
import 'package:ono/Util/AppErrorReporter.dart';

class ReviewDueProvider with ChangeNotifier {
  final ProblemService _problemService;

  ReviewDueProvider({ProblemService? problemService})
      : _problemService = problemService ?? ProblemService();

  ReviewDueResponse? _data;
  bool _isLoading = false;
  bool _hasError = false;

  ReviewDueResponse? get data => _data;
  bool get isLoading => _isLoading;

  /// 마지막 조회가 실패했는지. 받아 둔 목록이 없을 때 실패를 빈 목록과 구분한다.
  bool get hasError => _hasError;
  int get dueCount => _data?.dueCount ?? 0;

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

  void clear() {
    _data = null;
    _hasError = false;
    notifyListeners();
  }
}
