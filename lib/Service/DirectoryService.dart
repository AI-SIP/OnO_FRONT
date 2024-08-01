import 'dart:developer';

import '../Model/ProblemThumbnailModel.dart';
import '../Provider/ProblemsProvider.dart';

class DirectoryService {
  final ProblemsProvider problemsProvider;

  DirectoryService(this.problemsProvider);

  List<ProblemThumbnailModel> loadProblems() {
    if (problemsProvider.problems.isNotEmpty) {
      return problemsProvider.problems
          .map((problem) => ProblemThumbnailModel.fromJson(problem.toJson()))
          .toList();
    } else {
      log('No problems loaded');
      return [];
    }
  }
}
