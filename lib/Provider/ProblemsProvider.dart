import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:ono/Model/Problem/ProblemAnalysisStatus.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Service/Api/Problem/ProblemService.dart';

import '../Model/Problem/ProblemRegisterModel.dart';
import '../Module/Util/ReviewHandler.dart';
import '../Service/Api/FileUpload/FileUploadService.dart';

class ProblemsProvider with ChangeNotifier {
  List<ProblemModel> _problems = [];
  List<ProblemModel> get problems => _problems;

  int _problemCount = 0;
  int get problemCount => _problemCount;

  final problemService = ProblemService();
  final fileUploadService = FileUploadService();

  ProblemModel getProblem(int problemId) {
    final index = _findProblemIndex(problemId);
    if (index != null) {
      return _problems[index];
    }

    log('can\'t find problemId: $problemId');
    throw Exception('Problem with id $problemId not found.');
  }

  int? _findProblemIndex(int problemId) {
    int low = 0, high = _problems.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final midId = _problems[mid].problemId;
      if (midId == problemId) {
        return mid;
      } else if (midId < problemId) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return null;
  }

  Future<void> fetchProblem(int problemId) async {
    final fetchedProblem = await problemService.getProblem(problemId);

    final foundIndex = _findProblemIndex(problemId);

    if (foundIndex != null) {
      _problems[foundIndex] = fetchedProblem;
    } else {
      _problems.add(fetchedProblem);
    }

    log('problem: $problemId fetch complete');
    notifyListeners();
  }

  Future<void> fetchAllProblems() async {
    _problems = await problemService.getAllProblems();
    _problemCount = await getUserProblemCount();

    log('fetch problems complete');
    notifyListeners();
  }

  Future<void> registerProblem(
      ProblemRegisterModel problemData, BuildContext context) async {
    int registerProblemId = await problemService.registerProblem(problemData);
    await fetchProblem(registerProblemId);

    int userProblemCount = await getUserProblemCount();
    _problemCount = userProblemCount;

    await requestReview(context);

    log('register problem id: $registerProblemId complete');
    notifyListeners();
  }

  Future<void> fetchProblemAnalysis(int problemId) async {
    try {
      final analysisResult = await problemService.getProblemAnalysis(problemId);

      // 분석이 완료되었으면 ProblemModel 업데이트
      if (analysisResult.status == ProblemAnalysisStatus.COMPLETED) {
        final foundIndex = _findProblemIndex(problemId);
        if (foundIndex != null) {
          _problems[foundIndex] =
              _problems[foundIndex].updateAnalysis(analysisResult);
          notifyListeners();
          log('ProblemModel 업데이트 완료 - UI가 자동으로 갱신됩니다');

          // 업데이트된 문제 정보 다시 로그 출력
          final updatedProblem = _problems[foundIndex];
        }
      }

      log('문제 분석 결과 조회 완료');
    } catch (e, stackTrace) {
      log('문제 분석 결과 조회 실패 - Problem ID: $problemId');
      log('에러: $e');
      log('스택트레이스: $stackTrace');
    }
  }

  Future<void> registerProblemImageData({
    required int problemId,
    required List<File> problemImages,
    required List<String> problemImageTypes,
  }) async {
    await problemService.registerProblemImageData(
      problemId: problemId,
      problemImages: problemImages,
      problemImageTypes: problemImageTypes,
    );

    await fetchProblem(problemId);

    log('register problem id: $problemId complete');
    notifyListeners();
  }

  Future<int> getUserProblemCount() async {
    return await problemService.getProblemCount();
  }

  Future<void> updateProblem(ProblemRegisterModel problemData) async {
    log('Update problem: ${problemData.problemId}');
    try {
      if (problemData.imageDataDtoList != null &&
          problemData.imageDataDtoList!.isNotEmpty) {
        await problemService.updateProblemImageData(problemData);
      }

      if (problemData.memo != null || problemData.reference != null) {
        await problemService.updateProblemInfo(problemData);
      }

      if (problemData.folderId != null) {
        await problemService.updateProblemPath(problemData);
      }

      await fetchProblem(problemData.problemId!);
    } catch (e, stackTrace) {
      log('오답노트 수정 실패 - Problem ID: ${problemData.problemId}');
      log('에러: $e');
      log('스택트레이스: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateProblemCount(int amount) async {
    _problemCount += amount;
    notifyListeners();
  }

  Future<void> deleteProblems(List<int> deleteProblemIdList) async {
    log('delete problems: $deleteProblemIdList');
    await problemService.deleteProblems(deleteProblemIdList);
    await fetchAllProblems();
  }

  Future<void> deleteProblemImageData(String imageUrl) async {
    await problemService.deleteProblemImageData(imageUrl);
  }

  Future<String> uploadImage(XFile image) async {
    return await fileUploadService.uploadImageFile(image);
  }

  Future<void> requestReview(BuildContext context) async {
    final ReviewHandler reviewHandler = ReviewHandler();
    if (_problemCount > 0 && _problemCount % 10 == 0) {
      reviewHandler.requestReview(context);
    }
  }
}
