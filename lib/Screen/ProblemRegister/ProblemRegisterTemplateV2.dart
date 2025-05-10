import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModelWithTemplate.dart';
import '../../Model/Problem/ProblemRegisterModel.dart';
import '../../Module/Dialog/FolderSelectionDialog.dart';
import '../../Module/Dialog/LoadingDialog.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/FoldersProvider.dart';
import '../../Provider/ScreenIndexProvider.dart';
import '../../Screen/ScreenUtil/ProblemRegisterScreenService.dart';
import 'ProblemRegisterScreenWidget.dart';

class ProblemRegisterTemplateV2 extends StatefulWidget {
  final ProblemModelWithTemplate? problemModel;
  final bool isEditMode;

  const ProblemRegisterTemplateV2({
    required this.problemModel,
    required this.isEditMode,
    super.key,
  });

  @override
  _ProblemRegisterTemplateStateV2 createState() =>
      _ProblemRegisterTemplateStateV2();
}

class _ProblemRegisterTemplateStateV2 extends State<ProblemRegisterTemplateV2> {
  late ProblemModelWithTemplate? problemModel;
  late TextEditingController sourceController;
  late TextEditingController notesController;

  XFile? problemImage;
  XFile? answerImage;
  final _service = ProblemRegisterScreenService();

  String? analysisResult;
  bool isLoading = false;
  bool isAnalysisLoading = false;
  DateTime _selectedDate = DateTime.now();
  int? _selectedFolderId;
  String? _selectedFolderName;

  final ScrollController scrollControllerForPage = ScrollController();
  final ScrollController scrollControllerForAnalysis = ScrollController();

  @override
  void initState() {
    super.initState();
    problemModel = widget.problemModel;
    sourceController = TextEditingController(text: problemModel?.reference);
    notesController = TextEditingController(text: problemModel?.memo);
    _selectedDate = problemModel?.solvedAt ?? DateTime.now();

    if (widget.isEditMode) {
      _selectedFolderId = problemModel?.folderId;
    } else {
      final folderProvider =
          Provider.of<FoldersProvider>(context, listen: false);
      _selectedFolderId = folderProvider.currentFolder?.folderId ?? 1;
    }

    _selectedFolderName = '책장';
  }

  @override
  void dispose() {
    scrollControllerForPage.dispose();
    scrollControllerForAnalysis.dispose();
    sourceController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          controller: scrollControllerForPage,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      _selectedFolderName =
                          FolderSelectionDialog.getFolderNameByFolderId(
                              selectedFolderId);

                      if (sourceController.text.isEmpty) {
                        sourceController.text = '$_selectedFolderName ';
                      }
                    });
                  }
                },
                themeProvider: themeProvider,
              ),
              const SizedBox(height: 30),
              ProblemRegisterScreenWidget.buildLabeledField(
                label: "제목",
                themeProvider: themeProvider,
                icon: Icons.info,
                child: ProblemRegisterScreenWidget.textField(
                  controller: sourceController,
                  hintText: '오답노트의 제목을 작성해주세요!',
                  themeProvider: themeProvider,
                ),
              ),
              const SizedBox(height: 30),
              ProblemRegisterScreenWidget.buildLabeledField(
                label: "메모",
                themeProvider: themeProvider,
                icon: Icons.edit,
                child: ProblemRegisterScreenWidget.textField(
                  controller: notesController,
                  hintText: '기록하고 싶은 내용을 간단하게 작성해주세요!',
                  themeProvider: themeProvider,
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 30),
              if (screenWidth >= 600)
                _buildSimpleWideScreenLayout(themeProvider, screenWidth)
              else
                _buildNarrowScreenLayout(themeProvider),
              const SizedBox(height: 30),
              ProblemRegisterScreenWidget.buildActionButtons(
                context: context,
                themeProvider: themeProvider,
                onSubmit: _submitProblem,
                onCancel: _resetFields,
                isEditMode: widget.isEditMode,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleWideScreenLayout(
      ThemeHandler themeProvider, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: ProblemRegisterScreenWidget.buildImagePickerWithLabel(
                context: context,
                label: '문제 이미지',
                image: problemImage,
                existingImageUrl: problemModel?.problemImageUrl,
                themeProvider: themeProvider,
                onImagePicked: (XFile? pickedFile) {
                  setState(() {
                    problemImage = pickedFile;
                  });
                  FirebaseAnalytics.instance.logEvent(
                    name: 'image_add_problem_image',
                    parameters: {'type': 'problem_image'},
                  );
                },
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              flex: 1,
              child: ProblemRegisterScreenWidget.buildImagePickerWithLabel(
                context: context,
                label: '해설 이미지',
                image: answerImage,
                existingImageUrl: problemModel?.answerImageUrl,
                themeProvider: themeProvider,
                onImagePicked: (XFile? pickedFile) {
                  setState(() {
                    answerImage = pickedFile;
                  });
                  FirebaseAnalytics.instance.logEvent(
                    name: 'image_add_answer_image',
                    parameters: {'type': 'answer_image'},
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNarrowScreenLayout(ThemeHandler themeProvider) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProblemRegisterScreenWidget.buildImagePickerWithLabel(
          context: context,
          label: '문제 이미지',
          image: problemImage,
          existingImageUrl: problemModel?.problemImageUrl,
          themeProvider: themeProvider,
          onImagePicked: (XFile? pickedFile) {
            setState(() {
              problemImage = pickedFile;
            });

            FirebaseAnalytics.instance.logEvent(
              name: 'image_add_problem_image',
              parameters: {'type': 'problem_image'},
            );
          },
        ),
        const SizedBox(height: 30),
        ProblemRegisterScreenWidget.buildImagePickerWithLabel(
          context: context,
          label: '해설 이미지',
          image: answerImage,
          existingImageUrl: problemModel?.answerImageUrl,
          themeProvider: themeProvider,
          onImagePicked: (XFile? pickedFile) {
            setState(() {
              answerImage = pickedFile;
            });

            FirebaseAnalytics.instance.logEvent(
              name: 'image_add_answer_image',
              parameters: {'type': 'answer_image'},
            );
          },
        ),
      ],
    );
  }

  void _resetFields() {
    FirebaseAnalytics.instance.logEvent(
      name: 'problem_register_cancel_button_click',
    );

    setState(() {
      sourceController.clear();
      notesController.clear();

      problemImage = null;
      answerImage = null;
    });
  }

  void _submitProblem() {
    FirebaseAnalytics.instance.logEvent(
      name: 'problem_register_complete_button_click',
    );

    LoadingDialog.show(context, '오답노트 작성 중...');

    final problemRegisterModel = ProblemRegisterModelV2(
      problemId: problemModel?.problemId,
      problemImage: problemImage,
      answerImage: answerImage,
      memo: notesController.text,
      reference: sourceController.text,
      solvedAt: _selectedDate,
      folderId: _selectedFolderId,
    );

    _service.submitProblemV2(
      context,
      problemRegisterModel,
      () {
        _resetFields();
        LoadingDialog.hide(context);

        if (widget.isEditMode) {
          Navigator.of(context).pop(true);
        } else {
          Provider.of<ScreenIndexProvider>(context, listen: false)
              .setSelectedIndex(0);
        }
      },
    );
  }
}
