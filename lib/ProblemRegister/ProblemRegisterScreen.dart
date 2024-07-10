import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart'; // XFile을 사용하기 위해 추가
import 'package:mvp_front/Service/ProblemService.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../Provider/ProblemsProvider.dart';
import 'ProblemRegisterModel.dart';
import 'DatePickerHandler.dart';
import 'ImagePickerHandler.dart'; // 분리한 이미지 선택기 핸들러 가져오기
import 'package:http/http.dart' as http;

/*
TODO
  - 갤럭시에서도 카메라, 갤러리 기능 작동하는지 확인
  - 등록 취소 기능
  - 등록 완료 기능
*/

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

  // 등록에 성공했을 때 다이얼로그를 출력해주는 함수
  void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text("성공!"),
          content: Text("문제가 성공적으로 저장되었습니다."),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text("확인"),
              onPressed: () {
                Navigator.of(context).pop(true); // 다이얼로그 닫기
              },
            ),
          ],
        );
      },
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

  Future<void> submitProblem() async {
    final problemData = ProblemRegisterModel(
      problemImage: _problemImage,
      solveImage: _answerImage,
      answerImage: _solveImage,
      memo: _notesController.text,
      reference: _sourceController.text,
      solvedAt: _selectedDate,
    );

    resetForm();
    await Provider.of<ProblemsProvider>(context, listen: false).submitProblem(problemData, context);
    showSuccessDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context); // 미디어 쿼리 정보 가져오기
    final isLandscape =
        mediaQuery.orientation == Orientation.landscape; // 가로/세로 방향 확인

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 문제 푼 날짜 선택
              Row(
                children: <Widget>[
                  const Icon(Icons.calendar_today, color: Colors.green),
                  const SizedBox(width: 10),
                  const Text(
                    '문제 푼 날짜',
                    style: TextStyle(
                        fontFamily: 'font1',
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _showCustomDatePicker, // 날짜 선택기 호출
                    child: Text(
                      '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                      style: const TextStyle(fontSize: 18, color: Colors.green),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 출처 입력
              const Row(
                children: <Widget>[
                  Icon(Icons.info, color: Colors.green),
                  SizedBox(width: 10),
                  Text(
                    '출처',
                    style: TextStyle(
                        fontFamily: 'font1',
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _sourceController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '문제집, 페이지, 문제번호 등',
                ),
              ),
              const SizedBox(height: 20),
              // 문제 이미지 추가
              const Row(
                children: <Widget>[
                  Icon(Icons.camera_alt, color: Colors.green),
                  SizedBox(width: 10),
                  Text(
                    '문제',
                    style: TextStyle(
                        fontFamily: 'font1',
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: isLandscape ? mediaQuery.size.height * 0.3 : 200,
                color: Colors.grey[200],
                child: Center(
                  child: _problemImage == null
                      ? IconButton(
                          icon: const Icon(Icons.add,
                              color: Colors.green, size: 40),
                          onPressed: () {
                            _showImagePicker('problemImage'); // 이미지 선택 팝업 호출
                          },
                        )
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
              const Row(
                children: <Widget>[
                  Icon(Icons.camera_alt, color: Colors.green),
                  SizedBox(width: 10),
                  Text(
                    '해설',
                    style: TextStyle(
                        fontFamily: 'font1',
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: isLandscape ? mediaQuery.size.height * 0.3 : 200,
                color: Colors.grey[200],
                child: Center(
                  child: _answerImage == null
                      ? IconButton(
                          icon: const Icon(Icons.add,
                              color: Colors.green, size: 40),
                          onPressed: () {
                            _showImagePicker('answerImage'); // 이미지 선택 팝업 호출
                          },
                        )
                      : GestureDetector(
                          onTap: () {
                            _showImagePicker('answerImage'); // 이미지 선택 팝업 호출
                          },
                          child: Image.file(File(_answerImage!.path)),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // 나의 풀이 이미지 추가
              const Row(
                children: <Widget>[
                  Icon(Icons.camera_alt, color: Colors.green),
                  SizedBox(width: 10),
                  Text(
                    '나의 풀이',
                    style: TextStyle(
                        fontFamily: 'font1',
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: isLandscape ? mediaQuery.size.height * 0.3 : 200,
                color: Colors.grey[200],
                child: Center(
                  child: _solveImage == null
                      ? IconButton(
                          icon: const Icon(Icons.add,
                              color: Colors.green, size: 40),
                          onPressed: () {
                            _showImagePicker('solveImage'); // 이미지 선택 팝업 호출
                          },
                        )
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
              const Row(
                children: <Widget>[
                  Icon(Icons.edit, color: Colors.green),
                  SizedBox(width: 10),
                  Text(
                    '오답 메모',
                    style: TextStyle(
                        fontFamily: 'font1',
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '틀린 이유 등 자유롭게 작성',
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
                    child: const Text('등록 취소'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white54,
                      foregroundColor: Colors.green,
                      textStyle: const TextStyle(
                        fontFamily: 'font1',
                        fontSize: 16, // 글씨 크기 설정
                        fontWeight: FontWeight.bold, // 글씨 굵기 설정
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: submitProblem,
                    child: const Text('등록 완료'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontFamily: 'font1',
                        fontSize: 16, // 글씨 크기 설정
                        fontWeight: FontWeight.bold, // 글씨 굵기 설정
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
