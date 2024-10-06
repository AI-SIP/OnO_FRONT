import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ono/Model/ProblemModel.dart';
import 'package:ono/Model/ProblemRegisterModelV2.dart';
import 'package:ono/Model/TemplateType.dart';
import 'package:provider/provider.dart';

import '../../../GlobalModule/Image/DisplayImage.dart';
import '../../../GlobalModule/Theme/StandardText.dart';
import '../../../GlobalModule/Theme/ThemeHandler.dart';
import '../../../GlobalModule/Util/FolderSelectionDialog.dart';
import '../../ProblemManagement/DirectoryScreen.dart';
import '../ProblemRegisterScreenWidget.dart';
import '../../../Service/ScreenUtil/ProblemRegisterScreenService.dart';

class SimpleProblemRegisterTemplate extends StatefulWidget {
  final ProblemModel problemModel;
  final bool isEditMode;

  const SimpleProblemRegisterTemplate({required this.problemModel, required this.isEditMode, super.key});

  @override
  _SimpleTemplate createState() => _SimpleTemplate();
}

class _SimpleTemplate extends State<SimpleProblemRegisterTemplate> {
  late ProblemModel problemModel;
  late TextEditingController sourceController;
  late TextEditingController notesController;
  XFile? answerImage;
  final _service = ProblemRegisterScreenService();

  DateTime _selectedDate = DateTime.now();
  int? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    problemModel = widget.problemModel;
    sourceController = TextEditingController(text: problemModel.reference);
    notesController = TextEditingController(text: problemModel.memo);
    _selectedDate = problemModel.solvedAt ?? DateTime.now();
    _selectedFolderId = problemModel.folderId;
  }

  @override
  void dispose() {
    sourceController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Picker Widget
              ProblemRegisterScreenWidget.dateSelection(
                context: context,
                selectedDate: _selectedDate,
                onDateChanged: (newDate) {
                  setState(() {
                    _selectedDate = newDate;
                  });
                },
                themeProvider: themeProvider,
              ),
              const SizedBox(height: 30),

              ProblemRegisterScreenWidget.folderSelection(
                selectedFolderId: _selectedFolderId,
                onFolderSelected: () async {
                  FirebaseAnalytics.instance.logEvent(
                    name: 'problem_register_folder_select',
                  );

                  final selectedFolderId = await showDialog<int>(
                    context: context,
                    builder: (BuildContext context) => FolderSelectionDialog(
                      initialFolderId: _selectedFolderId,
                    ),
                  );

                  if (selectedFolderId != null) {
                    setState(() {
                      _selectedFolderId = selectedFolderId;
                    });
                  }
                },
                themeProvider: themeProvider,
              ),
              const SizedBox(height: 30),

              ProblemRegisterScreenWidget.buildLabeledField(
                label: "출처",
                themeProvider: themeProvider,
                icon: Icons.info, // Custom icon
                child: ProblemRegisterScreenWidget.textField(
                  controller: sourceController,
                  hintText: '문제집, 페이지, 문제번호 등 문제의 출처를 작성해주세요!',
                  themeProvider: themeProvider,
                ),
              ),
              const SizedBox(height: 30),

              ProblemRegisterScreenWidget.buildLabeledField(
                label: "메모",
                themeProvider: themeProvider,
                icon: Icons.edit, // Custom icon
                child: ProblemRegisterScreenWidget.textField(
                  controller: notesController,
                  hintText: '기록하고 싶은 내용을 간단하게 작성해주세요!',
                  themeProvider: themeProvider,
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 30),

              // Display problem image with label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.image, color: themeProvider.primaryColor),
                      const SizedBox(width: 10),
                      StandardText(text: '문제 이미지', fontSize: 16, color: themeProvider.primaryColor,),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DisplayImage(imagePath: problemModel.problemImageUrl),
                ],
              ),
              const SizedBox(height: 30),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.camera_alt, color: themeProvider.primaryColor),
                      const SizedBox(width: 10),
                      StandardText(text: '해설 이미지', fontSize: 16, color: themeProvider.primaryColor,),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Use the buildImagePicker widget to handle image picking
                  ProblemRegisterScreenWidget.buildImagePicker(
                    context: context,
                    image: answerImage,
                    existingImageUrl: problemModel.answerImageUrl,
                    onImagePicked: (XFile? pickedFile) {
                      setState(() {
                        answerImage = pickedFile;
                      });

                      FirebaseAnalytics.instance.logEvent(name: 'image_add', parameters: {
                        'type': 'answer_image',
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              ProblemRegisterScreenWidget.buildActionButtons(
                themeProvider: themeProvider,
                onSubmit: _submitProblem,
                onCancel: _resetFields,
                isEditMode: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetFields() {

    FirebaseAnalytics.instance.logEvent(
      name: 'problem_register_cancel_button_click',
    );

    setState(() {
      sourceController.clear();
      notesController.clear();
      answerImage = null; // 선택된 이미지 초기화
    });
  }

  void _submitProblem() {

    FirebaseAnalytics.instance.logEvent(
      name: 'problem_register_complete_button_click',
    );

    final problemRegisterModel = ProblemRegisterModelV2(
      problemId: problemModel.problemId,
      problemImageUrl: problemModel.problemImageUrl,
      answerImage: answerImage,
      memo: notesController.text,
      reference: sourceController.text,
      templateType: TemplateType.simple,
      solvedAt: _selectedDate,
      folderId: _selectedFolderId,
    );

    _service.submitProblemV2(
      context,
      problemRegisterModel,
          () {
        _resetFields(); // 성공 시 호출할 함수
        Navigator.of(context).pop(true);
      },
    );
  }
}
