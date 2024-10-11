import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreenV2.dart';
import 'package:provider/provider.dart';
import '../Theme/StandardText.dart';
import '../Theme/ThemeHandler.dart';

class NavigationButtons extends StatefulWidget {
  final BuildContext context;
  final FoldersProvider foldersProvider;
  final int currentId;

  const NavigationButtons({
    super.key,
    required this.context,
    required this.foldersProvider,
    required this.currentId,
  });

  @override
  _NavigationButtonsState createState() => _NavigationButtonsState();
}

class _NavigationButtonsState extends State<NavigationButtons> {
  bool isReviewed = false; // 복습 완료 상태를 저장하는 변수

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final problemIds = widget.foldersProvider.getProblemIds();

    if (problemIds.isEmpty) {
      return const Center();
    }

    int currentIndex = problemIds.indexOf(widget.currentId);
    int previousProblemId =
    currentIndex > 0 ? problemIds[currentIndex - 1] : problemIds.last;
    int nextProblemId = currentIndex < problemIds.length - 1
        ? problemIds[currentIndex + 1]
        : problemIds.first;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
          onPressed: () {
            FirebaseAnalytics.instance.logEvent(
              name: 'navigate_previous_problem',
            );
            navigateToProblem(context, previousProblemId, isNext: false);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            backgroundColor: themeProvider.primaryColor.withOpacity(0.1),
            side: BorderSide(
              color: themeProvider.primaryColor,
              width: 2.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
          ),
          child: StandardText(
              text: '< 이전 문제',
              fontSize: 12,
              color: themeProvider.primaryColor),
        ),

        // 복습 완료 버튼
        TextButton(
          onPressed: () async {
            if (!isReviewed) {
              FirebaseAnalytics.instance.logEvent(
                name: 'problem_repeat_complete',
              );

              await widget.foldersProvider.addRepeatCount(widget.currentId);
              setState(() {
                isReviewed = true; // 복습 완료 상태로 변경
              });
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            backgroundColor: themeProvider.primaryColor.withOpacity(0.1),
            side: BorderSide(
              color: themeProvider.primaryColor,
              width: 2.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
          ),
          child: isReviewed
              ? Icon(
            Icons.check, // 복습 완료 시 체크 아이콘만 표시
            color: themeProvider.primaryColor,
            size: 24,
          )
              : Row(
            mainAxisSize: MainAxisSize.min, // 터치 아이콘과 텍스트를 한 줄로 표시
            children: [
              Icon(
                Icons.touch_app, // 복습 완료 전 터치 아이콘
                color: themeProvider.primaryColor,
                size: 14,
              ),
              const SizedBox(width: 8), // 아이콘과 텍스트 간 간격
              StandardText(
                text: '복습 완료', // 복습 완료 텍스트
                fontSize: 14,
                color: themeProvider.primaryColor,
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            FirebaseAnalytics.instance.logEvent(
              name: 'navigate_next_problem',
            );
            navigateToProblem(context, nextProblemId, isNext: true);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            backgroundColor: themeProvider.primaryColor.withOpacity(0.1),
            side: BorderSide(
              color: themeProvider.primaryColor,
              width: 2.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
          ),
          child: StandardText(
              text: '다음 문제 >',
              fontSize: 12,
              color: themeProvider.primaryColor),
        ),
      ],
    );
  }

  void navigateToProblem(BuildContext context, int newProblemId, {required bool isNext}) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ProblemDetailScreenV2(problemId: newProblemId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 다음 문제인지 이전 문제인지에 따라 시작 위치와 애니메이션 설정
          final Offset begin = !isNext ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          // 회전 애니메이션 설정
          return SlideTransition(
            position: offsetAnimation,
            child: RotationTransition(
              alignment: Alignment.bottomRight, // 오른쪽 아래를 기준으로 회전
              turns: Tween(begin: !isNext ? -0.1 : 0.1, end: 0.0).animate(animation), // 시계 방향으로 회전
              child: child,
            ),
          );
        },
      ),
    );
  }

  void repeatComplete() async{
    Provider.of<FoldersProvider>(context, listen: false)
        .addRepeatCount(widget.currentId);
  }
}