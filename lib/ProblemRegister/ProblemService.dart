import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvp_front/ProblemRegister/ProblemRegisterModel.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../Directory/DirectoryService.dart';

class ProblemService {

  final DirectoryService _directoryService = DirectoryService();

  Future<void> submitProblem(ProblemRegisterModel problemData, BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    if (userId == null) {
      throw Exception("User ID is not available");
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/problem'),
        headers: {'Content-Type': 'application/json; charset=UTF-8', 'userId' : userId.toString()},
        body: jsonEncode(problemData.toJson()),
      );

      if (response.statusCode == 200) {
        print('Problem successfully submitted');

        // 폴더 갱신
        await _directoryService.fetchAndSaveProblems();

        showSuccessDialog(context);
      } else {
        print('Failed to submit problem: ${response.body}');
      }
    } catch (e) {
      print('Error submitting problem: $e');
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
}