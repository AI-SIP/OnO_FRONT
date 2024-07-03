import 'package:http/http.dart' as http;
import 'package:mvp_front/Service/ProblemService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer'; // 로깅을 위해 추가

class DirectoryService {
  final ProblemService problemService;

  DirectoryService(this.problemService);

  Future<void> fetchAndSaveProblems() async {
    await problemService.fetchAndSaveProblems();
  }

  // 저장된 문제 목록을 로드
  Future<List<ProblemThumbnail>> loadProblemsFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? problemsData = prefs.getString('problems');

    if (problemsData != null) {
      Iterable data = json.decode(utf8.decode(problemsData.codeUnits));
      return data
          .map<ProblemThumbnail>((model) => ProblemThumbnail.fromJson(model))
          .toList();
    } else {
      log('No problems found in cache'); // 로깅 추가
      throw Exception('오답노트가 존재하지 않습니다!');
    }
  }
}

class ProblemThumbnail {
  final int id;
  final String title;
  final String imageUrl;

  ProblemThumbnail({required this.id, required this.title, required this.imageUrl});

  factory ProblemThumbnail.fromJson(Map<String, dynamic> json) {
    return ProblemThumbnail(
      id: json['problemId'],
      title: json['reference'],
      imageUrl: json['imageUrl'],
    );
  }
}