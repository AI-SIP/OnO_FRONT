import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mvp_front/ProblemDetail/ProblemDetailModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ProblemRegister/ProblemRegisterModel.dart';
import 'ProblemModel.dart';

class ProblemsProvider with ChangeNotifier {
  List<ProblemModel> _problems = [];

  List<ProblemModel> get problems => List.unmodifiable(_problems);

  Future<void> fetchProblems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');
    if (userId == null) {
      log('User ID is not available');
      throw Exception('User ID is not available');
    }

    final url = Uri.parse('http://localhost:8080/api/problems');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      'userId': userId.toString(),
    });

    if (response.statusCode == 200) {
      List<dynamic> fetchedProblems =
          json.decode(utf8.decode(response.bodyBytes));
      _problems = fetchedProblems.map((e) => ProblemModel.fromJson(e)).toList();
      notifyListeners();
      log('Problems fetched and saved locally: ${_problems.length}');
    } else {
      log('Failed to load problems from server');
      throw Exception('Failed to load problems from server');
    }
  }

  Future<void> submitProblem(
      ProblemRegisterModel problemData, BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    if (userId == null) {
      throw Exception("User ID is not available");
    }

    var uri = Uri.parse('http://localhost:8080/api/problem');
    var request = http.MultipartRequest('POST', uri)
      ..headers.addAll({'userId': userId.toString()});
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

  Future<ProblemDetailModel?> getProblemDetails(int? problemId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      var problemDetails =
          _problems.firstWhere((problem) => problem.problemId == problemId);

      if (problemDetails != null) {
        return ProblemDetailModel.fromJson(problemDetails.toJson());
      } else {
        log('Problem with ID $problemId not found');
        return null;
      }
    } catch (e) {
      log('Error fetching problem details for ID $problemId: $e');
      return null;
    }
  }
}
