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
import 'PracticeProblemSelectionScreen.dart';

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
      appBar: _buildAppBar(context, themeProvider),
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPracticeInfo(context, themeProvider),
          const Divider(),
          Expanded(child: _buildProblemList(context, practiceProvider, themeProvider)),
          _buildNextButton(context, themeProvider, practiceProvider),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, ThemeHandler themeProvider) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: StandardText(
        text: practice.practiceTitle,
        fontSize: 20,
        color: themeProvider.primaryColor,
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0), // 우측에 여백 추가
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: themeProvider.primaryColor,
                ),
                onPressed: () => _showBottomSheet(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBottomSheet(BuildContext context) async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0), // 패딩 추가
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0), // 타이틀 아래 여백 추가
                  child: StandardText(
                    text: '복습 리스트 편집하기', // 타이틀 텍스트
                    fontSize: 20,
                    color: themeProvider.primaryColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0), // 텍스트 간격 조정
                  child: ListTile(
                    leading: const Icon(Icons.edit, color: Colors.black),
                    title: const StandardText(
                      text: '문제 목록 편집하기',
                      fontSize: 16,
                      color: Colors.black,
                    ),

                    onTap: () {
                      Navigator.pop(context); // BottomSheet 닫기
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PracticeProblemSelectionScreen(
                            practiceModel: practice, // ProblemPracticeModel 전체 전달
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0), // 텍스트 간격 조정
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const StandardText(
                      text: '복습 리스트 삭제하기',
                      fontSize: 16,
                      color: Colors.red,
                    ),

                    onTap: () {
                      Navigator.pop(context); // BottomSheet 닫기
                      _showDeletePracticeDialog(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPracticeInfo(BuildContext context, ThemeHandler themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPracticeTile('문제 수', '${practice.practiceSize}', themeProvider),
          const VerticalDivider(thickness: 1, color: Colors.grey, width: 1),
          _buildPracticeTile('복습 횟수', '${practice.practiceCount}회', themeProvider),
          const VerticalDivider(thickness: 1, color: Colors.grey, width: 1),
          _buildPracticeTile(
            '마지막 복습 일시',
            practice.lastSolvedAt != null ? formatDateTime(practice.lastSolvedAt!) : "기록 없음",
            themeProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeTile(String title, String value, ThemeHandler themeProvider) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StandardText(
            text: title,
            fontSize: 14,
            color: themeProvider.primaryColor,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          StandardText(
            text: value,
            fontSize: 14,
            color: Colors.black,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProblemList(BuildContext context, ProblemPracticeProvider provider, ThemeHandler themeProvider) {
    final problems = provider.problems;

    if (problems.isEmpty) {
      return Center(
        child: StandardText(
          text: '복습할 오답노트가 없습니다.',
          fontSize: 16,
          color: themeProvider.primaryColor,
        ),
      );
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
            _buildImageThumbnail(imageUrl),
            const SizedBox(width: 16),
            _buildProblemDetails(problem),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(String? imageUrl) {
    return SizedBox(
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
    );
  }

  Widget _buildProblemDetails(ProblemModel problem) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StandardText(
            text: (problem.reference != null && problem.reference!.isNotEmpty) ? problem.reference! : '제목 없음',
            fontSize: 16,
            color: Colors.black,
          ),
          const SizedBox(height: 4),
          StandardText(
            text: '작성 일시: ${problem.createdAt != null ? formatDateTime(problem.createdAt!) : '정보 없음'}',
            fontSize: 12,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(BuildContext context, ThemeHandler themeProvider, ProblemPracticeProvider practiceProvider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      width: MediaQuery.of(context).size.width * 0.8,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeProvider.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () => _onNextButtonPressed(context, practiceProvider),
        child: const StandardText(
          text: '복습하기',
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  void _onNextButtonPressed(BuildContext context, ProblemPracticeProvider practiceProvider) {
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
    } else {
      SnackBarDialog.showSnackBar(
        context: context,
        message: '복습 리스트가 비어있습니다!',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _showDeletePracticeDialog(BuildContext context) async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const StandardText(
            text: '복습 리스트 삭제',
            fontSize: 18,
            color: Colors.black,
          ),
          content: const StandardText(
            text: '정말로 이 복습 리스트를 삭제하시겠습니까?',
            fontSize: 16,
            color: Colors.black,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const StandardText(
                text: '취소',
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                final provider = Provider.of<ProblemPracticeProvider>(context,
                    listen: false);
                List<int> deletePracticeIds = [practice.practiceId];
                bool isDelete = await provider.deletePractices(deletePracticeIds);

                if(isDelete){
                  SnackBarDialog.showSnackBar(
                      context: context,
                      message: '공책이 삭제되었습니다!',
                      backgroundColor: themeProvider.primaryColor);
                  Navigator.pop(context);
                } else {
                  SnackBarDialog.showSnackBar(
                      context: context,
                      message: '삭제 과정에서 문제가 발생했습니다!',
                      backgroundColor: Colors.red);
                }
              },
              child: const StandardText(
                text: '삭제',
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }
}