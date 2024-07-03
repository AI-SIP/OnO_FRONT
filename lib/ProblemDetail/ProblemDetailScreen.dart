import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mvp_front/Service/ProblemService.dart';

class ProblemDetailScreen extends StatelessWidget {
  final int problemId;

  ProblemDetailScreen({Key? key, required this.problemId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final problemService = Provider.of<ProblemService>(context, listen: false);
    final problemData = problemService.getProblemDetails(problemId);

    return Scaffold(
      appBar: AppBar(
        title: Text('문제 상세'),
      ),
      body: problemData != null ? buildProblemDetails(context, problemService, problemData) : buildNoDataScreen(),
    );
  }

  Widget buildProblemDetails(BuildContext context, ProblemService problemService, Map<String, dynamic> problemData) {
    return SingleChildScrollView(
      child: Column(
        children: [
          displayImage(problemData['processImageUrl'], 'assets/default_image.png'),
          displayImage(problemData['answerImageUrl'], 'assets/default_image.png'),
          displayImage(problemData['solveImageUrl'], 'assets/default_image.png'),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('출처: ${problemData['reference']}', style: TextStyle(fontSize: 16)),
                Text('풀이 날짜: ${problemData['solvedAt']}', style: TextStyle(fontSize: 16)),
                Text('메모: ${problemData['memo']}', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          navigationButtons(context, problemService, problemId)
        ],
      ),
    );
  }

  Widget navigationButtons(BuildContext context, ProblemService service, int currentId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () => navigateToProblem(context, service, service.getPreviousProblemId(currentId)),
          child: Text('이전 문제'),
        ),
        ElevatedButton(
          onPressed: () => navigateToProblem(context, service, service.getNextProblemId(currentId)),
          child: Text('다음 문제'),
        ),
      ],
    );
  }

  void navigateToProblem(BuildContext context, ProblemService service, int newProblemId) {
    if (service.getProblemDetails(newProblemId) != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProblemDetailScreen(problemId: newProblemId)),
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
    if (imagePath == null || imagePath.isEmpty || !File(imagePath).existsSync()) {
      return Image.asset(defaultImagePath, fit: BoxFit.cover);
    } else {
      return Image.file(File(imagePath), fit: BoxFit.cover);
    }
  }
}