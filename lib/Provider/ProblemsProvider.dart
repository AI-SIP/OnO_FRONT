import 'dart:convert';
import 'dart:developer';
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

  Future<void> fetchProblems({String sortOption = 'newest'}) async {
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

      switch (sortOption) {
        case 'name':
          _problems.sortByName();
          break;
        case 'oldest':
          _problems.sortByOldest();
          break;
        case 'newest':
        default:
          _problems.sortByNewest();
          break;
      }

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
    final colors = problemData.colors;

    if (problemImage != null) {
      request.files.add(
          await http.MultipartFile.fromPath('problemImage', problemImage.path));
      if(colors != null){
        request.fields['colors'] = jsonEncode(colors);
      }
    }
    if (solveImage != null) {
      request.files.add(
          await http.MultipartFile.fromPath('solveImage', solveImage.path));
    }
    if (answerImage != null) {
      request.files.add(
          await http.MultipartFile.fromPath('answerImage', answerImage.path));
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        log('Problem successfully submitted');
        await fetchProblems();
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

  Future<void> updateProblem(ProblemRegisterModel problemData) async {
    final accessToken = await tokenProvider.getAccessToken();
    if (accessToken == null) {
      throw Exception("JWT token is not available");
    }

    var uri = Uri.parse('${AppConfig.baseUrl}/api/problem');
    var request = http.MultipartRequest('PATCH', uri)
      ..headers.addAll({'Authorization': 'Bearer $accessToken'});

    request.fields['problemId'] = (problemData.problemId ?? -1).toString();

    if (problemData.solvedAt != null) {
      request.fields['solvedAt'] = problemData.solvedAt!.toIso8601String();
    }

    if (problemData.reference != null && problemData.reference!.isNotEmpty) {
      request.fields['reference'] = problemData.reference!;
    }
    if (problemData.memo != null && problemData.memo!.isNotEmpty) {
      request.fields['memo'] = problemData.memo!;
    }

    final problemImage = problemData.problemImage;
    final colors = problemData.colors;
    if (problemImage != null) {
      request.files.add(
          await http.MultipartFile.fromPath('problemImage', problemImage.path));

      if(colors != null){
        request.fields['colors'] = jsonEncode(colors);
      }
    }

    final solveImage = problemData.solveImage;
    if (solveImage != null) {
      request.files.add(
          await http.MultipartFile.fromPath('solveImage', solveImage.path));
    }

    final answerImage = problemData.answerImage;
    if (answerImage != null) {
      request.files.add(
          await http.MultipartFile.fromPath('answerImage', answerImage.path));
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        log('Problem successfully submitted');
        await fetchProblems();
      } else {
        log('Failed to submit problem: ${response.reasonPhrase}');
      }
    } catch (e) {
      log('Error submitting problem: $e');
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

  void sortProblemsByName(String folder) {
    final groupedProblems = groupProblemsByFolder();
    if (groupedProblems.containsKey(folder)) {
      groupedProblems[folder]!.sortByName();
      _updateProblemsList(groupedProblems);
      notifyListeners();
    }
  }

  void sortProblemsByNewest(String folder) {
    final groupedProblems = groupProblemsByFolder();
    if (groupedProblems.containsKey(folder)) {
      groupedProblems[folder]!.sortByNewest();
      _updateProblemsList(groupedProblems);
      notifyListeners();
    }
  }

  void sortProblemsByOldest(String folder) {
    final groupedProblems = groupProblemsByFolder();
    if (groupedProblems.containsKey(folder)) {
      groupedProblems[folder]!.sortByOldest();
      _updateProblemsList(groupedProblems);
      notifyListeners();
    }
  }

  void sortAllProblemsByName() {
    _problems.sortByName();
    notifyListeners();
  }

  void _updateProblemsList(Map<String, List<ProblemModel>> groupedProblems) {
    _problems = groupedProblems.entries.expand((entry) => entry.value).toList();
  }

  List<int> getProblemIds() {
    return _problems.map((problem) => problem.problemId as int).toList();
  }
}
