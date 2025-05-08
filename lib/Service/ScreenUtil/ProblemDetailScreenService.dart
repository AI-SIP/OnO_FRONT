import 'package:flutter/material.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Dialog/SnackBarDialog.dart';
import '../../GlobalModule/Text/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../Model/Problem/ProblemModel.dart';

class ProblemDetailScreenService {
  Future<ProblemModel?> fetchProblemDetailsFromFolder(
      BuildContext context, int? problemId) async {
    return Provider.of<FoldersProvider>(context, listen: false)
        .getProblemDetails(problemId);
  }

  Future<ProblemModel?> fetchProblemDetailsFromPractice(
      BuildContext context, int? problemId) async {
    return Provider.of<ProblemPracticeProvider>(context, listen: false)
        .getProblemDetails(problemId);
  }
}
