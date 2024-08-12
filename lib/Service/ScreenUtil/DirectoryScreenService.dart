import 'dart:developer';

import 'package:flutter/material.dart';

import '../../Model/ProblemThumbnailModel.dart';
import '../../Provider/ProblemsProvider.dart';
import '../../Screen/ProblemDetailScreen.dart';

class DirectoryScreenService {
  final ProblemsProvider problemsProvider;

  DirectoryScreenService(this.problemsProvider);

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

  Future<void> fetchProblems() async {
    try {
      await problemsProvider.fetchProblems();
    } catch (e) {
      log('Failed to fetch problems: $e');
    }
  }

  void sortProblems(String option) {
    if (option == 'name') {
      problemsProvider.sortProblemsByName('root');
    } else if (option == 'newest') {
      problemsProvider.sortProblemsByNewest('root');
    } else if (option == 'oldest') {
      problemsProvider.sortProblemsByOldest('root');
    }
  }

  void navigateToProblemDetail(BuildContext context, int? problemId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProblemDetailScreen(problemId: problemId),
      ),
    ).then((value) {
      if (value == true) {
        fetchProblems();
      }
    });
  }
}
