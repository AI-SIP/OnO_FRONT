import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../Config/AppConfig.dart';
import '../Model/ProblemRegisterModel.dart';
import '../Model/ProblemModel.dart';

class ProblemsProvider with ChangeNotifier {
  List<ProblemModel> _problems = [];
  List<ProblemModel> get problems => List.unmodifiable(_problems);

  final storage = const FlutterSecureStorage();

  Future<String?> getJwtToken() async {
    return await storage.read(key: 'jwtToken');
  }

  Future<void> fetchProblems() async {
    final token = await getJwtToken();
    if (token == null) {
      log('JWT token is not available');
      return;
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/problems');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
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
    final token = await getJwtToken();
    if (token == null) {
      throw Exception("JWT token is not available");
    }

    var uri = Uri.parse('${AppConfig.baseUrl}/api/problem');
    var request = http.MultipartRequest('POST', uri)
      ..headers.addAll({'Authorization': 'Bearer $token'});
    request.fields['solvedAt'] = problemData.solvedAt?.toIso8601String() ?? "";
    request.fields['reference'] = problemData.reference ?? "";
    request.fields['memo'] = problemData.memo ?? "";

    final problemImage = problemData.problemImage;
    final solveImage = problemData.solveImage;
    final answerImage = problemData.answerImage;

    if (problemImage != null) {
      print('problemImage : ${problemImage}');
      request.files.add(
          await http.MultipartFile.fromPath('problemImage', problemImage.path));
    }
    if (solveImage != null) {
      print('solveImage : ${solveImage}');
      request.files.add(
          await http.MultipartFile.fromPath('solveImage', solveImage.path));
    }
    if (answerImage != null) {
      print('answerImage : ${answerImage}');
      request.files.add(
          await http.MultipartFile.fromPath('answerImage', answerImage.path));
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        print('Problem successfully submitted');
        await fetchProblems();
        //notifyListeners();
      } else {
        print('Failed to submit problem: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error submitting problem: $e');
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
    final token = await getJwtToken();
    if (token == null) {
      log('JWT token is not available');
      throw Exception('JWT token is not available');
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/problem');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
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
