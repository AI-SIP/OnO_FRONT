import 'package:mvp_front/Model/ProblemThumbnailModel.dart';
import 'package:mvp_front/Provider/ProblemsProvider.dart'; // ProblemsProvider import
import 'dart:developer';

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
