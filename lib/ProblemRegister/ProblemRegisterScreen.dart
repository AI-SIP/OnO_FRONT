import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'DatePicker.dart';

class ProblemRegisterScreen extends StatefulWidget {
  const ProblemRegisterScreen({super.key});

  @override
  ProblemRegisterScreenState createState() => ProblemRegisterScreenState();
}

class ProblemRegisterScreenState extends State<ProblemRegisterScreen> {
  DateTime _selectedDate = DateTime.now(); // 선택된 날짜를 저장하는 변수
  final _sourceController = TextEditingController(); // 출처 입력 컨트롤러
  final _notesController = TextEditingController(); // 오답 메모 입력 컨트롤러

  // 날짜 선택기를 표시하는 함수
  void _showCustomDatePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return DatePicker(
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

  @override
  void dispose() {
    _sourceController.dispose(); // 출처 컨트롤러 해제
    _notesController.dispose(); // 오답 메모 컨트롤러 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context); // 미디어 쿼리 정보 가져오기
    final isLandscape =
        mediaQuery.orientation == Orientation.landscape; // 가로/세로 방향 확인

    return Scaffold(
      // AppBar는 main.dart에서 제공
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
                    style: TextStyle(fontSize: 18),
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
                    style: TextStyle(fontSize: 18),
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
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: isLandscape ? mediaQuery.size.height * 0.3 : 200,
                color: Colors.grey[200],
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.green, size: 40),
                    onPressed: () {
                      // 이미지 추가 기능 구현
                    },
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
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: isLandscape ? mediaQuery.size.height * 0.3 : 200,
                color: Colors.grey[200],
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.green, size: 40),
                    onPressed: () {
                      // 이미지 추가 기능 구현
                    },
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
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: isLandscape ? mediaQuery.size.height * 0.3 : 200,
                color: Colors.grey[200],
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.green, size: 40),
                    onPressed: () {
                      // 이미지 추가 기능 구현
                    },
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
                    style: TextStyle(fontSize: 18),
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
                    onPressed: () {
                      // 등록 취소 기능 구현
                    },
                    child: const Text('+ 등록 취소'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // 등록 완료 기능 구현
                    },
                    child: const Text('+ 등록 완료'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
