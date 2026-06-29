import 'package:flutter/material.dart';
import 'package:ono/Model/Problem/ReviewDueProblemModel.dart';
import 'package:ono/Service/Api/Problem/ProblemService.dart';
import 'package:ono/Util/AppErrorReporter.dart';

class ReviewDueProvider with ChangeNotifier {
  final ProblemService _problemService = ProblemService();

  ReviewDueResponse? _data;
  bool _isLoading = false;

  ReviewDueResponse? get data => _data;
  bool get isLoading => _isLoading;
  int get dueCount => _data?.dueCount ?? 0;

  Future<void> fetchReviewDue() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      _data = await _problemService.getReviewDueProblems();
    } catch (e, stackTrace) {
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
    notifyListeners();
  }
}
