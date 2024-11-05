import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../GlobalModule/Theme/SnackBarDialog.dart';
import '../../Model/ProblemPracticeModel.dart';
import '../../Model/ProblemModel.dart';
import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../Model/TemplateType.dart';
import '../../Provider/ProblemPracticeProvider.dart';
import '../ProblemDetail/ProblemDetailScreenV2.dart';

class PracticeDetailScreen extends StatelessWidget {
  final ProblemPracticeModel practice;

  const PracticeDetailScreen({super.key, required this.practice});

  String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final practiceProvider = Provider.of<ProblemPracticeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: StandardText(
          text: practice.practiceTitle,
          fontSize: 20,
          color: themeProvider.primaryColor,
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPracticeInfo(context, themeProvider),
          const Divider(),
          Expanded(child: _buildProblemList(context, practiceProvider, themeProvider)),
          _buildNextButton(context, themeProvider),
        ],
      ),
    );
  }

  Widget _buildPracticeInfo(BuildContext context, ThemeHandler themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 첫 번째 타일: 문제 수
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StandardText(
                  text: '문제 수',
                  fontSize: 14,
                  color: themeProvider.primaryColor,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                StandardText(
                  text: '${practice.practiceSize}',
                  fontSize: 14,
                  color: Colors.black,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // 타일 구분을 위한 Divider
          const VerticalDivider(thickness: 1, color: Colors.grey, width: 1),

          // 두 번째 타일: 복습 횟수
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StandardText(
                  text: '복습 횟수',
                  fontSize: 14,
                  color: themeProvider.primaryColor,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                StandardText(
                  text: '${practice.practiceCount}회',
                  fontSize: 14,
                  color: Colors.black,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // 타일 구분을 위한 Divider
          const VerticalDivider(thickness: 1, color: Colors.grey, width: 1),

          // 세 번째 타일: 마지막 복습 일시
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StandardText(
                  text: '마지막 복습 일시',
                  fontSize: 14,
                  color: themeProvider.primaryColor,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                StandardText(
                  text: practice.lastSolvedAt != null
                      ? formatDateTime(practice.lastSolvedAt!)
                      : "기록 없음",
                  fontSize: 14,
                  color: Colors.black,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemList(BuildContext context,
      ProblemPracticeProvider provider, ThemeHandler themeProvider) {
    final problems = provider.problems;

    if (problems.isEmpty) {
      return Center(
          child: StandardText(
        text: '복습할 문제가 없습니다.',
        fontSize: 16,
        color: themeProvider.primaryColor,
      ));
    }

    return ListView.builder(
      itemCount: problems.length,
      itemBuilder: (context, index) {
        return _buildProblemItem(problems[index], themeProvider);
      },
    );
  }

  Widget _buildProblemItem(ProblemModel problem, ThemeHandler themeProvider) {
    final imageUrl = (problem.templateType == TemplateType.simple)
        ? problem.problemImageUrl
        : problem.processImageUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 70,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StandardText(
                    text: problem.reference ?? '제목 없음',
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 4),
                  StandardText(
                    text:
                        '작성 일시: ${problem.createdAt != null ? formatDateTime(problem.createdAt!) : '정보 없음'}',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton(BuildContext context, ThemeHandler themeProvider) {
    final practiceProvider = Provider.of<ProblemPracticeProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      width: MediaQuery.of(context).size.width * 0.8,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeProvider.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () async {
          if (practiceProvider.problems.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProblemDetailScreenV2(
                  problemId: practiceProvider.problems.first.problemId,
                  isPractice: true,
                ),
              ),
            );
          } else{
            SnackBarDialog.showSnackBar(
              context: context,
              message: '복습 루틴이 비어있습니다!',
              backgroundColor: Colors.red,
            );
          }
        },
        child: const StandardText(
          text: '복습하기',
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}
