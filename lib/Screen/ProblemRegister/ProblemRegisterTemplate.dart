import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Image/DisplayImage.dart';
import '../../GlobalModule/Theme/LoadingDialog.dart';
import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../GlobalModule/Util/FolderSelectionDialog.dart';
import '../../GlobalModule/Util/LatexTextHandler.dart';
import '../../Model/ProblemModel.dart';
import '../../Model/ProblemRegisterModelV2.dart';
import '../../Model/TemplateType.dart';
import '../../Provider/FoldersProvider.dart';
import '../../Provider/ScreenIndexProvider.dart';
import '../../Service/ScreenUtil/ProblemRegisterScreenService.dart';
import 'ProblemRegisterScreenWidget.dart';

class ProblemRegisterTemplate extends StatefulWidget {
  final ProblemModel problemModel;
  final List<Map<String, int>?>? colors;
  final bool isEditMode;
  final TemplateType templateType;

  const ProblemRegisterTemplate({
    required this.problemModel,
    required this.colors,
    required this.isEditMode,
    required this.templateType,
    super.key,
  });

  @override
  _ProblemRegisterTemplateState createState() =>
      _ProblemRegisterTemplateState();
}

class _ProblemRegisterTemplateState
    extends State<ProblemRegisterTemplate> {
  late ProblemModel problemModel;
  late TextEditingController sourceController;
  late TextEditingController notesController;
  XFile? answerImage;
  final _service = ProblemRegisterScreenService();

  String? processImageUrl;
  String? analysisResult;
  bool isLoading = false;
  DateTime _selectedDate = DateTime.now();
  int? _selectedFolderId;
  String? _selectedFolderName;

  final ScrollController scrollControllerForPage = ScrollController();
  final ScrollController scrollControllerForAnalysis = ScrollController();

  @override
  void initState() {
    super.initState();
    problemModel = widget.problemModel;
    sourceController = TextEditingController(text: problemModel.reference);
    notesController = TextEditingController(text: problemModel.memo);
    _selectedDate = problemModel.solvedAt ?? DateTime.now();
    _selectedFolderId = problemModel.folderId;
    _selectedFolderName = null;

    _fetchData();
  }

  @override
  void dispose() {
    scrollControllerForPage.dispose();
    scrollControllerForAnalysis.dispose();
    sourceController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if(widget.isEditMode){
      processImageUrl = problemModel.processImageUrl;
      analysisResult = problemModel.analysis;
    } else{
      setState(() {
        isLoading = true;
      });

      if (widget.templateType != TemplateType.simple) {
        final provider = Provider.of<FoldersProvider>(context, listen: false);

        // Fetch processImageUrl and analysis based on the template type
        processImageUrl = await provider.fetchProcessImageUrl(
            problemModel.problemImageUrl, widget.colors);

        if (widget.templateType == TemplateType.special) {
          analysisResult =
          await provider.fetchAnalysisResult(problemModel.problemImageUrl);
        }
      }
    }

    setState(() {
      isLoading = false;
    });
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
                label: "출처",
                themeProvider: themeProvider,
                icon: Icons.info,
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
                icon: Icons.edit,
                child: ProblemRegisterScreenWidget.textField(
                  controller: notesController,
                  hintText: '기록하고 싶은 내용을 간단하게 작성해주세요!',
                  themeProvider: themeProvider,
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 30),
              if (screenWidth >= 600 &&
                  widget.templateType != TemplateType.simple)
                _buildSpecialWideScreenLayout(
                    themeProvider, screenWidth, widget.templateType)
              else if (screenWidth >= 600)
                _buildSimpleWideScreenLayout(themeProvider, screenWidth)
              else
                _buildNarrowScreenLayout(themeProvider, widget.templateType),
              const SizedBox(height: 30),
              ProblemRegisterScreenWidget.buildActionButtons(
                themeProvider: themeProvider,
                onSubmit: _submitProblem,
                onCancel: _resetFields,
                isEditMode: widget.isEditMode,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialWideScreenLayout(ThemeHandler themeProvider,
      double screenWidth, TemplateType templateType) {

    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (templateType == TemplateType.special) ...[
          _buildAnalysisSection(
            analysisResult: analysisResult,
            themeProvider: themeProvider,
            maxHeight: screenHeight * 0.33,
          ),
          const SizedBox(height: 30),
        ],

        // 문제 원본 이미지와 보정 이미지 (한 줄에 두 개)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: _buildImageSection(
                label: '문제 이미지',
                imageUrl: problemModel.problemImageUrl,
                themeProvider: themeProvider,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.play_arrow_sharp, size: 30, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: _buildImageSection(
                label: '필기 제거 이미지',
                imageUrl: processImageUrl,
                themeProvider: themeProvider,
                isLoading: isLoading,
                loadingMessage: '필기 제거 중....'
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),

        // 정답 이미지와 해설 이미지 (한 줄에 두 개)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: ProblemRegisterScreenWidget.buildImagePickerWithLabel(
                context: context,
                label: '정답 이미지',
                image: answerImage,
                existingImageUrl: problemModel.answerImageUrl,
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
            const SizedBox(width: 10),
          ],
        ),
      ],
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
              child: _buildImageSection(
                label: '문제 이미지',
                imageUrl: problemModel.problemImageUrl,
                themeProvider: themeProvider,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: ProblemRegisterScreenWidget.buildImagePickerWithLabel(
                context: context,
                label: '정답 이미지',
                image: answerImage,
                existingImageUrl: problemModel.answerImageUrl,
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

  Widget _buildNarrowScreenLayout(ThemeHandler themeProvider, TemplateType templateType) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (templateType == TemplateType.special) ...[
          _buildAnalysisSection(
            analysisResult: analysisResult,
            themeProvider: themeProvider,
            maxHeight: screenHeight * 0.33,
          ),
          const SizedBox(height: 30),
        ],
        _buildImageSection(
          label: '문제 이미지',
          imageUrl: problemModel.problemImageUrl,
          themeProvider: themeProvider,
        ),
        const SizedBox(height: 30),
        if(widget.templateType != TemplateType.simple) ... [
          _buildImageSection(
              label: '필기 제거 이미지',
              imageUrl: processImageUrl,
              themeProvider: themeProvider,
              isLoading: isLoading,
              loadingMessage: '필기 제거 중....'
          ),
          const SizedBox(height: 30),
        ],
        ProblemRegisterScreenWidget.buildImagePickerWithLabel(
          context: context,
          label: '정답 이미지',
          image: answerImage,
          existingImageUrl: problemModel.answerImageUrl,
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
                const SizedBox(height: 30),
                CircularProgressIndicator(
                  color: themeProvider.primaryColor,
                ),
                const SizedBox(height: 30),
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

  Widget _buildAnalysisSection({
    required String? analysisResult,
    required ThemeHandler themeProvider,
    required double maxHeight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: themeProvider.primaryColor),
            const SizedBox(width: 10),
            StandardText(
              text: '문제 분석 결과',
              fontSize: 16,
              color: themeProvider.primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
            minHeight: 200, // 최소 높이를 지정해서 크기를 고정
          ),
          width: double.infinity,
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: themeProvider.primaryColor,
              width: 2.0,
            ),
          ),
          child: isLoading
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                CircularProgressIndicator(
                  color: themeProvider.primaryColor,
                ),
                const SizedBox(height: 20),
                StandardText(
                  text: '문제 분석 중...',
                  fontSize: 16,
                  color: themeProvider.primaryColor,
                ),
                const SizedBox(height: 10),
              ],
            ),
          )
              : analysisResult != null
              ? Scrollbar(
            controller: scrollControllerForAnalysis,
            thumbVisibility: true,
            thickness: 6.0,
            radius: const Radius.circular(10),
            child: SingleChildScrollView(
              controller: scrollControllerForAnalysis,
              scrollDirection: Axis.vertical,
              child: TeXView(
                fonts: const [
                  TeXViewFont(
                    fontFamily: 'HandWrite',
                    src: 'assets/fonts/HandWrite.ttf',
                  ),
                ],
                renderingEngine: const TeXViewRenderingEngine.mathjax(),
                child: LatexTextHandler.renderLatex(analysisResult!),
                style: const TeXViewStyle(
                  elevation: 5,
                  borderRadius: TeXViewBorderRadius.all(10),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          )
              : StandardText(
            text: "분석 결과가 없습니다.",
            color: themeProvider.primaryColor,
            fontSize: 16,
          ),
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
      answerImage = null;
      //solveImage = null;
    });
  }

  Future<void> _waitForLoadingToComplete() async {
    while (isLoading) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _submitProblem() {
    FirebaseAnalytics.instance.logEvent(
      name: 'problem_register_complete_button_click',
    );

    LoadingDialog.show(context, '오답노트 작성 중...');

    _waitForLoadingToComplete().then((_) {
      final problemRegisterModel = ProblemRegisterModelV2(
        problemId: problemModel.problemId,
        problemImageUrl: problemModel.problemImageUrl,
        processImageUrl: processImageUrl,
        answerImage: answerImage,
        memo: notesController.text,
        reference: sourceController.text,
        analysis: analysisResult,
        templateType: widget.templateType,
        solvedAt: _selectedDate,
        folderId: _selectedFolderId,
      );

      _service.submitProblemV2(
        context,
        problemRegisterModel,
        () {
          _resetFields();
          LoadingDialog.hide(context);
          Navigator.of(context).pop(true);

          Provider.of<ScreenIndexProvider>(context, listen: false)
              .setSelectedIndex(0);
        },
      );
    });
  }
}
