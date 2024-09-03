import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../GlobalModule/Image/DisplayImage.dart';
import '../GlobalModule/Theme/DecorateText.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../Model/ProblemModel.dart';
import '../Model/ProblemRegisterModel.dart';
import '../Service/ScreenUtil/ProblemRegisterScreenService.dart';

class ProblemRegisterScreen extends StatefulWidget {
  final ProblemModel? problem;
  const ProblemRegisterScreen({super.key, this.problem});

  @override
  ProblemRegisterScreenState createState() => ProblemRegisterScreenState();
}

class ProblemRegisterScreenState extends State<ProblemRegisterScreen> {
  final _service = ProblemRegisterScreenService();
  late DateTime _selectedDate;
  late TextEditingController _sourceController;
  late TextEditingController _notesController;

  XFile? _problemImage;
  XFile? _answerImage;
  XFile? _solveImage;
  List<Map<String, int>?>? _selectedColors;

  @override
  void initState() {
    super.initState();

    if (widget.problem != null) {

      _selectedDate = widget.problem!.solvedAt ?? DateTime.now();
      _sourceController =
          TextEditingController(text: widget.problem!.reference);
      _notesController = TextEditingController(text: widget.problem!.memo);

      // Images are not set here, handled in the image picker
    } else {
      _selectedDate = DateTime.now();
      _sourceController = TextEditingController();
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _resetFields() {
    _sourceController.clear();
    _notesController.clear();
    setState(() {
      _problemImage = null;
      _answerImage = null;
      _solveImage = null;
      _selectedColors = null;
      _selectedDate = DateTime.now();
    });
  }

  Widget buildSection(String title, IconData icon, Widget content) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: <Widget>[
            Icon(icon, color: themeProvider.primaryColor),
            const SizedBox(width: 10),
            DecorateText(
              text: title,
              fontSize: 20,
              color: themeProvider.primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 10),
        content,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildImagePicker(
      String imageType, XFile? image, String? existingImageUrl) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withOpacity(0.1),
        border: Border.all(
          color: themeProvider.primaryColor,
          width: 2.0,
        ),
      ),
      child: Center(
        child: image == null
            ? existingImageUrl != null
                ? GestureDetector(
                    onTap: () {
                      _service.showImagePicker(
                          context, _onImagePicked, imageType);
                    },
                    child: DisplayImage(imagePath: existingImageUrl),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.image,
                            color: themeProvider.primaryColor, size: 50),
                        onPressed: () {
                          _service.showImagePicker(
                              context, _onImagePicked, imageType);
                        },
                      ),
                      DecorateText(
                        text: '아이콘을 눌러 이미지를 추가해주세요!',
                        color: themeProvider.primaryColor,
                        fontSize: 16,
                      )
                    ],
                  )
            : GestureDetector(
                onTap: () {
                  _service.showImagePicker(context, _onImagePicked, imageType);
                },
                child: Image.file(File(image.path)),
              ),
      ),
    );
  }

  void _onImagePicked(XFile? pickedFile, List<Map<String, int>?>? selectedColors, String imageType) {
    setState(() {
      if (imageType == 'problemImage') {
        _problemImage = pickedFile;
        _selectedColors = selectedColors;
        print('selectedColors : ${selectedColors}');
      } else if (imageType == 'answerImage') {
        _answerImage = pickedFile;
      } else if (imageType == 'solveImage') {
        _solveImage = pickedFile;
      }
    });
  }

  void _submitProblem() {
    if (widget.problem == null) {
      final problemData = ProblemRegisterModel(
        problemImage: _problemImage,
        solveImage: _solveImage,
        answerImage: _answerImage,
        memo: _notesController.text,
        reference: _sourceController.text,
        solvedAt: _selectedDate,
        colors: _selectedColors,
      );
      _service.submitProblem(
        context,
        problemData,
        _resetFields,
      );
    } else {
      final updatedProblem = ProblemRegisterModel(
        problemId: widget.problem!.problemId,
        reference: _sourceController.text == widget.problem!.reference
            ? null
            : _sourceController.text,
        memo: _notesController.text == widget.problem!.memo
            ? null
            : _notesController.text,
        solvedAt:
            _selectedDate == widget.problem!.solvedAt ? null : _selectedDate,
        problemImage: _problemImage,
        answerImage: _answerImage,
        solveImage: _solveImage,
        colors: _selectedColors,
      );

      _service.updateProblem(context, updatedProblem, () {
        Navigator.of(context).pop(true); // Return to the previous screen
      });
    }
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // 문제 푼 날짜 선택
                Row(
                  children: <Widget>[
                    Icon(Icons.calendar_today,
                        color: themeProvider.primaryColor),
                    const SizedBox(width: 10),
                    DecorateText(
                      text: '푼 날짜',
                      fontSize: 20,
                      color: themeProvider.primaryColor,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _service.showCustomDatePicker(
                        context,
                        _selectedDate,
                        (newDate) => setState(() {
                          _selectedDate = newDate;
                        }),
                      ),
                      child: DecorateText(
                        text:
                            '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                        fontSize: 18,
                        color: themeProvider.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 출처 입력
                buildSection(
                  '출처',
                  Icons.info,
                  TextField(
                    controller: _sourceController,
                    style: TextStyle(
                      fontFamily: 'font1',
                      color: themeProvider.primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: themeProvider.primaryColor,
                          width: 2.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: themeProvider.primaryColor,
                          width: 2.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: themeProvider.primaryColor,
                          width: 2.0,
                        ),
                      ),
                      fillColor: themeProvider.primaryColor.withOpacity(0.1),
                      filled: true,
                      hintText: '문제집, 페이지, 문제번호 등 문제의 출처를 작성해주세요!',
                      hintStyle: TextStyle(
                        fontFamily: 'font1',
                        color: themeProvider.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                buildSection(
                  '문제',
                  Icons.camera_alt,
                  buildImagePicker('problemImage', _problemImage,
                      widget.problem?.problemImageUrl),
                ),
                buildSection(
                  '해설',
                  Icons.camera_alt,
                  buildImagePicker('answerImage', _answerImage,
                      widget.problem?.answerImageUrl),
                ),
                buildSection(
                  '나의 풀이',
                  Icons.camera_alt,
                  buildImagePicker(
                      'solveImage', _solveImage, widget.problem?.solveImageUrl),
                ),
                buildSection(
                  '한 줄 메모',
                  Icons.edit,
                  TextField(
                    controller: _notesController,
                    style: TextStyle(
                      fontFamily: 'font1',
                      color: themeProvider.primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: themeProvider.primaryColor,
                          width: 2.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: themeProvider.primaryColor,
                          width: 2.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: themeProvider.primaryColor,
                          width: 2.0,
                        ),
                      ),
                      fillColor: themeProvider.primaryColor.withOpacity(0.1),
                      filled: true,
                      hintText: '기록하고 싶은 내용을 간단하게 작성해주세요!',
                      hintStyle: TextStyle(
                        fontFamily: 'font1',
                        color: themeProvider.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    maxLines: 3,
                  ),
                ),
                // 등록 취소 및 완료 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: _resetFields,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white54,
                        foregroundColor: themeProvider.primaryColor,
                      ),
                      child: DecorateText(
                        text: widget.problem == null
                            ? '등록 취소'
                            : '수정 취소',
                        fontSize: 18,
                        color: themeProvider.primaryColor,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _submitProblem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: DecorateText(
                        text: widget.problem == null
                            ? '등록 완료'
                            : '수정 완료',
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
