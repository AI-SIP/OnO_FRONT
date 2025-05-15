import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Service/Api/Problem/ProblemService.dart';

import '../Model/Problem/ProblemRegisterModel.dart';
import '../Model/Problem/ProblemRepeatRegisterModel.dart';
import '../Module/Util/ReviewHandler.dart';
import '../Service/Api/FileUpload/FileUploadService.dart';

class ProblemsProvider with ChangeNotifier {
  List<ProblemModel> _problems = [];
  List<ProblemModel> get problems => _problems;

  final problemService = ProblemService();
  final fileUploadService = FileUploadService();

  Future<ProblemModel> getProblem(int problemId) async {
    if (_problems.isEmpty) {
      _problems = await problemService.getAllProblems();
    }

    int low = 0, high = _problems.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final midId = _problems[mid].problemId!;
      if (midId == problemId) {
        log('find problemId: $problemId');
        return _problems[mid];
      } else if (midId < problemId) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    log('can\'t find problemId: $problemId');
    throw Exception('Problem with id $problemId not found.');
  }

  Future<void> fetchProblem(int problemId) async {
    final fetchedProblem = await problemService.getProblem(problemId);

    int low = 0, high = _problems.length - 1;
    int? foundIndex;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final midId = _problems[mid].problemId!;
      if (midId == problemId) {
        foundIndex = mid;
        break;
      } else if (midId < problemId) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    if (foundIndex != null) {
      _problems[foundIndex] = fetchedProblem;
    } else {
      _problems.add(fetchedProblem);
    }

    notifyListeners();
  }

  Future<void> fetchAllProblems() async {
    _problems = await problemService.getAllProblems();

    for (var problem in _problems) {
      log('-----------------------------------------');
      log('problem ID: ${problem.problemId}');
      log('problem Name: ${problem.reference}');
      log('problem Memo: : ${problem.memo}');
      log('problem folderId: ${problem.folderId}');
      log('Length of problem image data: ${problem.problemImageDataList?.length}');
      log('Length of answer image data: ${problem.answerImageDataList?.length}');
      log('Created At: ${problem.createdAt}');
      log('Updated At: ${problem.updateAt}');
      log('solved At: ${problem.solvedAt}');
      log('-----------------------------------------');
    }

    notifyListeners();
  }

  Future<void> submitProblem(
      ProblemRegisterModel problemData, BuildContext context) async {
    int registerProblemId = await problemService.registerProblem(problemData);
    ProblemModel registerProblem =
        await problemService.getProblem(registerProblemId);

    problems.add(registerProblem);

    int userProblemCount = await getUserProblemCount();
    final ReviewHandler reviewHandler = ReviewHandler();
    if (userProblemCount > 0 && userProblemCount % 10 == 0) {
      reviewHandler.requestReview(context);
    }

    notifyListeners();
  }

  Future<int> getUserProblemCount() async {
    return await problemService.getProblemCount();
  }

  Future<void> updateProblem(ProblemRegisterModel problemData) async {
    if (problemData.imageDataDtoList != null &&
        problemData.imageDataDtoList!.isNotEmpty) {
      await problemService.updateProblemImageData(problemData);
    }

    if (problemData.memo != null || problemData.reference != null) {
      await problemService.updateProblemInfo(problemData);
    }

    await fetchProblem(problemData.problemId!);
  }

  Future<void> addRepeatCount(
      ProblemRepeatRegisterModel problemRepeatRegisterModel) async {
    await problemService.repeatProblem(problemRepeatRegisterModel);
    await fetchProblem(problemRepeatRegisterModel.problemId);
  }

  Future<void> deleteProblems(List<int> deleteProblemIdList) async {
    await problemService.deleteProblems(deleteProblemIdList);
    await fetchAllProblems();
  }

  Future<String> uploadImage(XFile image) async {
    return await fileUploadService.uploadImageFile(image);
  }
}
