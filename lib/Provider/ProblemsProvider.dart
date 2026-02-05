import 'dart:collection';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:ono/Model/Common/PaginatedResponse.dart';
import 'package:ono/Model/Problem/ProblemAnalysisStatus.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Service/Api/Problem/ProblemService.dart';

import '../Model/Problem/ProblemRegisterModel.dart';
import '../Module/Util/ReviewHandler.dart';
import '../Service/Api/FileUpload/FileUploadService.dart';

class ProblemsProvider with ChangeNotifier {
  // SplayTreeMap: O(log n) 삽입, O(log n) 조회, 자동 정렬
  final SplayTreeMap<int, ProblemModel> _problemsMap = SplayTreeMap();

  // 호환성을 위한 getter (정렬된 리스트 반환)
  List<ProblemModel> get problems => _problemsMap.values.toList();

  int _problemCount = 0;
  int get problemCount => _problemCount;

  final problemService = ProblemService();
  final fileUploadService = FileUploadService();

  // O(log n) 조회
  Future<ProblemModel> getProblem(int problemId) async {
    if (_problemsMap.containsKey(problemId)) {
      return _problemsMap[problemId]!;
    } else {
      log('can\'t find problemId: $problemId');

      await fetchProblem(problemId);
      return _problemsMap[problemId]!;
    }
  }

  // O(log n) 삽입/업데이트 (SplayTreeMap이 자동으로 정렬 유지)
  void _upsertProblem(ProblemModel problem) {
    _problemsMap[problem.problemId] = problem;
  }

  Future<void> fetchProblem(int problemId) async {
    final fetchedProblem = await problemService.getProblem(problemId);
    _upsertProblem(fetchedProblem);
    log('problem: $problemId fetch complete');
    notifyListeners();
  }

  Future<void> fetchAllProblems() async {
    final problemsList = await problemService.getAllProblems();
    _problemsMap.clear();
    for (var problem in problemsList) {
      _problemsMap[problem.problemId] = problem;
    }
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
        if (_problemsMap.containsKey(problemId)) {
          _problemsMap[problemId] =
              _problemsMap[problemId]!.updateAnalysis(analysisResult);
          notifyListeners();
          log('ProblemModel 업데이트 완료 - UI가 자동으로 갱신됩니다');
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

  void clear() {
    _problemsMap.clear();
    notifyListeners();
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

  // 문제 개수만 조회 (로그인 시 사용)
  Future<void> fetchProblemCount() async {
    _problemCount = await getUserProblemCount();
    notifyListeners();
  }

  // V2 API - 폴더 내 문제 무한 스크롤 조회
  Future<PaginatedResponse<ProblemModel>> loadMoreFolderProblemsV2({
    required int folderId,
    int? cursor,
    int size = 20,
  }) async {
    try {
      final response = await problemService.getFolderProblemsV2(
        folderId: folderId,
        cursor: cursor,
        size: size,
      );

      // O(log n) 삽입으로 로컬 캐시에 추가 (중복 방지 및 자동 정렬)
      for (var problem in response.content) {
        _upsertProblem(problem);
      }

      log('Loaded ${response.content.length} problems from folder $folderId');
      notifyListeners();

      return response;
    } catch (e, stackTrace) {
      log('Error loading folder problems V2: $e');
      log(stackTrace.toString());
      rethrow;
    }
  }
}
