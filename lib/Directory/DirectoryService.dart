import 'package:mvp_front/Directory/ProblemThumbnailModel.dart';
import 'package:mvp_front/Provider/ProblemsProvider.dart'; // ProblemsProvider import
import 'dart:developer';

class DirectoryService {
  final ProblemsProvider problemsProvider;

  DirectoryService(this.problemsProvider);

  // 문제 목록을 ProblemThumbnailModel 리스트로 변환하는 함수
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
