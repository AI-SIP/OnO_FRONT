import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Image/DisplayImage.dart';
import '../../GlobalModule/Theme/LoadingDialog.dart';
import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../GlobalModule/Util/FolderSelectionDialog.dart';
import '../../Model/ProblemModel.dart';
import '../../Model/ProblemRegisterModelV2.dart';
import '../../Provider/FoldersProvider.dart';
import '../../Provider/ScreenIndexProvider.dart';
import '../../Service/ScreenUtil/ProblemRegisterScreenService.dart';
import 'ProblemRegisterScreenWidget.dart';

class ProblemRegisterTemplateV2 extends StatefulWidget {
  final ProblemModel? problemModel;
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

class _ProblemRegisterTemplateStateV2
    extends State<ProblemRegisterTemplateV2> {
  late ProblemModel? problemModel;
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

    if(widget.isEditMode){
      _selectedFolderId = problemModel?.folderId;
    } else{
      final folderProvider = Provider.of<FoldersProvider>(context, listen: false);
      _selectedFolderId = folderProvider.currentFolder!.folderId;
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
                      _selectedFolderName = FolderSelectionDialog.getFolderNameByFolderId(selectedFolderId);

                      if(sourceController.text.isEmpty){
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

  Widget _buildImageSection({
    required String label,
    required String? imageUrl,
    required ThemeHandler themeProvider,
    bool isLoading = false,
    String loadingMessage = '이미지 로딩 중...', // 로딩 메시지를 받을 수 있도록 수정
  }) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image, color: themeProvider.primaryColor),
            const SizedBox(width: 10),
            StandardText(
              text: label,
              fontSize: 16,
              color: themeProvider.primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: screenHeight * 0.4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: themeProvider.primaryColor.withOpacity(0.1), // 흰색 배경 적용
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: themeProvider.primaryColor,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(10), // 이미지와 테두리 사이에 패딩 추가
          child: isLoading
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.03),
                SvgPicture.asset(
                  'assets/Icon/EraserDetail.svg', // Eraser 아이콘 경로
                  width: screenHeight * 0.1, // 적절한 크기 설정
                  height: screenHeight * 0.1,
                ),
                SizedBox(height: screenHeight * 0.02),
                StandardText(
                  text: loadingMessage, // 로딩 중 메시지 출력
                  fontSize: 16,
                  color: themeProvider.primaryColor,
                ),
              ],
            ),
          )
              : DisplayImage(imagePath: imageUrl ?? '', fit: BoxFit.contain,),
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

        Provider.of<ScreenIndexProvider>(context, listen: false)
            .setSelectedIndex(0);
      },
    );
  }
}
