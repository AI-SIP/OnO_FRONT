import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // JSON 처리를 위한 라이브러리

class ProblemInformationScreen extends StatelessWidget {
  const ProblemInformationScreen({super.key});

  Future<void> fetchData() async {
    try {
      final url = 'http://localhost:8080/api/user/autoLogin/test1';
      final response = await http
          .get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data); // 콘솔에 데이터 출력, 필요에 따라 다른 처리 가능
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print(e.toString()); // 에러 출력
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '오답노트 복습 화면',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchData,
              child: const Text('데이터 가져오기'),
            ),
          ],
        ),
      ),
    );
  }
}
