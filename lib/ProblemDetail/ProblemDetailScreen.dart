import 'package:flutter/material.dart';
import 'package:mvp_front/ProblemDetail/ProblemDetailModel.dart';
import 'package:provider/provider.dart';
import 'package:mvp_front/Service/ProblemService.dart';
import '../GlobalModule/DisplayImage.dart';
import '../GlobalModule/GridPainter.dart';
import '../GlobalModule/UnderlinedText.dart';
import '../ProblemModify/ProblemModifyScreen.dart';
import 'NavigationButtons.dart';

class ProblemDetailScreen extends StatefulWidget {
  final int problemId;

  ProblemDetailScreen({Key? key, required this.problemId}) : super(key: key);

  @override
  _ProblemDetailScreenState createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends State<ProblemDetailScreen> {
  late Future<ProblemDetailModel?> _problemDataFuture;
  late ProblemService problemService;

  @override
  void initState() {
    super.initState();
    problemService = Provider.of<ProblemService>(context, listen: false);
    _problemDataFuture = _fetchProblemDetails();
  }

  Future<ProblemDetailModel?> _fetchProblemDetails() {
    return problemService.getProblemDetails(widget.problemId);
  }

  void _refreshProblemDetails() {
    setState(() {
      _problemDataFuture = _fetchProblemDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<ProblemDetailModel?>(
          future: _problemDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('로딩 중...');
            } else if (snapshot.hasError) {
              return Text('에러 발생');
            } else if (snapshot.hasData && snapshot.data != null) {
              return Text(snapshot.data!.reference ?? '출처가 없습니다!',
                  style: TextStyle(
                      color: Colors.green,
                      fontFamily: 'font1',
                      fontSize: 24,
                      fontWeight: FontWeight.bold));
            } else {
              return Text('문제 상세',
                  style: TextStyle(
                      color: Colors.green,
                      fontFamily: 'font1',
                      fontSize: 24,
                      fontWeight: FontWeight.bold));
            }
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'edit') {
                _editProblem(context, widget.problemId);
              } else if (result == 'delete') {
                _deleteProblem(context);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              /*
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('수정하기',
                    style: TextStyle(
                      fontFamily: 'font1',
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    )),
              ),

               */
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('삭제하기',
                    style: TextStyle(
                      fontFamily: 'font1',
                      fontSize: 18,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<ProblemDetailModel?>(
        future: _problemDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('에러 발생'));
          } else if (snapshot.hasData && snapshot.data != null) {
            return buildProblemDetails(context, snapshot.data!);
          } else {
            return buildNoDataScreen();
          }
        },
      ),
    );
  }

  Widget buildProblemDetails(
      BuildContext context, ProblemDetailModel problemDetailModel) {
    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: GridPainter(),
        ),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 좌측 정렬
              children: [
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // 좌측 정렬
                        children: [
                          Container(
                            width: double.infinity,
                            alignment: Alignment.centerLeft, // 좌측 정렬
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.start, // 좌측 정렬
                              children: [
                                Icon(Icons.calendar_today, color: Colors.green),
                                SizedBox(width: 8.0),
                                Text('푼 날짜',
                                    style: TextStyle(
                                        fontFamily: 'font1',
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.0),
                          UnderlinedText(text: '${problemDetailModel.solvedAt}'),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // 좌측 정렬
                        children: [
                          Container(
                            width: double.infinity,
                            alignment: Alignment.centerLeft, // 좌측 정렬
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.start, // 좌측 정렬
                              children: [
                                Icon(Icons.info, color: Colors.green),
                                SizedBox(width: 8.0),
                                Text('문제 출처',
                                    style: TextStyle(
                                        fontFamily: 'font1',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.0),
                          UnderlinedText(text: '${problemDetailModel.reference}'),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.0),
                Container(
                  width: double.infinity,
                  alignment: Alignment.centerLeft, // 좌측 정렬
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start, // 좌측 정렬
                    children: [
                      Icon(Icons.camera_alt, color: Colors.green),
                      SizedBox(width: 8.0),
                      Text('문제',
                          style: TextStyle(
                              fontFamily: 'font1',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  ),
                ),
                SizedBox(height: 20.0),
                DisplayImage(
                    imagePath: problemDetailModel.processImageUrl,
                    defaultImagePath: 'assets/process_image.png'),
                SizedBox(height: 30.0),
                ExpansionTile(
                  title: Container(
                    width: double.infinity,
                    alignment: Alignment.centerLeft, // 좌측 정렬
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, // 좌측 정렬
                      children: [
                        SizedBox(width: 8.0),
                        Text('해설 및 풀이 확인',
                            style: TextStyle(
                                fontFamily: 'font1',
                                color: Colors.green,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  children: [
                    SizedBox(height: 20.0),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // 좌측 정렬
                        children: [
                          Container(
                            width: double.infinity,
                            alignment: Alignment.centerLeft, // 좌측 정렬
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.start, // 좌측 정렬
                              children: [
                                Icon(Icons.edit, color: Colors.green),
                                SizedBox(width: 8.0),
                                Text('메모',
                                    style: TextStyle(
                                        fontFamily: 'font1',
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.0),
                          UnderlinedText(text : '${problemDetailModel.memo}'),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0),
                    Container(
                      width: double.infinity,
                      alignment: Alignment.centerLeft, // 좌측 정렬
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start, // 좌측 정렬
                        children: [
                          Icon(Icons.image, color: Colors.green),
                          SizedBox(width: 8.0),
                          Text('원본 이미지',
                              style: TextStyle(
                                  fontFamily: 'font1',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0),
                    DisplayImage(
                        imagePath: problemDetailModel.problemImageUrl,
                        defaultImagePath: 'assets/problem_image.png'),
                    SizedBox(height: 20.0),
                    Container(
                      width: double.infinity,
                      alignment: Alignment.centerLeft, // 좌측 정렬
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start, // 좌측 정렬
                        children: [
                          Icon(Icons.image, color: Colors.green),
                          SizedBox(width: 8.0),
                          Text('풀이 이미지',
                              style: TextStyle(
                                  fontFamily: 'font1',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0),
                    DisplayImage(
                        imagePath: problemDetailModel.solveImageUrl,
                        defaultImagePath: 'assets/solve_image.png'),
                    SizedBox(height: 20.0),
                    Container(
                      width: double.infinity,
                      alignment: Alignment.centerLeft, // 좌측 정렬
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start, // 좌측 정렬
                        children: [
                          Icon(Icons.image, color: Colors.green),
                          SizedBox(width: 8.0),
                          Text('해설 이미지',
                              style: TextStyle(
                                  fontFamily: 'font1',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0),
                    DisplayImage(
                        imagePath: problemDetailModel.answerImageUrl,
                        defaultImagePath: 'assets/answer_image.png'),
                    SizedBox(height: 20.0),
                  ],
                ),
                SizedBox(height: 20.0),
                NavigationButtons(
                    context: context,
                    service: problemService,
                    currentId: widget.problemId),
                SizedBox(height: 50.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _editProblem(BuildContext context, int problemId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProblemModifyScreen(problemId: problemId),
      ),
    ).then((value) {
      if (value == true) {
        _refreshProblemDetails();
      }
    });
  }

  void _deleteProblem(BuildContext context) {
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
                problemService.deleteProblem(widget.problemId).then((success) {
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
