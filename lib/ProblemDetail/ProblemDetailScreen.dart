import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mvp_front/Service/ProblemService.dart';

import '../GlobalModule/GridPainter.dart';

class ProblemDetailScreen extends StatelessWidget {
  final int problemId;

  ProblemDetailScreen({Key? key, required this.problemId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final problemService = Provider.of<ProblemService>(context, listen: false);
    final problemData = problemService.getProblemDetails(problemId);

    return Scaffold(
      appBar: AppBar(
        title: Text('문제 $problemId',
            style: TextStyle(
                color: Colors.green,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ),
      body: problemData != null
          ? buildProblemDetails(context, problemService, problemData)
          : buildNoDataScreen(),
    );
  }

  Widget buildProblemDetails(BuildContext context,
      ProblemService problemService, Map<String, dynamic> problemData) {
    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: GridPainter(),
        ),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // 좌우 여백 추가
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // 가운데 정렬
              children: [
                SizedBox(height: 16.0), // 상단 여백 추가
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // 가운데 정렬
                        children: [
                          Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today, color: Colors.green),
                                SizedBox(width: 8.0),
                                Text('푼 날짜',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.0), // 상하 간격 추가
                          Text('${problemData['solvedAt']}',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.0), // 둘 사이 공백 추가
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // 가운데 정렬
                        children: [
                          Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info, color: Colors.green),
                                SizedBox(width: 8.0),
                                Text('문제 출처',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.0), // 상하 간격 추가
                          Text('${problemData['reference']}',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.0), // 상하 간격 추가
                Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.green),
                      SizedBox(width: 8.0),
                      Text('문제',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  ),
                ),
                SizedBox(height: 20.0), // 상하 간격 추가
                displayImage(
                    problemData['processImageUrl'], 'assets/process_image.png'),
                SizedBox(height: 30.0), // 상하 간격 추가
                ExpansionTile(
                  title: Container(
                    width: double.infinity,
                    alignment: Alignment.center, // 가운데 정렬
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 8.0),
                        Text('해설 및 풀이 확인',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  children: [
                    SizedBox(height: 30.0), // 상하 간격 추가,
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // 가운데 정렬
                        children: [
                          Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit, color: Colors.green),
                                SizedBox(width: 8.0),
                                Text('메모',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.0), // 상하 간격 추가
                          Text('${problemData['memo']}',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0),
                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, color: Colors.green),
                          SizedBox(width: 8.0),
                          Text('풀이 이미지',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0), // 상하 간격 추가
                    displayImage(
                        problemData['solveImageUrl'], 'assets/solve_image.png'),
                    SizedBox(height: 20.0), // 상하 간격 추가
                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, color: Colors.green),
                          SizedBox(width: 8.0),
                          Text('원본 이미지',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0), // 상하 간격 추가
                    displayImage(problemData['answerImageUrl'],
                        'assets/problem_image.png'),
                    SizedBox(height: 20.0), // 상하 간격 추가
                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, color: Colors.green),
                          SizedBox(width: 8.0),
                          Text('해설 이미지',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0), // 상하 간격 추가
                    displayImage(problemData['answerImageUrl'],
                        'assets/answer_image.png'),
                    SizedBox(height: 20.0), // 상하 간격 추가
                  ],
                ),
                SizedBox(height: 20.0), // 상하 간격 추가
                navigationButtons(context, problemService, problemId)
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget navigationButtons(
      BuildContext context, ProblemService service, int currentId) {
    final problemIds = service.getProblemIds(); // 모든 문제 ID를 가져옴
    int currentIndex = problemIds.indexOf(currentId);
    int previousIndex =
        (currentIndex - 1 + problemIds.length) % problemIds.length;
    int nextIndex = (currentIndex + 1) % problemIds.length;

    int previousProblemId = problemIds[previousIndex];
    int nextProblemId = problemIds[nextIndex];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () =>
              navigateToProblem(context, service, previousProblemId),
          child: Text('이전 문제',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
        ),
        ElevatedButton(
          onPressed: () => navigateToProblem(context, service, nextProblemId),
          child: Text('다음 문제',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
        ),
      ],
    );
  }

  void navigateToProblem(
      BuildContext context, ProblemService service, int newProblemId) {
    if (service.getProblemDetails(newProblemId) != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ProblemDetailScreen(problemId: newProblemId)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('더 이상 문제가 없습니다.'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  Widget buildNoDataScreen() {
    return Center(child: Text("문제 정보를 가져올 수 없습니다."));
  }

  Widget displayImage(String? imagePath, String defaultImagePath) {
    if (imagePath == null ||
        imagePath.isEmpty ||
        !File(imagePath).existsSync()) {
      return Image.asset(defaultImagePath, fit: BoxFit.cover);
    } else {
      return Image.file(File(imagePath), fit: BoxFit.cover);
    }
  }
}
