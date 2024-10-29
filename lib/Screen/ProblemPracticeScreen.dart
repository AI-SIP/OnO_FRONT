import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../GlobalModule/Theme/StandardText.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../Model/ProblemPracticeModel.dart';
import '../Provider/ProblemPracticeProvider.dart';

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
              'assets/Icon/RainbowNote.svg', // 아이콘 경로
              width: 100, // 적절한 크기 설정
              height: 100,
            ),
            const SizedBox(height: 40), // 아이콘과 텍스트 사이 간격
            StandardText(
              text: '오답 복습 루틴을 추가해보세요!',
              fontSize: 16,
              color: themeProvider.primaryColor,
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: practiceThumbnails!.length,
        itemBuilder: (context, index) {
          final practice = practiceThumbnails![index];
          return ListTile(
            leading: Icon(Icons.book, color: themeProvider.primaryColor),
            title: StandardText(
              text: practice.practiceTitle,
              fontSize: 16,
              color: Colors.black,
            ),
            subtitle: Row(
              children: [
                StandardText(
                  text: '${practice.practiceSize} 문제',
                  fontSize: 12,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                StandardText(
                  text: '${practice.practiceCount}회 복습',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ],
            ),
            trailing: _buildStatusIcons(practice.practiceCount),
          );
        },
      ),
    );
  }

  // 복습 완료 상태에 따른 아이콘 표시
  Widget _buildStatusIcons(int practiceCount) {
    List<Widget> icons = [];
    for (int i = 0; i < 5; i++) {
      icons.add(
        Icon(
          Icons.check_circle,
          color: i < practiceCount ? Colors.green : Colors.grey,
          size: 16,
        ),
      );
    }
    return Row(children: icons);
  }
}
