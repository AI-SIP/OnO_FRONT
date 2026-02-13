import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteDetailModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteUpdateModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNotificationModel.dart';
import 'package:provider/provider.dart';

import '../../Model/PracticeNote/PracticeNoteRegisterModel.dart';
import '../../Model/PracticeNote/RepeatType.dart';
import '../../Module/Dialog/SnackBarDialog.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/PracticeNoteProvider.dart';

class PracticeTitleWriteScreen extends StatefulWidget {
  final PracticeNoteRegisterModel? practiceRegisterModel;
  final PracticeNoteUpdateModel? practiceNoteUpdateModel;
  final PracticeNoteDetailModel? practiceNoteDetailModel;

  const PracticeTitleWriteScreen({
    super.key,
    this.practiceRegisterModel,
    this.practiceNoteUpdateModel,
    this.practiceNoteDetailModel,
  });

  @override
  _PracticeTitleWriteScreenState createState() =>
      _PracticeTitleWriteScreenState();
}

class _PracticeTitleWriteScreenState extends State<PracticeTitleWriteScreen> {
  late TextEditingController _titleController;
  bool _notifyEnabled = false;
  int _intervalDays = 7;
  late TimeOfDay _notifyTime;
  RepeatType _repeatType = RepeatType.daily;
  Set<int> _selectedWeekdays = {};

  @override
  void initState() {
    super.initState();

    // 현재 시각으로 초기화
    final now = DateTime.now();
    _notifyTime = TimeOfDay(hour: now.hour, minute: now.minute);

    _titleController = TextEditingController(
      text: widget.practiceNoteUpdateModel != null
          ? widget.practiceNoteUpdateModel!.practiceTitle
          : widget.practiceRegisterModel?.practiceTitle ?? '',
    );

    if (widget.practiceNoteDetailModel != null &&
        widget.practiceNoteDetailModel!.practiceNotificationModel != null) {
      _notifyEnabled = true;
      _intervalDays = widget
          .practiceNoteDetailModel!.practiceNotificationModel!.intervalDays!;
      final hour =
          widget.practiceNoteDetailModel!.practiceNotificationModel!.hour!;
      final minute =
          widget.practiceNoteDetailModel!.practiceNotificationModel!.minute!;
      _notifyTime = TimeOfDay(hour: hour, minute: minute);

      _repeatType = widget
              .practiceNoteDetailModel!.practiceNotificationModel!.repeatType ??
          RepeatType.daily;
      _selectedWeekdays = widget
              .practiceNoteDetailModel!.practiceNotificationModel!.weekDays
              ?.toSet() ??
          Set();
    }
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

      try {
        if (widget.practiceNoteUpdateModel != null) {
          widget.practiceNoteUpdateModel!
              .setPracticeTitle(_titleController.text);

          if (_notifyEnabled) {
            PracticeNotificationModel practiceNotificationModel =
                PracticeNotificationModel(
              intervalDays: _intervalDays,
              hour: _notifyTime.hour,
              minute: _notifyTime.minute,
              repeatType: _repeatType,
              weekDays: _repeatType == RepeatType.weekly
                  ? _selectedWeekdays.toList()
                  : null,
            );

            widget.practiceNoteUpdateModel!
                .setPracticeNotificationModel(practiceNotificationModel);
          }

          await problemPracticeProvider
              .updatePractice(widget.practiceNoteUpdateModel!);

          _showSnackBar(context, themeProvider, '복습 노트가 수정되었습니다.',
              themeProvider.primaryColor);

          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
        } else {
          widget.practiceRegisterModel!.setPracticeTitle(_titleController.text);

          if (_notifyEnabled) {
            PracticeNotificationModel practiceNotificationModel =
                PracticeNotificationModel(
              intervalDays: _intervalDays,
              hour: _notifyTime.hour,
              minute: _notifyTime.minute,
              repeatType: _repeatType,
              weekDays: _repeatType == RepeatType.weekly
                  ? _selectedWeekdays.toList()
                  : null,
            );

            widget.practiceRegisterModel!
                .setPracticeNotificationModel(practiceNotificationModel);
          }
          await problemPracticeProvider
              .registerPractice(widget.practiceRegisterModel!);

          _showSnackBar(context, themeProvider, '복습 노트가 생성되었습니다.',
              themeProvider.primaryColor);

          Navigator.pop(context);
          Navigator.pop(context);
        }
      } catch (error) {
        log(error.toString());
        _showSnackBar(context, themeProvider, '복습 노트 생성에 실패했습니다.', Colors.red);
        throw Exception(error);
      }
    }
  }

  void _showTitleRequiredDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const StandardText(
                      text: '경고',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 내용
                const StandardText(
                  text: '제목을 입력해 주세요!',
                  fontSize: 15,
                  color: Colors.black87,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 액션 버튼
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      backgroundColor: themeProvider.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const StandardText(
                      text: '확인',
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
        text:
            widget.practiceNoteUpdateModel == null ? "복습 노트 만들기" : "복습 노트 수정하기",
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
          ? "복습 노트의 이름을 입력해주세요"
          : "수정할 이름을 입력해주세요",
      fontSize: 18,
      color: Colors.black,
    );
  }

  Widget _buildTextField(
      TextStyle standardTextStyle, ThemeHandler themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Icon(
                Icons.edit_note,
                color: themeProvider.primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const StandardText(
              text: '복습 노트 제목',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          style: standardTextStyle.copyWith(
            color: Colors.black87,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeProvider.primaryColor.withOpacity(0.5),
                width: 2,
              ),
            ),
            fillColor: Colors.grey[50],
            filled: true,
            hintText: "ex) 9월 모의 전과목 모의고사 오답 복습",
            hintStyle: standardTextStyle.copyWith(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          maxLines: 2,
        ),
      ],
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
                ? "복습 노트 수정하기"
                : "복습 노트 만들기",
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSection(ThemeHandler theme, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Icon(
                Icons.notifications_active,
                color: theme.primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const StandardText(
              text: '복습 주기 알림',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const StandardText(
                      text: '알림 사용',
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: _notifyEnabled,
                        activeColor: theme.primaryColor,
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
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StandardText(
                        text: '반복 주기',
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildChoiceButton(
                              label: "매일",
                              isSelected: _repeatType == RepeatType.daily,
                              onTap: () => setState(() => _repeatType = RepeatType.daily),
                              theme: theme,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildChoiceButton(
                              label: "매주",
                              isSelected: _repeatType == RepeatType.weekly,
                              onTap: () => setState(() => _repeatType = RepeatType.weekly),
                              theme: theme,
                            ),
                          ),
                        ],
                      ),

                      if (_repeatType == RepeatType.weekly) ...[
                        const SizedBox(height: 16),
                        const StandardText(
                          text: '요일 선택',
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(7, (index) {
                            final day = index + 1;
                            final dayText = ['월', '화', '수', '목', '금', '토', '일'][index];
                            final isSelected = _selectedWeekdays.contains(day);
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedWeekdays.remove(day);
                                  } else {
                                    _selectedWeekdays.add(day);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.primaryColor.withOpacity(0.1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.primaryColor
                                        : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: StandardText(
                                  text: dayText,
                                  fontSize: 13,
                                  color: isSelected ? theme.primaryColor : Colors.black54,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],

                      const SizedBox(height: 16),
                      const StandardText(
                        text: '알림 시각',
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _showTimePickerBottomSheet(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: theme.primaryColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  StandardText(
                                    text: _notifyTime.format(context),
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeHandler theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: StandardText(
          text: label,
          fontSize: 14,
          color: isSelected ? theme.primaryColor : Colors.black54,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  void _showTimePickerBottomSheet(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    final openTime = DateTime.now();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title with icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.access_time,
                          color: themeProvider.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const StandardText(
                        text: '알림 시각 선택',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
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
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: themeProvider.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const StandardText(
                        text: '확인',
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
