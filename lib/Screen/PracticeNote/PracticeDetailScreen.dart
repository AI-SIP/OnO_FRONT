import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../Model/PracticeNote/PracticeNoteDetailModel.dart';
import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Dialog/SnackBarDialog.dart';
import '../../Module/Image/DisplayImage.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/PracticeNoteProvider.dart';
import '../ProblemDetail/ProblemDetailScreen.dart';
import 'PracticeProblemSelectionScreen.dart';

class PracticeDetailScreen extends StatelessWidget {
  final PracticeNoteDetailModel practice;

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
          Expanded(
              child:
                  _buildProblemList(context, practiceProvider, themeProvider)),
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

    final openTime = DateTime.now();
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isDismissible: false,
      builder: (context) {
        return TapRegion(
          onTapOutside: (_) {
            // Workaround for iPadOS 26.1 bug: https://github.com/flutter/flutter/issues/177992
            if (DateTime.now().difference(openTime) < const Duration(milliseconds: 500)) {
              return;
            }
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 24.0, horizontal: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeProvider.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.edit_note,
                            color: themeProvider.primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const StandardText(
                          text: '복습 노트 편집하기',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Menu items
                    _buildActionItem(
                      icon: Icons.edit,
                      iconColor: themeProvider.primaryColor,
                      title: '복습 노트 편집하기',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PracticeProblemSelectionScreen(
                              practiceModel: practice,
                            ),
                          ),
                        );
                      },
                      themeProvider: themeProvider,
                    ),
                    const SizedBox(height: 12),
                    _buildActionItem(
                      icon: Icons.delete_forever,
                      iconColor: Colors.red,
                      title: '복습 노트 삭제하기',
                      titleColor: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _showDeletePracticeDialog(context);
                      },
                      themeProvider: themeProvider,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
    required ThemeHandler themeProvider,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StandardText(
                text: title,
                fontSize: 16,
                color: titleColor ?? Colors.black87,
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
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
          _buildPracticeTile(
              '복습 횟수', '${practice.practiceCount}회', themeProvider),
          const VerticalDivider(thickness: 1, color: Colors.grey, width: 1),
          _buildPracticeTile(
            '마지막 복습 일시',
            practice.lastSolvedAt != null
                ? formatDateTime(practice.lastSolvedAt!)
                : "기록 없음",
            themeProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeTile(
      String title, String value, ThemeHandler themeProvider) {
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

  Widget _buildProblemList(BuildContext context,
      ProblemPracticeProvider provider, ThemeHandler themeProvider) {
    final problems = provider.currentProblems;

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
    final imageUrl = problem.problemImageDataList != null &&
            problem.problemImageDataList!.isNotEmpty
        ? problem.problemImageDataList!.first.imageUrl
        : null;

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
        child: DisplayImage(
          imagePath: imageUrl,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildProblemDetails(ProblemModel problem) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StandardText(
            text: (problem.reference != null && problem.reference!.isNotEmpty)
                ? problem.reference!
                : '제목 없음',
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
    );
  }

  Widget _buildNextButton(BuildContext context, ThemeHandler themeProvider,
      ProblemPracticeProvider practiceProvider) {
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

  void _onNextButtonPressed(
      BuildContext context, ProblemPracticeProvider practiceProvider) {
    if (practiceProvider.currentProblems.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProblemDetailScreen(
            problemId: practiceProvider.currentProblems.first.problemId,
            isPractice: true,
          ),
        ),
      );
    } else {
      SnackBarDialog.showSnackBar(
        context: context,
        message: '복습 노트가 비어있습니다!',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _showDeletePracticeDialog(BuildContext context) async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const StandardText(
                      text: '복습 노트 삭제',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 내용
                const StandardText(
                  text: '정말로 이 복습 노트를 삭제하시겠습니까?',
                  fontSize: 15,
                  color: Colors.black87,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 액션 버튼
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const StandardText(
                          text: '취소',
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }

                          final provider = Provider.of<ProblemPracticeProvider>(context,
                              listen: false);
                          List<int> deletePracticeIds = [practice.practiceId];
                          await provider.deletePractices(deletePracticeIds);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const StandardText(
                          text: '삭제',
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
