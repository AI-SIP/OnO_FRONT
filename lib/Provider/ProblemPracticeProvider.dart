import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ono/Model/ProblemPracticeModel.dart';
import 'package:ono/Model/ProblemPracticeRegisterModel.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../Config/AppConfig.dart';
import '../GlobalModule/Util/HttpService.dart';
import '../Model/ProblemModel.dart';
import 'TokenProvider.dart';

class ProblemPracticeProvider with ChangeNotifier{

  int currentPracticeId = -1;
  List<ProblemPracticeModel> practices = [];
  List<ProblemModel> currentProblems = [];
  final TokenProvider tokenProvider = TokenProvider();
  final HttpService httpService = HttpService();

  Future<void> fetchAllPracticeContents() async {
    try {
      final response = await httpService.sendRequest(
        method: 'GET',
        url: '${AppConfig.baseUrl}/api/problem/practice/all',
      );

      if (response.statusCode == 200) {
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
    } catch (error, stackTrace) {
      log('Error fetching root folder contents: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  Future<void> moveToPractice(int practiceId) async {
    try {
      final targetPractice = practices.firstWhere(
          (practice) => practice.practiceId == practiceId,
        orElse: () => throw Exception('Practice with ID $practiceId not found'),
      );

      currentProblems = targetPractice.problems;

      final response = await httpService.sendRequest(
        method: 'GET',
        url: '${AppConfig.baseUrl}/api/problem/practice/$practiceId',
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));

        currentPracticeId = practiceId;

        currentProblems = (jsonResponse as List)
            .map((e) => ProblemModel.fromJson(e))
            .toList();

        //problemIds = currentProblems.map((problem) => problem.problemId).toList();

        log('Fetched ${currentProblems.length} problems for practice ID: $practiceId');
        notifyListeners();
      } else {
        throw Exception('Failed to load problems for practice ID: $practiceId');
      }
    } catch (error, stackTrace) {
      log('Error fetching problems for practice ID $practiceId: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  Future<void> fetchPracticeContents(int? practiceId) async {
    try {
      final response = await httpService.sendRequest(
        method: 'GET',
        url: '${AppConfig.baseUrl}/api/problem/practice/$practiceId',
      );

      if (response.statusCode == 200) {
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
    } catch (error, stackTrace) {
      log('Error fetching problems for practice ID $practiceId: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  Future<bool> registerPractice(ProblemPracticeRegisterModel problemPracticeRegisterModel) async {
    try {
      log('practice problem list: ${problemPracticeRegisterModel.registerProblemIds.toString()}');
      log('practice problem title: ${problemPracticeRegisterModel.practiceTitle}');

      final response = await httpService.sendRequest(
        method: 'POST',
        url: '${AppConfig.baseUrl}/api/problem/practice',
        body: {
          'practiceTitle': problemPracticeRegisterModel.practiceTitle.toString(),
          'registerProblemIds': problemPracticeRegisterModel.registerProblemIds.map((id) => id.toString()).toList(),
        },
      );

      log('response: ${response.body}');

      if(response.statusCode == 200){
        final practiceData = json.decode(utf8.decode(response.bodyBytes));
        final updatedPractice = ProblemPracticeModel.fromJson(practiceData);

        await fetchPracticeContents(updatedPractice.practiceId);

        return true;
      } else{
        return false;
      }
    } catch (error, stackTrace) {
      log('Error submitting selected problems: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);

      return false;
    }
  }

  Future<bool> updatePractice(
    ProblemPracticeRegisterModel problemPracticeRegisterModel
  ) async {
    try {
      final practiceId = problemPracticeRegisterModel.practiceId;

      // 서버에 PATCH 요청 보내기
      final response = await httpService.sendRequest(
        method: 'PATCH',
        url: '${AppConfig.baseUrl}/api/problem/practice',
        body: problemPracticeRegisterModel.toJson(),
      );

      if (response.statusCode == 200) {
        await fetchPracticeContents(practiceId);
        log('Practice problems updated successfully for practice ID: $practiceId');
        return true;
      } else {
        log('Failed to update practice problems for practice ID: $practiceId');
        return false;
      }
    } catch (error, stackTrace) {
      log('Error updating practice : $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> deletePractices(List<int> deletePracticeIds) async {
    try {
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

      if(response.statusCode == 200){

        await fetchAllPracticeContents();

        return true;
      } else{
        return false;
      }
    } catch (error, stackTrace) {
      log('Error submitting selected problems: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);

      return false;
    }
  }

  Future<void> resetProblems() async {
    currentProblems = [];
    notifyListeners();
  }

  Future<ProblemModel?> getProblemDetails(int? problemId) async {
    try {
      var problemDetails = currentProblems.firstWhere((problem) => problem.problemId == problemId);

      if (problemDetails != null) {
        return problemDetails;
      } else {
        throw Exception('Problem with ID $problemId not found');
      }
    } catch (error, stackTrace) {
      log('Error fetching problem details for ID $problemId: $error');
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<bool> addPracticeCount(int practiceId) async {
    try {
      final response = await httpService.sendRequest(
        method: 'PATCH',
        url: '${AppConfig.baseUrl}/api/problem/practice/complete/$practiceId',
      );

      if (response.statusCode == 200) {
        log('Practice count updated for practice ID: $practiceId');
        return true;
      } else {
        log('Failed to update practice count for practice ID: $practiceId');
        return false;
      }
    } catch (error, stackTrace) {
      log('Error completing practice for practice ID $practiceId: $error');
      await Sentry.captureException(error, stackTrace: stackTrace);
      return false;
    }
  }
}