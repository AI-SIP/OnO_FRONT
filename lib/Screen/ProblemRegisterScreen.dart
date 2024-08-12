import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../GlobalModule/Theme/DecorateText.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../Service/ScreenUtil/ProblemRegisterScreenService.dart';

class ProblemRegisterScreen extends StatefulWidget {
  const ProblemRegisterScreen({super.key});

  @override
  ProblemRegisterScreenState createState() => ProblemRegisterScreenState();
}

class ProblemRegisterScreenState extends State<ProblemRegisterScreen> {
  final _service = ProblemRegisterScreenService();
  DateTime _selectedDate = DateTime.now(); // 선택된 날짜를 저장하는 변수
  final _sourceController = TextEditingController(); // 출처 입력 컨트롤러
  final _notesController = TextEditingController(); // 오답 메모 입력 컨트롤러

  XFile? _problemImage; // 문제 이미지 변수
  XFile? _answerImage; // 해설 이미지 변수
  XFile? _solveImage; // 나의 풀이 이미지 변수

  @override
  void dispose() {
    _sourceController.dispose(); // 출처 컨트롤러 해제
    _notesController.dispose(); // 오답 메모 컨트롤러 해제
    super.dispose();
  }

  // Build a section of the form with an icon, text, and a TextField or image
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

  // Build a container with an image picker button or a selected image
  Widget buildImagePicker(String imageType, XFile? image) {
    final mediaQuery = MediaQuery.of(context); // 미디어 쿼리 정보 가져오기
    final isLandscape =
        mediaQuery.orientation == Orientation.landscape; // 가로/세로 방향 확인
    final themeProvider = Provider.of<ThemeHandler>(context);
    return Container(
      height: isLandscape ? mediaQuery.size.height * 0.3 : 200,
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withOpacity(0.1),
        border: Border.all(
          color: themeProvider.primaryColor, // 테두리 색상
          width: 2.0, // 테두리 두께
        ),
      ),
      child: Center(
        child: image == null
            ? Column(
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

  // 이미지 선택 결과를 처리하는 함수
  void _onImagePicked(XFile? pickedFile, String imageType) {
    setState(() {
      if (imageType == 'problemImage') {
        _problemImage = pickedFile;
      } else if (imageType == 'answerImage') {
        _answerImage = pickedFile;
      } else if (imageType == 'solveImage') {
        _solveImage = pickedFile;
      }
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
                          color: themeProvider.primaryColor, // 테두리 색상 설정
                          width: 2.0, // 테두리 두께 설정
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              themeProvider.primaryColor, // 활성화된 상태의 테두리 색상 설정
                          width: 2.0, // 테두리 두께 설정
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              themeProvider.primaryColor, // 포커스된 상태의 테두리 색상 설정
                          width: 2.0, // 테두리 두께 설정
                        ),
                      ),
                      fillColor: themeProvider.primaryColor.withOpacity(0.1),
                      filled: true,
                      hintText: '문제집, 페이지, 문제번호 등 문제의 출처를 작성해주세요!',
                      hintStyle: TextStyle(
                          fontFamily: 'font1',
                          color: themeProvider.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // 문제 이미지 추가
                buildSection(
                  '문제',
                  Icons.camera_alt,
                  buildImagePicker('problemImage', _problemImage),
                ),
                // 해설 이미지 추가
                buildSection(
                  '해설',
                  Icons.camera_alt,
                  buildImagePicker('answerImage', _answerImage),
                ),
                // 나의 풀이 이미지 추가
                buildSection(
                  '나의 풀이',
                  Icons.camera_alt,
                  buildImagePicker('solveImage', _solveImage),
                ),
                // 오답 메모
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
                    textInputAction: TextInputAction.done, // 이 부분 추가
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: themeProvider.primaryColor, // 테두리 색상 설정
                          width: 2.0, // 테두리 두께 설정
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              themeProvider.primaryColor, // 활성화된 상태의 테두리 색상 설정
                          width: 2.0, // 테두리 두께 설정
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              themeProvider.primaryColor, // 포커스된 상태의 테두리 색상 설정
                          width: 2.0, // 테두리 두께 설정
                        ),
                      ),
                      fillColor: themeProvider.primaryColor
                          .withOpacity(0.1), // 내부 배경색 설정
                      filled: true,
                      hintText: '기록하고 싶은 내용을 간단하게 작성해주세요!',
                      hintStyle: TextStyle(
                          fontFamily: 'font1',
                          color: themeProvider.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    maxLines: 3,
                  ),
                ),
                // 등록 취소 및 완료 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () {
                        _sourceController.clear();
                        _notesController.clear();
                        setState(() {
                          _problemImage = null;
                          _answerImage = null;
                          _solveImage = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white54,
                        foregroundColor: themeProvider.primaryColor,
                      ),
                      child: DecorateText(
                        text: '등록 취소',
                        fontSize: 18,
                        color: themeProvider.primaryColor,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _service.submitProblem(
                        context,
                        _sourceController,
                        _notesController,
                        _problemImage,
                        _solveImage,
                        _answerImage,
                        _selectedDate,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const DecorateText(
                        text: '등록 완료',
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
