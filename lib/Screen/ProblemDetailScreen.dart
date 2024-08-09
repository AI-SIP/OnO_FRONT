import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../GlobalModule/Theme/DecorateText.dart';
import '../GlobalModule/Image/DisplayImage.dart';
import '../GlobalModule/Image/FullScreenImage.dart';
import '../GlobalModule/Theme/GridPainter.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../GlobalModule/Theme/UnderlinedText.dart';
import '../Model/ProblemModel.dart';
import '../GlobalModule/Util/NavigationButtons.dart';
import '../Provider/ProblemsProvider.dart';

class ProblemDetailScreen extends StatefulWidget {
  final int? problemId;

  const ProblemDetailScreen({super.key, required this.problemId});

  @override
  _ProblemDetailScreenState createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends State<ProblemDetailScreen> {
  late Future<ProblemModel?> _problemDataFuture;

  @override
  void initState() {
    super.initState();
    _problemDataFuture = _fetchProblemDetails();
  }

  Future<ProblemModel?> _fetchProblemDetails() {
    return Provider.of<ProblemsProvider>(context, listen: false)
        .getProblemDetails(widget.problemId);
  }

  void _refreshProblemDetails() {
    setState(() {
      _problemDataFuture = _fetchProblemDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<ProblemModel?>(
          future: _problemDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('로딩 중...');
            } else if (snapshot.hasError) {
              return const Text('에러 발생');
            } else if (snapshot.hasData && snapshot.data != null) {
              return DecorateText(
                text: snapshot.data!.reference ?? '출처가 없습니다!',
                fontSize: 24,
                color: themeProvider.primaryColor,
              );
            } else {
              return DecorateText(
                  text: '문제 상세',
                  fontSize: 24,
                  color: themeProvider.primaryColor);
            }
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'edit') {
                //_editProblem(context, widget.problemId);
              } else if (result == 'delete') {
                _deleteProblem(context, widget.problemId);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                  value: 'delete',
                  child: DecorateText(
                    text: '삭제하기',
                    fontSize: 18,
                    color: Colors.red,
                  )),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<ProblemModel?>(
              future: _problemDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('에러 발생'));
                } else if (snapshot.hasData && snapshot.data != null) {
                  return buildProblemDetails(context, snapshot.data!);
                } else {
                  return buildNoDataScreen();
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                top: 10.0, bottom: 30.0), // Adjust padding here
            child: NavigationButtons(
              context: context,
              provider: Provider.of<ProblemsProvider>(context, listen: false),
              currentId: widget.problemId!,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProblemDetails(BuildContext context, ProblemModel problemModel) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final formattedDate =
        DateFormat('yyyy년 M월 d일').format(problemModel.solvedAt!);

    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: GridPainter(gridColor: themeProvider.primaryColor),
        ),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 좌측 정렬
              children: [
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: themeProvider.primaryColor),
                    const SizedBox(width: 8),
                    DecorateText(
                        text: '푼 날짜',
                        fontSize: 20,
                        color: themeProvider.primaryColor),
                    const Spacer(),
                    UnderlinedText(text: formattedDate, fontSize: 18),
                  ],
                ),
                const SizedBox(height: 25.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // 레이블을 위로 정렬
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.info, color: themeProvider.primaryColor),
                            const SizedBox(width: 8),
                            DecorateText(
                                text: '문제 출처',
                                fontSize: 20,
                                color: themeProvider.primaryColor),
                          ]),
                          const SizedBox(height: 10.0),
                          UnderlinedText(
                              text: problemModel.reference ?? '출처 없음',
                              fontSize: 18),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30.0),
                Container(
                  width: double.infinity,
                  alignment: Alignment.centerLeft, // 좌측 정렬
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start, // 좌측 정렬
                    children: [
                      Icon(Icons.camera_alt, color: themeProvider.primaryColor),
                      const SizedBox(width: 8.0),
                      DecorateText(
                          text: '문제',
                          fontSize: 20,
                          color: themeProvider.primaryColor),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      // 이미지를 탭했을 때 FullScreenImage를 표시합니다.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImage(
                              imagePath: problemModel.processImageUrl),
                        ),
                      );
                    },
                    child: DisplayImage(
                      imagePath: problemModel.processImageUrl,
                    ),
                  ),
                ),
                const SizedBox(height: 30.0),
                ExpansionTile(
                  title: Container(
                    width: double.infinity,
                    alignment: Alignment.center, // 좌측 정렬
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, // 좌측 정렬
                      children: [
                        const SizedBox(width: 8.0),
                        DecorateText(
                            text: '해설 및 풀이 확인',
                            fontSize: 20,
                            color: themeProvider.primaryColor),
                      ],
                    ),
                  ),
                  children: [
                    const SizedBox(height: 10.0),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // 좌측 정렬
                        children: [
                          Container(
                            width: double.infinity,
                            alignment: Alignment.centerLeft, // 좌측 정렬
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.start, // 좌측 정렬
                              children: [
                                Icon(Icons.edit,
                                    color: themeProvider.primaryColor),
                                const SizedBox(width: 8.0),
                                DecorateText(
                                    text: '메모',
                                    fontSize: 20,
                                    color: themeProvider.primaryColor),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          UnderlinedText(text: '${problemModel.memo}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Container(
                      width: double.infinity,
                      alignment: Alignment.centerLeft, // 좌측 정렬
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start, // 좌측 정렬
                        children: [
                          Icon(Icons.image, color: themeProvider.primaryColor),
                          const SizedBox(width: 8.0),
                          DecorateText(
                              text: '원본 이미지',
                              fontSize: 20,
                              color: themeProvider.primaryColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImage(
                                  imagePath: problemModel.problemImageUrl),
                            ),
                          );
                        },
                        child: DisplayImage(
                          imagePath: problemModel.problemImageUrl,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Container(
                      width: double.infinity,
                      alignment: Alignment.centerLeft, // 좌측 정렬
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start, // 좌측 정렬
                        children: [
                          Icon(Icons.image, color: themeProvider.primaryColor),
                          const SizedBox(width: 8.0),
                          DecorateText(
                              text: '풀이 이미지',
                              fontSize: 20,
                              color: themeProvider.primaryColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImage(
                                  imagePath: problemModel.solveImageUrl),
                            ),
                          );
                        },
                        child: DisplayImage(
                          imagePath: problemModel.solveImageUrl,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Container(
                      width: double.infinity,
                      alignment: Alignment.centerLeft, // 좌측 정렬
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start, // 좌측 정렬
                        children: [
                          Icon(Icons.image, color: themeProvider.primaryColor),
                          const SizedBox(width: 8.0),
                          DecorateText(
                              text: '해설 이미지',
                              fontSize: 20,
                              color: themeProvider.primaryColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImage(
                                  imagePath: problemModel.answerImageUrl),
                            ),
                          );
                        },
                        child: DisplayImage(
                          imagePath: problemModel.answerImageUrl,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                  ],
                ),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _deleteProblem(BuildContext context, int? problemId) {
    if (problemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문제 ID가 유효하지 않습니다.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeHandler>(context);

        return AlertDialog(
          title: DecorateText(
              text: '문제 삭제', fontSize: 24, color: themeProvider.primaryColor),
          content: DecorateText(
              text: '정말로 이 문제를 삭제하시겠습니까?',
              fontSize: 20,
              color: themeProvider.primaryColor),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: const DecorateText(
                text: '취소',
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {
                Provider.of<ProblemsProvider>(context, listen: false)
                    .deleteProblem(problemId)
                    .then((success) {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  if (success) {
                    Navigator.of(context).pop(true); // 이전 화면으로 이동
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: const DecorateText(
                            text: '문제가 삭제되었습니다.',
                            fontSize: 20,
                            color: Colors.white,
                          ),
                          backgroundColor: themeProvider.primaryColor),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: DecorateText(
                            text: '문제 삭제에 실패했습니다.',
                            fontSize: 20,
                            color: Colors.white,
                          ),
                          backgroundColor: Colors.red),
                    );
                  }
                }).catchError((error) {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: DecorateText(
                        text: '오류 발생: ${error.toString()}',
                        fontSize: 20,
                        color: Colors.white,
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                });
              },
              child: const DecorateText(
                text: '삭제',
                fontSize: 20,
                color: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildNoDataScreen() {
    return const Center(child: Text("문제 정보를 가져올 수 없습니다."));
  }

  void _showImageDialog(BuildContext context, String? imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double dialogWidth = constraints.maxWidth * 0.9;
              double dialogHeight = constraints.maxHeight * 0.8;

              return SizedBox(
                width: dialogWidth,
                height: dialogHeight,
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: imageUrl != null
                      ? Image.network(imageUrl, fit: BoxFit.contain)
                      : Image.asset('assets/no_image.png', fit: BoxFit.contain),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
