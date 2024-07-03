import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvp_front/ProblemRegister/ProblemRegisterModel.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProblemService {
  Future<void> submitProblem(
      ProblemRegisterModel problemData, BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    if (userId == null) {
      throw Exception("User ID is not available");
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/problem'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'userId': userId.toString()
        },
        body: jsonEncode(problemData.toJson()),
      );

      if (response.statusCode == 200) {
        print('Problem successfully submitted');

        // 폴더 갱신
        await fetchAndSaveProblems();
        showSuccessDialog(context);
      } else {
        print('Failed to submit problem: ${response.body}');
      }
    } catch (e) {
      print('Error submitting problem: $e');
    }
  }

  List<dynamic> _problems = []; // 문제 목록 저장할 리스트

  // 서버에서 문제 목록을 가져와 저장하고 SharedPreferences에 저장하는 함수
  Future<void> fetchAndSaveProblems() async {
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

    log('Fetching problems: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      // 성공적으로 문제 목록을 받아온 경우
      _problems = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      await prefs.setString('problems', response.body); // 로컬에 문제 목록 저장
      log('Problems fetched and saved locally');
    } else {
      log('Failed to load problems from server');
      throw Exception('Failed to load problems from server');
    }
  }

  void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text("성공!"),
          content: Text("문제가 성공적으로 저장되었습니다."),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text("확인"),
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
            ),
          ],
        );
      },
    );
  }

  // 문제 목록에서 특정 문제 상세 정보 가져오기
  Map<String, dynamic>? getProblemDetails(int problemId) {
    try {
      var problemDetails =
          _problems.firstWhere((problem) => problem['problemId'] == problemId);
      return problemDetails;
    } catch (e) {
      log('Problem with ID $problemId not found: $e');
      return null;
    }
  }

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
}
