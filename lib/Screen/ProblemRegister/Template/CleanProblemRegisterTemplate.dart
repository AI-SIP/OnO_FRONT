import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ono/GlobalModule/Theme/HandWriteText.dart';
import 'package:ono/Model/ProblemModel.dart';
import 'package:ono/Model/ProblemRegisterModelV2.dart';
import 'package:ono/Model/TemplateType.dart';
import 'package:ono/Screen/ProblemManagement/DirectoryScreen.dart';
import 'package:provider/provider.dart';
import '../../../GlobalModule/Image/DisplayImage.dart';
import '../../../GlobalModule/Theme/ThemeHandler.dart';
import '../../../GlobalModule/Util/FolderSelectionDialog.dart';
import '../ProblemRegisterScreenWidget.dart';
import '../../../Service/ScreenUtil/ProblemRegisterScreenService.dart';
import '../../../Provider/FoldersProvider.dart';

class CleanProblemRegisterTemplate extends StatefulWidget {
  final ProblemModel problemModel;
  final List<Map<String, int>?>? colors;

  const CleanProblemRegisterTemplate({required this.problemModel, required this.colors, Key? key})
      : super(key: key);

  @override
  _CleanProblemRegisterTemplateState createState() => _CleanProblemRegisterTemplateState();
}

class _CleanProblemRegisterTemplateState extends State<CleanProblemRegisterTemplate> {
  late ProblemModel problemModel;
  late TextEditingController sourceController;
  late TextEditingController notesController;
  XFile? answerImage;
  XFile? solveImage;
  final _service = ProblemRegisterScreenService();

  String? processImageUrl;
  bool isLoading = true;
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

    _fetchProcessImage();
  }

  @override
  void dispose() {
    sourceController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchProcessImage() async {
    final provider = Provider.of<FoldersProvider>(context, listen: false);

    processImageUrl = await provider.fetchProcessImageUrl(problemModel.problemImageUrl, widget.colors);

    setState(() {
      isLoading = false;
    });
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

              // Display problem image with label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.image, color: themeProvider.primaryColor),
                      const SizedBox(width: 10),
                      HandWriteText(text: '문제 이미지', fontSize: 20, color: themeProvider.primaryColor,),
                    ],
                  ),
                  const SizedBox(height: 5),
                  DisplayImage(imagePath: problemModel.problemImageUrl),
                ],
              ),
              const SizedBox(height: 30),

              // Display process image or loading message
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.image, color: themeProvider.primaryColor),
                      const SizedBox(width: 10),
                      HandWriteText(text: '보정된 이미지', fontSize: 20, color: themeProvider.primaryColor,),
                    ],
                  ),
                  const SizedBox(height: 5),
                  isLoading
                      ? Center(child: HandWriteText(text: '이미지 보정 중...', fontSize: 16, color: themeProvider.primaryColor,))
                      : DisplayImage(imagePath: processImageUrl ?? ''),
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
                      HandWriteText(text: '해설 이미지', fontSize: 20, color: themeProvider.primaryColor,),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Use the buildImagePicker widget to handle image picking
                  ProblemRegisterScreenWidget.buildImagePicker(
                    context: context,
                    image: answerImage,
                    existingImageUrl: problemModel.answerImageUrl,
                    onImagePicked: (XFile? pickedFile) {
                      setState(() {
                        answerImage = pickedFile;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.camera_alt, color: themeProvider.primaryColor),
                      const SizedBox(width: 10),
                      HandWriteText(text: '풀이 이미지', fontSize: 20, color: themeProvider.primaryColor,),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Use the buildImagePicker widget to handle image picking
                  ProblemRegisterScreenWidget.buildImagePicker(
                    context: context,
                    image: solveImage,
                    existingImageUrl: problemModel.solveImageUrl,
                    onImagePicked: (XFile? pickedFile) {
                      setState(() {
                        solveImage = pickedFile;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

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
    setState(() {
      sourceController.clear();
      notesController.clear();
      answerImage = null;
    });
  }

  Future<void> _waitForLoadingToComplete() async {
    while (isLoading) {
      // 500ms 마다 로딩 상태를 체크
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _submitProblem() {
    _service.showLoadingDialog(context);
    if (isLoading) {
      // isLoading이 false로 바뀌면 서버로 전송
      _waitForLoadingToComplete().then((_) {
        final problemRegisterModel = ProblemRegisterModelV2(
          problemId: problemModel.problemId,
          problemImageUrl: problemModel.problemImageUrl,
          processImageUrl: processImageUrl,
          answerImage: answerImage,
          solveImage: solveImage,
          memo: notesController.text == problemModel.memo
              ? null
              : notesController.text,
          reference: sourceController.text == problemModel.reference
              ? null
              : sourceController.text,
          templateType: TemplateType.special,
          solvedAt: _selectedDate,
          folderId: _selectedFolderId == problemModel.folderId
              ? null
              : _selectedFolderId,
        );

        _service.submitProblemV2(
          context,
          problemRegisterModel,
              () {
            _resetFields(); // 성공 시 호출할 함수
            _service.hideLoadingDialog(context);
            Navigator.of(context)
                .pop(true);
          },
        );
      });
    }
  }
}