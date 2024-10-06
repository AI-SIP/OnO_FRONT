import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreenV2.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../Model/ProblemThumbnailModel.dart';
import '../../Provider/FoldersProvider.dart';

class DirectoryScreenService {
  final FoldersProvider foldersProvider;

  DirectoryScreenService(this.foldersProvider);

  List<ProblemThumbnailModel> loadProblems() {
    if (foldersProvider.problems.isNotEmpty) {
      return foldersProvider.problems
          .map((problem) => ProblemThumbnailModel.fromJson(problem.toJson()))
          .toList();
    } else {
      log('No problems loaded');
      return [];
    }
  }

  Future<void> fetchProblems() async {
    try {
      await foldersProvider.fetchCurrentFolderContents();
    } catch (error, stackTrace) {
      log('Failed to fetch problems: $error');
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
    }
  }

  void sortProblems(String option) {
    if (option == 'name') {
      foldersProvider.sortProblemsByName();
    } else if (option == 'newest') {
      foldersProvider.sortProblemsByNewest();
    } else if (option == 'oldest') {
      foldersProvider.sortProblemsByOldest();
    }
  }

  void navigateToProblemDetail(BuildContext context, int problemId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        //builder: (context) => ProblemDetailScreen(problemId: problemId),
        builder: (context) => ProblemDetailScreenV2(problemId: problemId),
      ),
    ).then((value) {
      if (value == true) {
        fetchProblems();
      }
    });
  }
}
