import 'package:flutter/material.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModelWithTemplate.dart';

class ProblemDetailScreenService {
  Future<ProblemModelWithTemplate?> fetchProblemDetailsFromFolder(
      BuildContext context, int? problemId) async {
    return Provider.of<FoldersProvider>(context, listen: false)
        .getProblemDetails(problemId);
  }

  Future<ProblemModelWithTemplate?> fetchProblemDetailsFromPractice(
      BuildContext context, int? problemId) async {
    return Provider.of<ProblemPracticeProvider>(context, listen: false)
        .getProblemDetails(problemId);
  }
}
