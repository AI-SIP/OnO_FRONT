import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../GlobalModule/Theme/DecorateText.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../Provider/ProblemsProvider.dart';
import '../Model/ProblemRegisterModel.dart';
import '../GlobalModule/Util/DatePickerHandler.dart';
import '../GlobalModule/Image/ImagePickerHandler.dart';
import '../Service/AuthService.dart';

class ProblemRegisterScreen extends StatefulWidget {
  const ProblemRegisterScreen({super.key});

  @override
  ProblemRegisterScreenState createState() => ProblemRegisterScreenState();
}

class ProblemRegisterScreenState extends State<ProblemRegisterScreen> {
  DateTime _selectedDate = DateTime.now(); // 선택된 날짜를 저장하는 변수
  final _sourceController = TextEditingController(); // 출처 입력 컨트롤러
  final _notesController = TextEditingController(); // 오답 메모 입력 컨트롤러
  final ImagePickerHandler _imagePickerHandler =
      ImagePickerHandler(); // 이미지 선택기 핸들러 인스턴스

  XFile? _problemImage; // 문제 이미지 변수
  XFile? _answerImage; // 해설 이미지 변수
  XFile? _solveImage; // 나의 풀이 이미지 변수

  // 날짜 선택기를 표시하는 함수
  void _showCustomDatePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return DatePickerHandler(
          initialDate: _selectedDate,
          onDateSelected: (DateTime newDate) {
            setState(() {
              _selectedDate = newDate; // 선택된 날짜 업데이트
            });
          },
        );
      },
    );
  }

  // 이미지 선택 결과를 처리하는 함수
  void _onImagePicked(XFile? pickedFile, String imageType) {
    if (pickedFile != null) {
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
  }

  // 이미지 선택 팝업 호출 함수
  void _showImagePicker(String imageType) {
    _imagePickerHandler.showImagePicker(context, (pickedFile) {
      _onImagePicked(pickedFile, imageType);
    });
  }

  @override
  void dispose() {
    _sourceController.dispose(); // 출처 컨트롤러 해제
    _notesController.dispose(); // 오답 메모 컨트롤러 해제
    super.dispose();
  }

  void showSuccessDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: const DecorateText(
            text: '문제가 성공적으로 저장되었습니다.',
            fontSize: 20,
            color: Colors.white,
          ),
          backgroundColor: themeProvider.primaryColor),
    );
  }

  // 모든 입력 필드와 이미지 선택기를 초기화하는 함수
  void resetForm() {
    _sourceController.clear();
    _notesController.clear();
    setState(() {
      _problemImage = null;
      _answerImage = null;
      _solveImage = null;
    });
  }

  // 로딩 다이얼로그를 보여주는 함수
  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  // 로딩 다이얼로그를 닫는 함수
  void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop(true);
  }

  bool _isLogin(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isLoggedIn) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const DecorateText(text: '로그인 필요', fontSize: 24),
          content:
              const DecorateText(text: '문제를 등록하려면 로그인 해주세요!', fontSize: 20),
          actions: <Widget>[
            TextButton(
              child: const DecorateText(text: '확인', fontSize: 20),
              onPressed: () {
                Navigator.of(ctx).pop(); // 다이얼로그 닫기
              },
            )
          ],
        ),
      );
      return false;
    }
    return true;
  }

  // 필수 항목 확인 함수
  bool _validateForm() {
    if (_sourceController.text.isEmpty) {
      _showValidationMessage('출처는 필수 항목입니다.');
      return false;
    }
    if (_problemImage == null) {
      _showValidationMessage('문제 이미지는 필수 항목입니다.');
      return false;
    }
    return true;
  }

  // 경고 메시지 출력 함수
  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: DecorateText(
          text: message,
          fontSize: 20,
          color: Colors.white,
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> submitProblem() async {
    if (!_isLogin(context)) {
      return;
    }

    if (!_validateForm()) {
      return;
    }

    showLoadingDialog(context); // 로딩 다이얼로그 표시

    final problemData = ProblemRegisterModel(
      problemImage: _problemImage,
      solveImage: _answerImage,
      answerImage: _solveImage,
      memo: _notesController.text,
      reference: _sourceController.text,
      solvedAt: _selectedDate,
    );

    await Provider.of<ProblemsProvider>(context, listen: false)
        .submitProblem(problemData, context);

    hideLoadingDialog(context); // 로딩 다이얼로그 닫기
    resetForm();
    showSuccessDialog(context); // 성공 다이얼로그 표시
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context); // 미디어 쿼리 정보 가져오기
    final isLandscape =
        mediaQuery.orientation == Orientation.landscape; // 가로/세로 방향 확인
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
                  Icon(Icons.calendar_today, color: themeProvider.primaryColor),
                  const SizedBox(width: 10),
                  DecorateText(
                      text: '푼 날짜',
                      fontSize: 20,
                      color: themeProvider.primaryColor),
                  const Spacer(),
                  TextButton(
                    onPressed: _showCustomDatePicker, // 날짜 선택기 호출
                    child: DecorateText(
                        text:
                            '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                        fontSize: 18,
                        color: themeProvider.primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 출처 입력
              Row(
                children: <Widget>[
                  Icon(Icons.info, color: themeProvider.primaryColor),
                  const SizedBox(width: 10),
                  DecorateText(
                      text: '출처',
                      fontSize: 20,
                      color: themeProvider.primaryColor)
                ],
              ),
              const SizedBox(height: 10),
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
                      color: themeProvider.primaryColor, // 활성화된 상태의 테두리 색상 설정
                      width: 2.0, // 테두리 두께 설정
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: themeProvider.primaryColor, // 포커스된 상태의 테두리 색상 설정
                      width: 2.0, // 테두리 두께 설정
                    ),
                  ),
                  fillColor: themeProvider.primaryColor.withOpacity(0.1),
                  filled: true,
                  hintText: '문제집, 페이지, 문제번호 등',
                  hintStyle: TextStyle(
                      fontFamily: 'font1',
                      color: themeProvider.primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              // 문제 이미지 추가
              Row(
                children: <Widget>[
                  Icon(Icons.camera_alt, color: themeProvider.primaryColor),
                  const SizedBox(width: 10),
                  DecorateText(
                      text: '문제',
                      fontSize: 20,
                      color: themeProvider.primaryColor),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: isLandscape ? mediaQuery.size.height * 0.3 : 200,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  border: Border.all(
                    color: themeProvider.primaryColor, // 테두리 색상
                    width: 2.0, // 테두리 두께
                  ),
                ),
                child: Center(
                  child: _problemImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              IconButton(
                                icon: Icon(Icons.image,
                                    color: themeProvider.primaryColor,
                                    size: 50),
                                onPressed: () {
                                  _showImagePicker(
                                      'problemImage'); // 이미지 선택 팝업 호출
                                },
                              ),
                              DecorateText(
                                text: '아이콘을 눌러 이미지를 추가해주세요!',
                                color: themeProvider.primaryColor,
                              )
                            ])
                      : GestureDetector(
                          onTap: () {
                            _showImagePicker('problemImage'); // 이미지 선택 팝업 호출
                          },
                          child: Image.file(File(_problemImage!.path)),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // 해설 이미지 추가
              Row(
                children: <Widget>[
                  Icon(Icons.camera_alt, color: themeProvider.primaryColor),
                  const SizedBox(width: 10),
                  DecorateText(
                      text: '해설',
                      fontSize: 20,
                      color: themeProvider.primaryColor),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: isLandscape ? mediaQuery.size.height * 0.3 : 200,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  border: Border.all(
                    color: themeProvider.primaryColor,
                    width: 2.0,
                  ),
                ),
                child: Center(
                  child: _answerImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              IconButton(
                                icon: Icon(Icons.image,
                                    color: themeProvider.primaryColor,
                                    size: 50),
                                onPressed: () {
                                  _showImagePicker(
                                      'answerImage'); // 이미지 선택 팝업 호출
                                },
                              ),
                              DecorateText(
                                text: '아이콘을 눌러 이미지를 추가해주세요!',
                                color: themeProvider.primaryColor,
                              )
                            ])
                      : GestureDetector(
                          onTap: () {
                            _showImagePicker('answerImage');
                          },
                          child: Image.file(File(_answerImage!.path)),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // 나의 풀이 이미지 추가
              Row(
                children: <Widget>[
                  Icon(Icons.camera_alt, color: themeProvider.primaryColor),
                  const SizedBox(width: 10),
                  DecorateText(
                      text: '나의 풀이',
                      fontSize: 20,
                      color: themeProvider.primaryColor),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: isLandscape ? mediaQuery.size.height * 0.3 : 200,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  border: Border.all(
                    color: themeProvider.primaryColor, // 테두리 색상
                    width: 2.0, // 테두리 두께
                  ),
                ),
                child: Center(
                  child: _solveImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              IconButton(
                                icon: Icon(Icons.image,
                                    color: themeProvider.primaryColor,
                                    size: 50),
                                onPressed: () {
                                  _showImagePicker(
                                      'solveImage'); // 이미지 선택 팝업 호출
                                },
                              ),
                              DecorateText(
                                text: '아이콘을 눌러 이미지를 추가해주세요!',
                                color: themeProvider.primaryColor,
                              )
                            ])
                      : GestureDetector(
                          onTap: () {
                            _showImagePicker('solveImage'); // 이미지 선택 팝업 호출
                          },
                          child: Image.file(File(_solveImage!.path)),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // 오답 메모
              Row(
                children: <Widget>[
                  Icon(Icons.edit, color: themeProvider.primaryColor),
                  const SizedBox(width: 10),
                  DecorateText(
                      text: '오답 메모',
                      fontSize: 20,
                      color: themeProvider.primaryColor)
                ],
              ),
              const SizedBox(height: 10),
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
                      color: themeProvider.primaryColor, // 활성화된 상태의 테두리 색상 설정
                      width: 2.0, // 테두리 두께 설정
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: themeProvider.primaryColor, // 포커스된 상태의 테두리 색상 설정
                      width: 2.0, // 테두리 두께 설정
                    ),
                  ),
                  fillColor:
                      themeProvider.primaryColor.withOpacity(0.1), // 내부 배경색 설정
                  filled: true,
                  hintText: '틀린 이유 등 자유롭게 작성',
                  hintStyle: TextStyle(
                      fontFamily: 'font1',
                      color: themeProvider.primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              // 등록 취소 및 완료 버튼

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: resetForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white54,
                      foregroundColor: themeProvider.primaryColor,
                    ),
                    child: DecorateText(
                        text: '등록 취소',
                        fontSize: 18,
                        color: themeProvider.primaryColor),
                  ),
                  ElevatedButton(
                      onPressed: submitProblem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const DecorateText(
                        text: '등록 완료',
                        fontSize: 18,
                        color: Colors.white,
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
