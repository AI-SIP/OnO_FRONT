import 'package:flutter/material.dart';
import 'package:mvp_front/Service/ProblemService.dart';
import 'ProblemDetailScreen.dart';

class NavigationButtons extends StatelessWidget {
  final BuildContext context;
  final ProblemService service;
  final int currentId;

  const NavigationButtons(
      {required this.context, required this.service, required this.currentId});

  @override
  Widget build(BuildContext context) {
    return Row(

    );
  }
    /*
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
                  fontFamily: 'font1',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
        ),
        ElevatedButton(
          onPressed: () => navigateToProblem(context, service, nextProblemId),
          child: Text('다음 문제',
              style: TextStyle(
                  fontFamily: 'font1',
                  fontSize: 16,
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

     */
}
