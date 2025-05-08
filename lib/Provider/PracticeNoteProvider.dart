import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteRegisterModel.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../Config/AppConfig.dart';
import '../Service/Network/HttpService.dart';
import '../Model/Problem/ProblemModel.dart';
import 'TokenProvider.dart';

class ProblemPracticeProvider with ChangeNotifier{

  int currentPracticeId = -1;
  List<ProblemPracticeModel> practices = [];
  List<ProblemModel> currentProblems = [];
  final TokenProvider tokenProvider = TokenProvider();
  final HttpService httpService = HttpService();

  Future<void> fetchAllPracticeContents() async {
    final response = await httpService.sendRequest(
      method: 'GET',
      url: '${AppConfig.baseUrl}/api/practices/thumbnail',
    );

    if (response != null) {
      final List<dynamic> jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      practices = jsonResponse.map((practiceData) => ProblemPracticeModel.fromJson(practiceData)).toList();
      log('fetch all practice contents');

      for (var practice in practices) {
        log('-----------------------------------------');
        log('Practice ID: ${practice.practiceId}');
        log('Practice Name: ${practice.practiceTitle}');
        log('Practice length: ${practice.problems.length}');
        log('Created At: ${practice.createdAt}');
        log('last solved At: ${practice.lastSolvedAt}');
        log('-----------------------------------------');
      }

      notifyListeners();
      log('Practice contents fetched : ${practices.length} problem practices');
    } else {
      throw Exception('Failed to load RootFolderContents');
    }
  }

  Future<void> moveToPractice(int practiceId) async {
    final targetPractice = practices.firstWhere(
          (practice) => practice.practiceId == practiceId,
      orElse: () => throw Exception('Practice with ID $practiceId not found'),
    );

    currentProblems = targetPractice.problems;
    currentPracticeId = targetPractice.practiceId;
  }

  Future<void> fetchPracticeContent(int? practiceId) async {
    final response = await httpService.sendRequest(
      method: 'GET',
      url: '${AppConfig.baseUrl}/api/problem/practice/$practiceId',
    );

    if (response != null) {
      final practiceData = json.decode(utf8.decode(response.bodyBytes));
      final updatedPractice = ProblemPracticeModel.fromJson(practiceData);

      // 기존 데이터를 업데이트
      final index = practices.indexWhere((practice) => practice.practiceId == practiceId);
      if (index != -1) {
        practices[index] = updatedPractice;
      } else {
        practices.add(updatedPractice);
      }

      notifyListeners();
    } else {
      throw Exception('Failed to load problems for practice ID: $practiceId');
    }
  }

  Future<bool> registerPractice(ProblemPracticeRegisterModel problemPracticeRegisterModel) async {
    final response = await httpService.sendRequest(
      method: 'POST',
      url: '${AppConfig.baseUrl}/api/problem/practice',
      body: {
        'practiceTitle': problemPracticeRegisterModel.practiceTitle.toString(),
        'registerProblemIds': problemPracticeRegisterModel.registerProblemIds.map((id) => id.toString()).toList(),
      },
    );

    log('response: ${response.body}');

    if(response == null){
      return false;
    }

    final practiceData = json.decode(utf8.decode(response.bodyBytes));
    final updatedPractice = ProblemPracticeModel.fromJson(practiceData);

    await fetchPracticeContent(updatedPractice.practiceId);

    return true;
  }

  Future<bool> updatePractice(
    ProblemPracticeRegisterModel problemPracticeRegisterModel
  ) async {
    final practiceId = problemPracticeRegisterModel.practiceId;

    // 서버에 PATCH 요청 보내기
    final response = await httpService.sendRequest(
      method: 'PATCH',
      url: '${AppConfig.baseUrl}/api/problem/practice',
      body: problemPracticeRegisterModel.toJson(),
    );

    if (response != null) {
      await fetchPracticeContent(practiceId);
      log('Practice problems updated successfully for practice ID: $practiceId');
      return true;
    } else {
      log('Failed to update practice problems for practice ID: $practiceId');
      return false;
    }
  }

  Future<bool> deletePractices(List<int> deletePracticeIds) async {
    log('practice problem list: ${deletePracticeIds.toString()}');

    final queryParams = {
      'deletePracticeIds': deletePracticeIds.join(','), // 쉼표로 구분된 문자열로 변환
    };

    final response = await httpService.sendRequest(
      method: 'DELETE',
      url: '${AppConfig.baseUrl}/api/problem/practice',
      queryParams: queryParams,
    );

    log('response: ${response.body}');

    if(response != null){

      await fetchAllPracticeContents();

      return true;
    } else{
      return false;
    }
  }

  Future<void> resetProblems() async {
    currentProblems = [];
    notifyListeners();
  }

  Future<ProblemModel?> getProblemDetails(int? problemId) async {
    return currentProblems.firstWhere((problem) => problem.problemId == problemId);
  }

  Future<bool> addPracticeCount(int practiceId) async {
    final response = await httpService.sendRequest(
      method: 'PATCH',
      url: '${AppConfig.baseUrl}/api/problem/practice/complete/$practiceId',
    );

    if (response != null) {
      log('Practice count updated for practice ID: $practiceId');
      return true;
    } else {
      log('Failed to update practice count for practice ID: $practiceId');
      return false;
    }
  }
}