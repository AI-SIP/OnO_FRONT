import 'package:firebase_analytics/firebase_analytics.dart';
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
  String _selectedFolderName = '폴더 선택';
  bool _isProcess = false;
  late TextEditingController _sourceController;
  late TextEditingController _notesController;

  XFile? _problemImage;
  XFile? _answerImage;
  XFile? _solveImage;
  List<Map<String, int>?>? _selectedColors;

  @override
  void initState() {
    super.initState();

    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);

    if (foldersProvider.currentFolder != null) {
      //_selectedFolderId = foldersProvider.currentFolder!.folderId;
      //_selectedFolderName = foldersProvider.currentFolder!.folderName;
    } else {
      _selectedFolderId = null;
      _selectedFolderName = '폴더 선택'; // 기본값 설정
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
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);

    _sourceController.clear();
    _notesController.clear();
    setState(() {
      _problemImage = null;
      _answerImage = null;
      _solveImage = null;
      _selectedColors = null;
      _selectedDate = DateTime.now();
      _selectedFolderId = null;
      _selectedFolderName = '폴더 선택';
      _isProcess = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // 이미지 항목을 한 줄에 몇 개 배치할지 결정 (가로 크기에 따라 다르게 설정)
    int crossAxisCount;
    if (screenWidth > 1100) {
      crossAxisCount = 3;  // 가로가 900 이상이면 3개
    } else if (screenWidth >= 600) {
      crossAxisCount = 2;  // 가로가 600에서 900 사이면 2개
    } else {
      crossAxisCount = 1;  // 가로가 600 이하이면 1개
    }

    double childAspectRatio;
    if(screenWidth > 1100){
      childAspectRatio = 0.7;
    } else if(screenWidth >= 600) {
      childAspectRatio = 0.8;
    } else{
      childAspectRatio = (screenWidth / (screenWidth / crossAxisCount) * 0.9);
    }

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
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
                GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,  // GridView가 다른 스크롤 뷰 안에 있으므로 shrinkWrap을 true로 설정
                  physics: const NeverScrollableScrollPhysics(),  // 스크롤을 금지하고 부모 스크롤뷰 사용
                  mainAxisSpacing: 0,  // 항목 간 세로 간격
                  crossAxisSpacing: 20.0,  // 항목 간 가로 간격
                  childAspectRatio: childAspectRatio,
                  children: [
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
                      buildImagePicker('solveImage', _solveImage,
                          widget.problem?.solveImageUrl),
                    ),
                  ],
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            backgroundColor:
                themeProvider.primaryColor.withOpacity(0.1), // 배경색을 은은하게 설정
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

    return Flexible(  // Flexible 또는 Expanded로 감싸서 크기 조정 가능하게 만듦
      child: Container(
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
                  context, _onImagePicked, imageType, _isProcess);
            },
            child: DisplayImage(imagePath: existingImageUrl),
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.image,
                    color: themeProvider.desaturateColor, size: 50),
                onPressed: () {
                  _service.showImagePicker(
                      context, _onImagePicked, imageType, _isProcess);
                },
              ),
              DecorateText(
                text: '아이콘을 눌러 이미지를 추가해주세요!',
                color: themeProvider.desaturateColor,
                fontSize: 16,
              ),
            ],
          )
              : GestureDetector(
            onTap: () {
              _service.showImagePicker(
                  context, _onImagePicked, imageType, _isProcess);
            },
            child: Image.file(File(image.path)),
          ),
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
        color: themeProvider.desaturateColor,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
            backgroundColor: themeProvider.primaryColor.withOpacity(0.3),
            foregroundColor: themeProvider.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0), // 둥글기 조정
            ),
          ),
          child: DecorateText(
            text: widget.problem == null ? '등록 취소' : '수정 취소',
            fontSize: 20,
            color : Colors.white,
          ),
        ),
        TextButton(
          onPressed: _submitProblem,
          style: ElevatedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
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
        SizedBox(
          height: 60, // 고정된 높이 설정 (적절한 높이로 수정 가능)
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양쪽 끝으로 배치
            children: <Widget>[
              Row(
                children: [
                  Icon(icon, color: themeProvider.primaryColor),
                  const SizedBox(width: 10),
                  DecorateText(
                    text: title,
                    fontSize: 20,
                    color: themeProvider.primaryColor,
                  ),
                ],
              ),
              // '문제' 섹션에서만 토글을 추가
              if (title == '문제')
                Row(
                  children: [
                    DecorateText(
                      text: '필기 제거 및 이미지 보정',
                      fontSize: 16,
                      color: themeProvider.primaryColor,
                    ),
                    Transform.scale(
                      scale: 0.6, // 스위치 크기 조정 (0.6배)
                      child: Switch(
                        value: _isProcess,
                        onChanged: (bool newValue) {
                          setState(() {
                            _isProcess = newValue;
                          });
                        },
                        activeColor: themeProvider.primaryColor,
                      ),
                    ),
                  ],
                )
              else
                // 문제 이미지가 아닌 경우 동일한 높이 확보를 위해 빈 위젯 추가
                const SizedBox(
                  width: 160, // 토글이 차지하는 공간만큼 너비를 설정
                ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        content,
        const SizedBox(height: 20),
      ],
    );
  }

  // 이미지 선택 핸들러
  void _onImagePicked(XFile? pickedFile,
      List<Map<String, int>?>? selectedColors, String imageType) {
    setState(() {
      if (pickedFile != null) {
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
        isProcess: _isProcess,
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
        isProcess: _isProcess,
        colors: _selectedColors,
      );

      _service.updateProblem(context, updatedProblem, () {
        Navigator.of(context)
            .pop(true); // Return to the previous screen after editing
      });
    }
  }
}
