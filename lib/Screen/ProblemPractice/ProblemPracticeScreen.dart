import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../Model/ProblemPracticeModel.dart';
import '../../Provider/ProblemPracticeProvider.dart';
import 'PracticeProblemSelectionScreen.dart';

class ProblemPracticeScreen extends StatefulWidget {
  const ProblemPracticeScreen({super.key});

  @override
  _ProblemPracticeScreen createState() => _ProblemPracticeScreen();
}

class _ProblemPracticeScreen extends State<ProblemPracticeScreen> {
  List<ProblemPracticeModel>? practiceThumbnails;

  @override
  void initState() {
    super.initState();
    _fetchPracticeThumbnails();
  }

  Future<void> _fetchPracticeThumbnails() async {
    final provider = Provider.of<ProblemPracticeProvider>(context, listen: false);
    List<ProblemPracticeModel>? fetchedThumbnails = await provider.fetchAllPracticeThumbnails();
    setState(() {
      practiceThumbnails = fetchedThumbnails;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: StandardText(
          text: '오답 복습',
          fontSize: 20,
          color: themeProvider.primaryColor,
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: practiceThumbnails == null
          ? const Center(child: CircularProgressIndicator())
          : practiceThumbnails!.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/Icon/RainbowNote.svg',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 40),
            StandardText(
              text: '오답 복습 루틴을 추가해보세요!',
              fontSize: 16,
              color: themeProvider.primaryColor,
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: practiceThumbnails!.length,
        itemBuilder: (context, index) {
          final practice = practiceThumbnails![index];
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
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/Icon/RainbowNote.svg',
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StandardText(
                          text: practice.practiceTitle,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildTag('${practice.practiceSize} 문제', themeProvider),
                            const SizedBox(width: 8),
                            practice.practiceCount >= 3
                                ? _buildTag('복습 완료', themeProvider, highlight: true)
                                : _buildTag('${practice.practiceCount}회 복습', themeProvider),
                            const SizedBox(width: 8),
                            ..._buildStatusIcons(practice.practiceCount),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            StandardText(
                              text: '마지막 복습 날짜: ${formatDateTime(practice.lastSolvedAt) ?? '복습 기록 없음'}',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 20,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: themeProvider.primaryColor, width: 2),
              ),
              child: FloatingActionButton(
                heroTag: 'create_problem_practice',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PracticeProblemSelectionScreen(),
                    ),
                  );
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: SvgPicture.asset("assets/Icon/addPractice.svg"),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildTag(String text, ThemeHandler themeProvider, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? themeProvider.primaryColor : themeProvider.primaryColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: StandardText(
        text: text,
        fontSize: 12,
        color: Colors.white,
      ),
    );
  }

  List<Widget> _buildStatusIcons(int practiceCount) {
    List<String> icons = [
      'assets/Icon/SmallGreenFrog.svg',
      'assets/Icon/SmallYellowFrog.svg',
      'assets/Icon/SmallPinkFrog.svg'
    ];

    return List<Widget>.generate(3, (index) {
      return Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: SvgPicture.asset(
          icons[index],
          width: 20,
          height: 20,
          color: index < practiceCount ? null : Colors.white,
        ),
      );
    });
  }

  String? formatDateTime(DateTime? dateTime) {
    if(dateTime == null){
      return null;
    }
    return DateFormat('yyyy/MM/dd').format(dateTime);
  }
}