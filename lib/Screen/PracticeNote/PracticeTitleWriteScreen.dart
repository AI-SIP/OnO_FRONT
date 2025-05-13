import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../Model/PracticeNote/PracticeNoteRegisterModel.dart';
import '../../Module/Dialog/SnackBarDialog.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/PracticeNoteProvider.dart';

class PracticeTitleWriteScreen extends StatelessWidget {
  final PracticeNoteRegisterModel practiceRegisterModel;
  final TextEditingController _titleController;

  PracticeTitleWriteScreen({required this.practiceRegisterModel})
      : _titleController =
            TextEditingController(text: practiceRegisterModel.practiceTitle);

  void _submitPractice(BuildContext context, ThemeHandler themeProvider) async {
    if (_titleController.text.isEmpty) {
      _showTitleRequiredDialog(context);
    } else {
      final problemPracticeProvider =
          Provider.of<ProblemPracticeProvider>(context, listen: false);

      practiceRegisterModel.setPracticeTitle(_titleController.text);

      bool isSubmit = false, isUpdate = false;
      if (practiceRegisterModel.practiceId == null) {
        await problemPracticeProvider.registerPractice(practiceRegisterModel);
        isSubmit = true;
      } else {
        await problemPracticeProvider.updatePractice(practiceRegisterModel);
        isUpdate = true;
      }

      Navigator.pop(context);
      Navigator.pop(context);

      if (isSubmit) {
        _showSnackBar(context, themeProvider, '복습 리스트가 생성되었습니다.',
            themeProvider.primaryColor);
      } else if (isUpdate) {
        Navigator.pop(context);
        _showSnackBar(context, themeProvider, '복습 리스트가 수정되었습니다.',
            themeProvider.primaryColor);
      } else {
        _showSnackBar(context, themeProvider, '복습 리스트가 실패했습니다.', Colors.red);
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

  void _showSnackBar(BuildContext context, ThemeHandler themeProvider,
      String message, Color color) {
    SnackBarDialog.showSnackBar(
      context: context,
      message: message,
      backgroundColor: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    double screenHeight = MediaQuery.of(context).size.height;
    final standardTextStyle = const StandardText(text: '').getTextStyle();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // 다른 곳을 클릭하면 키보드를 숨깁니다.
      },
      child: Scaffold(
        appBar: _buildAppBar(themeProvider),
        backgroundColor: Colors.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                child: _buildContent(
                    screenHeight, standardTextStyle, themeProvider)),
            _buildSubmitButton(context, themeProvider),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(ThemeHandler themeProvider) {
    return AppBar(
      title: StandardText(
        text: practiceRegisterModel.practiceId == null
            ? "복습 리스트 만들기"
            : "복습 리스트 수정하기",
        fontSize: 20,
        color: themeProvider.primaryColor,
      ),
      backgroundColor: Colors.white,
      centerTitle: true,
    );
  }

  Widget _buildContent(double screenHeight, TextStyle standardTextStyle,
      ThemeHandler themeProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTitleText(),
          SizedBox(height: screenHeight * 0.03),
          _buildTextField(standardTextStyle, themeProvider),
          SizedBox(height: screenHeight * 0.03),
          _buildInfoContainer(screenHeight, themeProvider),
        ],
      ),
    );
  }

  Widget _buildTitleText() {
    return StandardText(
      text: practiceRegisterModel.practiceId == null
          ? "복습 리스트의 이름을 입력해주세요"
          : "수정할 이름을 입력해주세요",
      fontSize: 18,
      color: Colors.black,
    );
  }

  Widget _buildTextField(
      TextStyle standardTextStyle, ThemeHandler themeProvider) {
    return TextField(
      controller: _titleController,
      style: standardTextStyle.copyWith(
        color: themeProvider.primaryColor,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: themeProvider.primaryColor, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: themeProvider.primaryColor, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: themeProvider.primaryColor, width: 2.0),
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
    );
  }

  Widget _buildInfoContainer(double screenHeight, ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withOpacity(0.1),
        border: Border.all(color: themeProvider.primaryColor, width: 1.0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoHeader(themeProvider),
          SizedBox(height: screenHeight * 0.02),
          _buildInfoText(),
        ],
      ),
    );
  }

  Widget _buildInfoHeader(ThemeHandler themeProvider) {
    return Row(
      children: [
        SvgPicture.asset('assets/Icon/RainbowNote.svg', width: 24, height: 24),
        const SizedBox(width: 8),
        StandardText(
          text: "3회 반복 복습 시스템",
          fontSize: 20,
          color: themeProvider.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ],
    );
  }

  Widget _buildInfoText() {
    return const Text(
      "뇌과학적으로 1일차, 1주일 후, 1달 후 간격을 둔 반복 복습이 기억에 가장 잘 남는다고 해요. 이를 참고해서 잊지 않고 3번의 복습이 이루어지도록 도와드려요.",
      style: TextStyle(fontSize: 15, color: Colors.black),
    );
  }

  Widget _buildSubmitButton(BuildContext context, ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: ElevatedButton(
          onPressed: () => _submitPractice(context, themeProvider),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: StandardText(
            text: practiceRegisterModel.practiceId == null
                ? "복습 리스트 만들기"
                : "복습 리스트 수정하기",
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
