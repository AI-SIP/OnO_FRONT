import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../GlobalModule/Image/DisplayImage.dart';
import '../GlobalModule/Theme/DecorateText.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../Model/ProblemModel.dart';
import '../Model/ProblemRegisterModel.dart';
import '../Provider/FoldersProvider.dart';
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
  int? _selectedFolderId;
  String _selectedFolderName = '메인';
  late TextEditingController _sourceController;
  late TextEditingController _notesController;

  XFile? _problemImage;
  XFile? _answerImage;
  XFile? _solveImage;
  List<Map<String, int>?>? _selectedColors;

  @override
  void initState() {
    super.initState();

    final foldersProvider = Provider.of<FoldersProvider>(context, listen: false);

    if (foldersProvider.currentFolder != null) {
      _selectedFolderId = foldersProvider.currentFolder!.folderId;
      _selectedFolderName = foldersProvider.currentFolder!.folderName;
    } else {
      _selectedFolderId = null;
      _selectedFolderName = '메인'; // 기본값 설정
    }

    if (widget.problem != null) {
      _selectedDate = widget.problem!.solvedAt ?? DateTime.now();
      _sourceController =
          TextEditingController(text: widget.problem!.reference);
      _notesController = TextEditingController(text: widget.problem!.memo);
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
                _buildDatePickerSection(themeProvider),
                const SizedBox(height: 20),
                _buildFolderSelection(themeProvider),
                const SizedBox(height: 20),
                buildSection(
                  '출처',
                  Icons.info,
                  _buildStyledTextField(
                    _sourceController,
                    '문제집, 페이지, 문제번호 등 문제의 출처를 작성해주세요!',
                    themeProvider,
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
                  _buildStyledTextField(
                    _notesController,
                    '기록하고 싶은 내용을 간단하게 작성해주세요!',
                    themeProvider,
                    maxLines: 3,
                  ),
                ),
                _buildActionButtons(themeProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 문제 푼 날짜 선택 UI
  Widget _buildDatePickerSection(ThemeHandler themeProvider) {
    return Row(
      children: <Widget>[
        Icon(Icons.calendar_today, color: themeProvider.primaryColor),
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
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            foregroundColor: themeProvider.primaryColor,
            backgroundColor: themeProvider.primaryColor.withOpacity(0.1),
            side: BorderSide(
              color: themeProvider.primaryColor,
              width: 2.0, // 테두리 두께
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: DecorateText(
            text:
                '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
            fontSize: 18,
            color: themeProvider.primaryColor,
          ),
        ),
      ],
    );
  }

  // 폴더 선택 UI
  Widget _buildFolderSelection(ThemeHandler themeProvider) {
    return Row(
      children: [
        Icon(Icons.folder, color: themeProvider.primaryColor),
        const SizedBox(width: 10),
        DecorateText(
          text: '저장 폴더',
          fontSize: 20,
          color: themeProvider.primaryColor,
        ),
        const Spacer(),
        TextButton(
          onPressed: () async {
            await _showFolderSelectionModal(context);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            backgroundColor: themeProvider.primaryColor.withOpacity(0.1), // 배경색을 은은하게 설정
            side: BorderSide(
              color: themeProvider.primaryColor,
              width: 2.0, // 테두리 두께
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                constraints: const BoxConstraints(
                  maxWidth: 150, // 최대 너비 설정
                ),
                child: Text(
                  _selectedFolderName ?? '폴더 선택',
                  style: TextStyle(
                    fontFamily: 'font1',
                    fontSize: 18,
                    color: themeProvider.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis, // 길어지면 말줄임표 적용
                  maxLines: 1, // 한 줄로 표시
                  softWrap: false, // 말 줄임표 적용 시 줄바꿈 방지
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showFolderSelectionModal(BuildContext context) async {
    final result = await _service.showFolderSelectionModal(context);

    if (result != null) {
      setState(() {
        _selectedFolderId = result['folderId']; // 폴더 ID 저장
        _selectedFolderName = result['folderName']; // 폴더 이름 저장
      });
    }
  }

  // 이미지 선택 UI
  Widget buildImagePicker(
      String imageType, XFile? image, String? existingImageUrl) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withOpacity(0.1),
        border: Border.all(color: themeProvider.primaryColor, width: 2.0),
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
                      ),
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

  // 텍스트 필드 생성 공통 함수
  Widget _buildStyledTextField(
    TextEditingController controller,
    String hintText,
    ThemeHandler themeProvider, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
        fontFamily: 'font1',
        color: themeProvider.primaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      decoration: _buildInputDecoration(hintText, themeProvider),
      maxLines: maxLines,
    );
  }

  // InputDecoration 공통 설정 함수
  InputDecoration _buildInputDecoration(
      String hintText, ThemeHandler themeProvider) {
    return InputDecoration(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: themeProvider.primaryColor, width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: themeProvider.primaryColor, width: 2.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: themeProvider.primaryColor, width: 2.0),
      ),
      fillColor: themeProvider.primaryColor.withOpacity(0.1),
      filled: true,
      hintText: hintText,
      hintStyle: TextStyle(
        fontFamily: 'font1',
        color: themeProvider.primaryColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // 버튼 UI 생성 함수
  Row _buildActionButtons(ThemeHandler themeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        TextButton(
          onPressed: _resetFields,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
            backgroundColor: themeProvider.primaryColor.withOpacity(0.3),
            foregroundColor: themeProvider.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0), // 둥글기 조정
            ),
          ),
          child: DecorateText(
            text: widget.problem == null ? '등록 취소' : '수정 취소',
            fontSize: 20,
            color: themeProvider.primaryColor,
          ),
        ),
        TextButton(
          onPressed: _submitProblem,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
            backgroundColor: themeProvider.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0), // 둥글기 조정
            ),
          ),
          child: DecorateText(
            text: widget.problem == null ? '등록 완료' : '수정 완료',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // 공통 UI 빌더 함수
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

  // 이미지 선택 핸들러
  void _onImagePicked(XFile? pickedFile,
      List<Map<String, int>?>? selectedColors, String imageType) {
    setState(() {
      if (pickedFile != null) { // 이미지 선택이 성공했을 때만 값을 업데이트
        if (imageType == 'problemImage') {
          _problemImage = pickedFile;
          _selectedColors = selectedColors;
        } else if (imageType == 'answerImage') {
          _answerImage = pickedFile;
        } else if (imageType == 'solveImage') {
          _solveImage = pickedFile;
        }
      }
    });
  }

  // 문제 등록 및 수정 제출
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
        folderId: _selectedFolderId,
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
        folderId: _selectedFolderId,
        problemImage: _problemImage,
        answerImage: _answerImage,
        solveImage: _solveImage,
        colors: _selectedColors,
      );

      _service.updateProblem(context, updatedProblem, () {
        Navigator.of(context)
            .pop(true); // Return to the previous screen after editing
      });
    }
  }
}
