import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteUpdateModel.dart';
import 'package:provider/provider.dart';

import '../../Model/PracticeNote/PracticeNoteRegisterModel.dart';
import '../../Module/Dialog/SnackBarDialog.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/PracticeNoteProvider.dart';

class PracticeTitleWriteScreen extends StatefulWidget {
  final PracticeNoteRegisterModel? practiceRegisterModel;
  final PracticeNoteUpdateModel? practiceNoteUpdateModel;

  const PracticeTitleWriteScreen({
    super.key,
    this.practiceRegisterModel,
    this.practiceNoteUpdateModel,
  });

  @override
  _PracticeTitleWriteScreenState createState() =>
      _PracticeTitleWriteScreenState();
}

class _PracticeTitleWriteScreenState extends State<PracticeTitleWriteScreen> {
  late TextEditingController _titleController;
  bool _notifyEnabled = false;
  int _intervalDays = 1;
  TimeOfDay _notifyTime = TimeOfDay(hour: 9, minute: 0);
  int _notifyCount = 3;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.practiceNoteUpdateModel != null
          ? widget.practiceNoteUpdateModel!.practiceTitle
          : widget.practiceRegisterModel?.practiceTitle ?? '',
    );
    // 초기 설정: 만약 모델에 알림 설정이 이미 있으면, 여기에 반영하세요.
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submitPractice(
      BuildContext context, ThemeHandler themeProvider) async {
    if (_titleController.text.isEmpty) {
      _showTitleRequiredDialog(context);
    } else {
      final problemPracticeProvider =
          Provider.of<ProblemPracticeProvider>(context, listen: false);

      Navigator.pop(context);
      Navigator.pop(context);

      try {
        if (widget.practiceNoteUpdateModel != null) {
          widget.practiceNoteUpdateModel!
              .setPracticeTitle(_titleController.text);
          await problemPracticeProvider
              .updatePractice(widget.practiceNoteUpdateModel!);

          Navigator.pop(context);
          _showSnackBar(context, themeProvider, '복습 리스트가 수정되었습니다.',
              themeProvider.primaryColor);
        } else {
          widget.practiceRegisterModel!.setPracticeTitle(_titleController.text);
          await problemPracticeProvider
              .registerPractice(widget.practiceRegisterModel!);

          _showSnackBar(context, themeProvider, '복습 리스트가 생성되었습니다.',
              themeProvider.primaryColor);
        }
      } catch (error) {
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
        text: widget.practiceNoteUpdateModel == null
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
          _buildNotificationSection(themeProvider, screenHeight),
          SizedBox(height: screenHeight * 0.03),
          _buildInfoContainer(screenHeight, themeProvider),
        ],
      ),
    );
  }

  Widget _buildTitleText() {
    return StandardText(
      text: widget.practiceNoteUpdateModel == null
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
        fillColor: Colors.white,
        //fillColor: themeProvider.primaryColor.withOpacity(0.1),
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
            text: widget.practiceRegisterModel == null
                ? "복습 리스트 수정하기"
                : "복습 리스트 만들기",
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSection(ThemeHandler theme, double screenHeight) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: theme.primaryColor, width: 2.0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 공통 좌우 패딩
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StandardText(
                  text: '복습 주기 알림 사용',
                  fontSize: 16,
                  color: theme.primaryColor,
                ),
                // 스위치 크기 줄이기
                Transform.scale(
                  scale: 0.8, // 80% 크기로 축소
                  child: Switch(
                    value: _notifyEnabled,
                    activeColor: theme.darkPrimaryColor,
                    inactiveTrackColor: Colors.grey.shade300,
                    inactiveThumbColor: Colors.grey,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) => setState(() => _notifyEnabled = v),
                  ),
                ),
              ],
            ),
          ),

          if (_notifyEnabled) ...[
            SizedBox(height: screenHeight * 0.02),

            // 알림 주기
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 0, 0),
              child: _buildNumberInput(
                label: '알림 주기(일)',
                value: _intervalDays,
                onChanged: (v) => setState(() => _intervalDays = v),
                themeProvider: theme,
              ),
            ),

            SizedBox(height: screenHeight * 0.02),

            // 알림 시각
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () => _showTimePickerBottomSheet(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StandardText(
                        text: '알림 시각', fontSize: 16, color: theme.primaryColor),
                    StandardText(
                      text: _notifyTime.format(context),
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.02),

            // 알림 횟수
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 0, 0),
              child: _buildNumberInput(
                label: '알림 횟수',
                value: _notifyCount,
                onChanged: (v) => setState(() => _notifyCount = v),
                themeProvider: theme,
              ),
            ),

            SizedBox(height: screenHeight * 0.02),
          ],
        ],
      ),
    );
  }

  void _showTimePickerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white, // 바텀시트 배경을 흰색으로
      shape: const RoundedRectangleBorder(
        // 모서리를 살짝 둥글게
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white, // 내부도 확실히 흰색
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const StandardText(
                text: '알림 시각 선택',
                color: Colors.black,
                fontSize: 18,
              ),
              const SizedBox(
                height: 20,
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    0,
                    0,
                    0,
                    _notifyTime.hour,
                    _notifyTime.minute,
                  ),
                  use24hFormat: false,
                  onDateTimeChanged: (dt) {
                    setState(() {
                      _notifyTime = TimeOfDay(
                        hour: dt.hour,
                        minute: dt.minute,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const StandardText(
                  text: '확인',
                  color: Colors.black,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNumberInput({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required ThemeHandler themeProvider,
  }) {
    return SizedBox(
      width: double.infinity, // 폭을 최대한으로 늘립니다.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양 끝 정렬
        children: [
          StandardText(
            text: label,
            fontSize: 16,
            color: themeProvider.primaryColor,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.black),
                onPressed: value > 1 ? () => onChanged(value - 1) : null,
              ),
              StandardText(
                text: '$value',
                fontSize: 16,
                color: Colors.black,
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.black),
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
