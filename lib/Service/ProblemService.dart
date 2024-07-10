import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvp_front/Model/ProblemRegisterModel.dart';
import 'package:mvp_front/Provider/ProblemsProvider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProblemService extends ChangeNotifier {

  ProblemsProvider _problemsProvider;

  ProblemService(this._problemsProvider);

  Future<void> fetchAndSaveProblems() async {
    /*
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

    //log('Fetching problems: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      // 성공적으로 문제 목록을 받아온 경우
      //_problems = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;

      var result = json.decode(utf8.decode(response.bodyBytes));
      _problems.clear();
      _problems.addAll(result);
      notifyListeners();

      print('problems size: ${_problems.length}');
      //await prefs.setString('problems', response.body); // 로컬에 문제 목록 저장
      log('Problems fetched and saved locally');
    } else {
      log('Failed to load problems from server');
      throw Exception('Failed to load problems from server');
    }

     */

    await _problemsProvider.fetchProblems();
  }

  // 문제 목록에서 특정 문제 상세 정보 가져오기
  /*
  Future<ProblemDetailModel?> getProblemDetails(int problemId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      var problemDetails = _problems.firstWhere(
          (problem) => problem['problemId'] == problemId,
          orElse: () => null);

      if (problemDetails != null) {
        return ProblemDetailModel.fromJson(problemDetails);
      } else {
        log('Problem with ID $problemId not found');
        return null;
      }
    } catch (e) {
      log('Error fetching problem details for ID $problemId: $e');
      return null;
    }
  }

   */

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
        await fetchAndSaveProblems();
        //notifyListeners();
      } else {
        print('Failed to submit problem: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error submitting problem: $e');
    }
  }

  Future<void> updateProblem(int problemId, ProblemRegisterModel problemData,
      BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    if (userId == null) {
      throw Exception("User ID is not available");
    }

    try {
      final response = await http.put(
        Uri.parse('http://localhost:8080/api/problem/$problemId'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'userId': userId.toString()
        },
        body: jsonEncode(problemData.toJson()),
      );

      if (response.statusCode == 200) {
        print('Problem successfully updated');

        // 폴더 갱신
        await fetchAndSaveProblems();
      } else {
        print('Failed to update problem: ${response.body}');
      }
    } catch (e) {
      print('Error updating problem: $e');
    }
  }

  Future<bool> deleteProblem(int problemId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    if (userId == null) {
      log('User ID is not available');
      throw Exception('User ID is not available');
    }

    final url = Uri.parse('http://localhost:8080/api/problem');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'userId': userId.toString(),
        'problemId': problemId.toString(),
      },
    );

    log('Deleting problem: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      // 성공적으로 문제를 삭제한 경우
      //_problems.removeWhere((problem) => problem['problemId'] == problemId);
      await fetchAndSaveProblems();
      return true;
    } else {
      log('Failed to delete problem from server');
      return false;
    }
  }

  /*
  // Checks if there is a next problem
  bool hasNextProblem(int currentProblemId) {
    var currentIndex =
        _problems.indexWhere((p) => p['problemId'] == currentProblemId);
    return currentIndex >= 0 && currentIndex < _problems.length - 1;
  }

  // Checks if there is a previous problem
  bool hasPreviousProblem(int currentProblemId) {
    var currentIndex =
        _problems.indexWhere((p) => p['problemId'] == currentProblemId);
    return currentIndex > 0 && currentIndex < _problems.length;
  }

  // Get the ID of the next problem
  int getNextProblemId(int currentProblemId) {
    var currentIndex =
        _problems.indexWhere((p) => p['problemId'] == currentProblemId);
    if (currentIndex >= 0 && currentIndex < _problems.length - 1) {
      return _problems[currentIndex + 1]['problemId'];
    } else if (currentIndex == _problems.length - 1) {
      return _problems[0]['problemId'];
    }
    throw Exception('No next problem available.');
  }

  List<int> getProblemIds() {
    return _problems.map((problem) => problem['problemId'] as int).toList();
  }

  // Get the ID of the previous problem
  int getPreviousProblemId(int currentProblemId) {
    var currentIndex =
        _problems.indexWhere((p) => p['problemId'] == currentProblemId);
    if (currentIndex > 0) {
      return _problems[currentIndex - 1]['problemId'];
    } else if (currentIndex == 0) {
      return _problems[_problems.length - 1]['problemId'];
    }
    throw Exception('No previous problem available.');
  }

   */
}
