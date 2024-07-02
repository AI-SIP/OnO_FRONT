import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:developer'; // 로깅을 위해 추가

class DirectoryService {
  // 서버에서 문제 목록을 가져와 저장하고 SharedPreferences에 저장하는 함수
  Future<void> fetchAndSaveProblems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    if (userId == null) {
      log('User ID is not available');
      throw Exception('User ID is not available');
    }

    final url = Uri.parse('http://localhost:8080/api/problems');
    final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'userId': userId.toString(), // User ID를 문자열로 변환하여 헤더에 추가
        }
    );

    log('Fetching problems: ${response.statusCode} ${response.body}'); // 로깅 추가

    if (response.statusCode == 200) {
      await prefs.setString('problems', response.body); // JSON 데이터를 문자열로 저장
    } else {
      log('Failed to load problems from server'); // 로깅 추가
      throw Exception('Failed to load problems from server');
    }
  }

  // 저장된 문제 목록을 로드
  Future<List<ProblemThumbnail>> loadProblemsFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? problemsData = prefs.getString('problems');

    if (problemsData != null) {
      Iterable data = json.decode(problemsData);
      return data.map<ProblemThumbnail>((model) => ProblemThumbnail.fromJson(model)).toList();
    } else {
      log('No problems found in cache'); // 로깅 추가
      throw Exception('No problems found in cache');
    }
  }
}

class ProblemThumbnail {
  final int id;
  final String imageUrl;

  ProblemThumbnail({required this.id, required this.imageUrl});

  factory ProblemThumbnail.fromJson(Map<String, dynamic> json) {
    return ProblemThumbnail(
      id: json['problemId'],
      imageUrl: json['imageUrl'],
    );
  }
}