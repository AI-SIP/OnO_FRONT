import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mvp_front/Service/ProblemService.dart';
import '../GlobalModule/DisplayImage.dart';
import '../GlobalModule/GridPainter.dart';
import 'NavigationButtons.dart';

class ProblemDetailScreen extends StatelessWidget {
  final int problemId;

  ProblemDetailScreen({Key? key, required this.problemId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final problemService = Provider.of<ProblemService>(context, listen: false);
    final problemData = problemService.getProblemDetails(problemId);

    return Scaffold(
      appBar: AppBar(
        title: Text(problemData != null ? problemData['reference'] : '문제 상세',
            style: TextStyle(
                color: Colors.green,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'edit') {
                // 수정하기 로직
                _editProblem(context, problemId);
              } else if (result == 'delete') {
                // 삭제하기 로직
                _deleteProblem(context, problemService, problemId);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('수정하기'),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('삭제하기', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: problemData != null
          ? buildProblemDetails(context, problemService, problemData)
          : buildNoDataScreen(),
    );
  }

  Widget buildProblemDetails(BuildContext context,
      ProblemService problemService, Map<String, dynamic> problemData) {
    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: GridPainter(),
        ),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35.0), // 좌우 여백 추가
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // 가운데 정렬
              children: [
                SizedBox(height: 16.0), // 상단 여백 추가
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // 가운데 정렬
                        children: [
                          Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today, color: Colors.green),
                                SizedBox(width: 8.0),
                                Text('푼 날짜',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.0), // 상하 간격 추가
                          Text('${problemData['solvedAt']}',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.0), // 둘 사이 공백 추가
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // 가운데 정렬
                        children: [
                          Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info, color: Colors.green),
                                SizedBox(width: 8.0),
                                Text('문제 출처',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.0), // 상하 간격 추가
                          Text('${problemData['reference']}',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.0), // 상하 간격 추가
                Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.green),
                      SizedBox(width: 8.0),
                      Text('문제',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  ),
                ),
                SizedBox(height: 20.0), // 상하 간격 추가
                DisplayImage(
                    imagePath: problemData['processImageUrl'],
                    defaultImagePath: 'assets/process_image.png'),
                SizedBox(height: 30.0), // 상하 간격 추가
                ExpansionTile(
                  title: Container(
                    width: double.infinity,
                    alignment: Alignment.center, // 가운데 정렬
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 8.0),
                        Text('해설 및 풀이 확인',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  children: [
                    SizedBox(height: 30.0), // 상하 간격 추가,
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // 가운데 정렬
                        children: [
                          Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit, color: Colors.green),
                                SizedBox(width: 8.0),
                                Text('메모',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.0), // 상하 간격 추가
                          Text('${problemData['memo']}',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0),
                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, color: Colors.green),
                          SizedBox(width: 8.0),
                          Text('풀이 이미지',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0), // 상하 간격 추가
                    DisplayImage(
                        imagePath: problemData['solveImageUrl'],
                        defaultImagePath: 'assets/solve_image.png'),
                    SizedBox(height: 20.0), // 상하 간격 추가
                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, color: Colors.green),
                          SizedBox(width: 8.0),
                          Text('원본 이미지',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0), // 상하 간격 추가
                    DisplayImage(
                        imagePath: problemData['answerImageUrl'],
                        defaultImagePath: 'assets/problem_image.png'),
                    SizedBox(height: 20.0), // 상하 간격 추가
                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, color: Colors.green),
                          SizedBox(width: 8.0),
                          Text('해설 이미지',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0), // 상하 간격 추가
                    DisplayImage(
                        imagePath: problemData['answerImageUrl'],
                        defaultImagePath: 'assets/answer_image.png'),
                    SizedBox(height: 20.0), // 상하 간격 추가
                  ],
                ),
                SizedBox(height: 20.0), // 상하 간격 추가
                NavigationButtons(
                    context: context,
                    service: problemService,
                    currentId: problemId),
                SizedBox(height: 50.0), // 상하 간격 추가
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _editProblem(BuildContext context, int problemId) {
    // 수정하기 로직 구현
    // 여기서 수정 화면으로 이동하거나 수정 다이얼로그를 표시할 수 있습니다.
    /*
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProblemScreen(problemId: problemId),
      ),
    );
     */
  }

  void _deleteProblem(
      BuildContext context, ProblemService problemService, int problemId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('문제 삭제'),
          content: Text('정말로 이 문제를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                problemService.deleteProblem(problemId).then((success) {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  if (success) {
                    Navigator.of(context).pop(true); // 이전 화면으로 이동
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('문제가 삭제되었습니다.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('문제 삭제에 실패했습니다.')),
                    );
                  }
                });
              },
              child: Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  Widget buildNoDataScreen() {
    return Center(child: Text("문제 정보를 가져올 수 없습니다."));
  }
}