import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ono/Module/Image/ImagePickerHandler.dart';
import 'package:provider/provider.dart';

import '../../Model/Common/LoginStatus.dart';
import '../../Model/Common/ProblemImageDataType.dart';
import '../../Model/Problem/ProblemImageDataRegisterModel.dart';
import '../../Model/Problem/ProblemModel.dart';
import '../../Model/Problem/ProblemRegisterModel.dart';
import '../../Module/Dialog/FolderSelectionDialog.dart';
import '../../Module/Dialog/LoadingDialog.dart';
import '../../Module/Dialog/SnackBarDialog.dart';
import '../../Module/Text/HandWriteText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/FoldersProvider.dart';
import '../../Provider/ScreenIndexProvider.dart';
import '../../Provider/UserProvider.dart';
import '../../Service/Api/FileUpload/FileUploadService.dart';
import 'ProblemRegisterScreenWidget.dart';

class ProblemRegisterTemplate extends StatefulWidget {
  final ProblemModel? problemModel;
  final bool isEditMode;

  const ProblemRegisterTemplate({
    required this.problemModel,
    required this.isEditMode,
    super.key,
  });

  @override
  _ProblemRegisterTemplateState createState() =>
      _ProblemRegisterTemplateState();
}

class _ProblemRegisterTemplateState extends State<ProblemRegisterTemplate> {
  late ProblemModel? problemModel;
  late TextEditingController sourceController;
  late TextEditingController notesController;

  List<XFile> problemImages = [];
  List<XFile> answerImages = [];

  bool isLoading = false;
  DateTime _selectedDate = DateTime.now();
  int? _selectedFolderId;
  String? _selectedFolderName;

  final ScrollController scrollControllerForPage = ScrollController();

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
              const SizedBox(height: 25),
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
              const SizedBox(height: 25),
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
              const SizedBox(height: 25),
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
              const SizedBox(height: 40),
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
    final imagePicker = ImagePickerHandler();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: ProblemRegisterScreenWidget.buildImageGrid(
                files: problemImages,
                label: '문제 이미지',
                themeProvider: themeProvider,
                onAdd: () async {
                  imagePicker.showImagePicker(context, (XFile? file) {
                    if (file != null) {
                      setState(() => problemImages.add(file));
                    }
                  });
                },
                onRemove: (idx) => setState(() => problemImages.removeAt(idx)),
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              flex: 1,
              child: ProblemRegisterScreenWidget.buildImageGrid(
                files: answerImages,
                label: '해설 이미지',
                themeProvider: themeProvider,
                onAdd: () async {
                  imagePicker.showImagePicker(context, (XFile? file) {
                    if (file != null) {
                      setState(() => answerImages.add(file));
                    }
                  });
                },
                onRemove: (idx) => setState(() => answerImages.removeAt(idx)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNarrowScreenLayout(ThemeHandler themeProvider) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imagePicker = ImagePickerHandler();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProblemRegisterScreenWidget.buildImageGrid(
          files: problemImages,
          label: '문제 이미지',
          themeProvider: themeProvider,
          onAdd: () async {
            imagePicker.showImagePicker(context, (XFile? file) {
              if (file != null) {
                setState(() => problemImages.add(file));
              }
            });
          },
          onRemove: (idx) => setState(() => problemImages.removeAt(idx)),
        ),
        const SizedBox(height: 30),
        ProblemRegisterScreenWidget.buildImageGrid(
          files: answerImages,
          label: '해설 이미지',
          themeProvider: themeProvider,
          onAdd: () async {
            imagePicker.showImagePicker(context, (XFile? file) {
              if (file != null) {
                setState(() => answerImages.add(file));
              }
            });
          },
          onRemove: (idx) => setState(() => answerImages.removeAt(idx)),
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

      problemImages.clear();
      answerImages.clear();
    });
  }

  void registerImages() {}

  void _submitProblem() async {
    LoadingDialog.show(context, '오답노트 작성 중...');
    final fileService = FileUploadService();

    final problemUrls =
        await fileService.uploadMultipleImageFiles(problemImages);
    final answerUrls = await fileService.uploadMultipleImageFiles(answerImages);

    final now = DateTime.now();
    final imageDataList = <ProblemImageDataRegisterModel>[
      // 문제 이미지들
      for (var url in problemUrls)
        ProblemImageDataRegisterModel(
          imageUrl: url,
          problemImageType: ProblemImageType.PROBLEM_IMAGE,
          createdAt: now,
        ),
      // 해설 이미지들
      for (var url in answerUrls)
        ProblemImageDataRegisterModel(
          imageUrl: url,
          problemImageType: ProblemImageType.ANSWER_IMAGE,
          createdAt: now,
        ),
    ];

    final problemRegisterModel = ProblemRegisterModel(
      problemId: problemModel?.problemId,
      memo: notesController.text,
      reference: sourceController.text,
      solvedAt: _selectedDate,
      folderId: _selectedFolderId,
      imageDataDtoList: imageDataList,
    );

    submitProblem(
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

  void showSuccessDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    SnackBarDialog.showSnackBar(
        context: context,
        message: "오답노트가 성공적으로 저장되었습니다.",
        backgroundColor: themeProvider.primaryColor);
  }

  void showValidationMessage(BuildContext context, String message) {
    SnackBarDialog.showSnackBar(
        context: context,
        message: "오답노트 작성 과정에서 오류가 발생했습니다.",
        backgroundColor: Colors.red);
  }

  void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop(true);
  }

  Future<void> submitProblem(BuildContext context,
      ProblemRegisterModel problemData, VoidCallback onSuccess) async {
    final authService = Provider.of<UserProvider>(context, listen: false);
    if (authService.isLoggedIn == LoginStatus.logout) {
      _showLoginRequiredDialog(context);
      return;
    }

    try {
      await Provider.of<FoldersProvider>(context, listen: false)
          .submitProblem(problemData, context);
      onSuccess();
      showSuccessDialog(context);
    } catch (error) {
      hideLoadingDialog(context);
    }
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const HandWriteText(
          text: '로그인 필요',
        ),
        content: const HandWriteText(
          text: '오답노트를 작성하려면 로그인 해주세요!',
        ),
        actions: <Widget>[
          TextButton(
            child: const HandWriteText(
              text: '확인',
              fontSize: 20,
            ),
            onPressed: () {
              Navigator.of(ctx).pop(); // 다이얼로그 닫기
            },
          )
        ],
      ),
    );
  }
}
