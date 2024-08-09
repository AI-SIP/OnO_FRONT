import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Util/ProblemSorting.dart';

import '../Config/AppConfig.dart';
import '../Model/ProblemRegisterModel.dart';
import '../Model/ProblemModel.dart';
import 'TokenProvider.dart';

class ProblemsProvider with ChangeNotifier {
  List<ProblemModel> _problems = [];
  List<ProblemModel> get problems => List.unmodifiable(_problems);
  final TokenProvider tokenProvider = TokenProvider();

  Future<void> fetchProblems() async {
    final accessToken = await tokenProvider.getAccessToken();
    if (accessToken == null) {
      log('access token is not available');
      return;
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/problems');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> fetchedProblems =
          json.decode(utf8.decode(response.bodyBytes));
      _problems = fetchedProblems.map((e) => ProblemModel.fromJson(e)).toList();
      notifyListeners();
      log('Problems fetched and saved locally: ${_problems.length}');
    } else {
      log('Failed to load problems from server');
    }
  }

  Future<void> submitProblem(
      ProblemRegisterModel problemData, BuildContext context) async {
    final accessToken = await tokenProvider.getAccessToken();
    if (accessToken == null) {
      throw Exception("JWT token is not available");
    }

    var uri = Uri.parse('${AppConfig.baseUrl}/api/problem');
    var request = http.MultipartRequest('POST', uri)
      ..headers.addAll({'Authorization': 'Bearer $accessToken'});
    request.fields['solvedAt'] = problemData.solvedAt?.toIso8601String() ?? "";
    request.fields['reference'] = problemData.reference ?? "";
    request.fields['memo'] = problemData.memo ?? "";

    final problemImage = problemData.problemImage;
    final solveImage = problemData.solveImage;
    final answerImage = problemData.answerImage;

    if (problemImage != null) {
      log('problemImage : $problemImage');
      request.files.add(
          await http.MultipartFile.fromPath('problemImage', problemImage.path));
    }
    if (solveImage != null) {
      log('solveImage : $solveImage');
      request.files.add(
          await http.MultipartFile.fromPath('solveImage', solveImage.path));
    }
    if (answerImage != null) {
      log('answerImage : $answerImage');
      request.files.add(
          await http.MultipartFile.fromPath('answerImage', answerImage.path));
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        log('Problem successfully submitted');
        await fetchProblems();
        //notifyListeners();
      } else {
        log('Failed to submit problem: ${response.reasonPhrase}');
      }
    } catch (e) {
      log('Error submitting problem: $e');
    }
  }

  Future<ProblemModel?> getProblemDetails(int? problemId) async {
    try {
      var problemDetails =
          _problems.firstWhere((problem) => problem.problemId == problemId);

      if (problemDetails != null) {
        return ProblemModel.fromJson(problemDetails.toJson());
      } else {
        log('Problem with ID $problemId not found');
        return null;
      }
    } catch (e) {
      log('Error fetching problem details for ID $problemId: $e');
      return null;
    }
  }

  Future<bool> deleteProblem(int problemId) async {
    final accessToken = await tokenProvider.getAccessToken();
    if (accessToken == null) {
      log('accessToken is not available');
      throw Exception('accessToken is not available');
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/problem');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
        'problemId': problemId.toString(),
      },
    );

    log('Deleting problem: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      await fetchProblems();
      return true;
    } else {
      log('Failed to delete problem from server');
      return false;
    }
  }

  // 폴더로 문제를 그룹화
  Map<String, List<ProblemModel>> groupProblemsByFolder() {
    Map<String, List<ProblemModel>> groupedProblems = {};
    for (var problem in _problems) {
      String folder = problem.folder ?? 'root'; // 기본 폴더로 그룹화
      if (groupedProblems.containsKey(folder)) {
        groupedProblems[folder]!.add(problem);
      } else {
        groupedProblems[folder] = [problem];
      }
    }
    return groupedProblems;
  }

  // 특정 폴더 내에서 이름순 정렬
  void sortProblemsByName(String folder) {
    final groupedProblems = groupProblemsByFolder();
    if (groupedProblems.containsKey(folder)) {
      groupedProblems[folder]!.sortByName();
      // Update the main list to reflect the sorted order
      _updateProblemsList(groupedProblems);
      notifyListeners();
    }
  }

  // 특정 폴더 내에서 최신순 정렬
  void sortProblemsByNewest(String folder) {
    final groupedProblems = groupProblemsByFolder();
    if (groupedProblems.containsKey(folder)) {
      groupedProblems[folder]!.sortByNewest();
      // Update the main list to reflect the sorted order
      _updateProblemsList(groupedProblems);
      notifyListeners();
    }
  }

  // 특정 폴더 내에서 오래된순 정렬
  void sortProblemsByOldest(String folder) {
    final groupedProblems = groupProblemsByFolder();
    if (groupedProblems.containsKey(folder)) {
      groupedProblems[folder]!.sortByOldest();
      // Update the main list to reflect the sorted order
      _updateProblemsList(groupedProblems);
      notifyListeners();
    }
  }

  // 전체 문제를 이름순으로 정렬
  void sortAllProblemsByName() {
    _problems.sortByName();
    notifyListeners();
  }

  // 그룹화된 문제 리스트로 _problems 업데이트
  void _updateProblemsList(Map<String, List<ProblemModel>> groupedProblems) {
    _problems = groupedProblems.entries.expand((entry) => entry.value).toList();
  }

  // Checks if there is a next problem
  bool hasNextProblem(int currentProblemId) {
    var currentIndex =
        _problems.indexWhere((p) => p.problemId == currentProblemId);
    return currentIndex >= 0 && currentIndex < _problems.length - 1;
  }

  // Checks if there is a previous problem
  bool hasPreviousProblem(int currentProblemId) {
    var currentIndex =
        _problems.indexWhere((p) => p.problemId == currentProblemId);
    return currentIndex > 0 && currentIndex < _problems.length;
  }

  // Get the ID of the next problem
  int? getNextProblemId(int currentProblemId) {
    var currentIndex =
        _problems.indexWhere((p) => p.problemId == currentProblemId);
    if (currentIndex >= 0 && currentIndex < _problems.length - 1) {
      return _problems[currentIndex + 1].problemId;
    } else if (currentIndex == _problems.length - 1) {
      return _problems[0].problemId;
    }
    throw Exception('No next problem available.');
  }

  List<int> getProblemIds() {
    return _problems.map((problem) => problem.problemId as int).toList();
  }

  // Get the ID of the previous problem
  int? getPreviousProblemId(int currentProblemId) {
    var currentIndex =
        _problems.indexWhere((p) => p.problemId == currentProblemId);
    if (currentIndex > 0) {
      return _problems[currentIndex - 1].problemId;
    } else if (currentIndex == 0) {
      return _problems[_problems.length - 1].problemId;
    }
    throw Exception('No previous problem available.');
  }
}
