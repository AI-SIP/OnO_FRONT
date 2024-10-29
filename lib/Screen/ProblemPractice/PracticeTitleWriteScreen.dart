import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../GlobalModule/Theme/SnackBarDialog.dart';
import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import 'package:provider/provider.dart';
import '../../Provider/ProblemPracticeProvider.dart';
import '../../Model/ProblemPracticeRegisterModel.dart';

class PracticeTitleWriteScreen extends StatelessWidget {
  final List<int> selectedProblemIds;

  PracticeTitleWriteScreen({required this.selectedProblemIds});

  final TextEditingController _titleController = TextEditingController();

  void _submitPractice(BuildContext context, ThemeHandler themeProvider) async {
    if (_titleController.text.isEmpty) {
      _showTitleRequiredDialog(context);
    } else {
      final problemPracticeProvider =
      Provider.of<ProblemPracticeProvider>(context, listen: false);
      final model = ProblemPracticeRegisterModel(
        practiceCount: 0,
        practiceTitle: _titleController.text,
        registerProblemIds: selectedProblemIds,
        removeProblemIds: [],
      );

      bool isSubmit =  await problemPracticeProvider.submitPracticeProblems(model);
      Navigator.pop(context);
      Navigator.pop(context);

      if(isSubmit){
        SnackBarDialog.showSnackBar(
          context: context,
          message: '복습 루틴이 생성되었습니다.',
          backgroundColor: themeProvider.primaryColor,
        );
      } else{
        SnackBarDialog.showSnackBar(
          context: context,
          message: '복습 루틴에 실패했습니다.',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _showTitleRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title:
          const StandardText(text: "경고", fontSize: 18, color: Colors.black),
          content: const StandardText(
              text: "제목을 입력해 주세요!", fontSize: 16, color: Colors.black),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const StandardText(
                  text: "확인", fontSize: 14, color: Colors.red),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    double screenHeight = MediaQuery.of(context).size.height;
    final standardTextStyle = const StandardText(text: '').getTextStyle();

    return Scaffold(
      appBar: AppBar(
        title: StandardText(
            text: "복습 루틴 만들기", fontSize: 20, color: themeProvider.primaryColor),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const StandardText(
                    text: "복습 루틴의 이름을 정해주세요",
                    fontSize: 18,
                    color: Colors.black,
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  TextField(
                    controller: _titleController,
                    style: standardTextStyle.copyWith(
                        color: themeProvider.primaryColor, fontSize: 16),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: themeProvider.primaryColor, width: 2.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: themeProvider.primaryColor, width: 2.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: themeProvider.primaryColor, width: 2.0),
                      ),
                      fillColor: themeProvider.primaryColor.withOpacity(0.1),
                      filled: true,
                      hintText: "ex) 9월 모의 전과목 모의고사 오답 복습",
                      hintStyle: standardTextStyle.copyWith(
                        color: themeProvider.desaturateColor,
                        fontSize: 15,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      border: Border.all(color: themeProvider.primaryColor, width: 1.0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset('assets/Icon/RainbowNote.svg',
                                width: 24, height: 24),
                            const SizedBox(width: 8),
                            StandardText(
                              text: "3회 반복 복습 시스템",
                              fontSize: 20,
                              color: themeProvider.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        const Text(
                          "뇌과학적으로 1일차, 1주일 후, 1달 후 간격을 둔 반복 복습이 "
                              "기억에 가장 잘 남는다고 해요. 이를 참고해서 잊지 않고 "
                              "3번의 복습이 이루어지도록 도와드려요.",
                          style: TextStyle(fontSize: 15, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.only(bottom: 16.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: ElevatedButton(
                onPressed: () => _submitPractice(context, themeProvider),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: themeProvider.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const StandardText(
                  text: "복습 루틴 만들기",
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}