import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../GlobalModule/Theme/DecorateText.dart';
import '../GlobalModule/Image/DisplayImage.dart';
import '../GlobalModule/Image/FullScreenImage.dart';
import '../GlobalModule/Theme/GridPainter.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../GlobalModule/Theme/UnderlinedText.dart';
import '../Model/ProblemModel.dart';
import '../GlobalModule/Util/NavigationButtons.dart';
import '../Provider/ProblemsProvider.dart';
import '../Service/ScreenUtil/ProblemDetailScreenService.dart';
import 'ProblemRegisterScreen.dart'; // Import the update form screen

class ProblemDetailScreen extends StatefulWidget {
  final int? problemId;

  const ProblemDetailScreen({super.key, required this.problemId});

  @override
  _ProblemDetailScreenState createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends State<ProblemDetailScreen> {
  final GlobalKey _problemShareKey = GlobalKey();
  final GlobalKey _answerShareKey = GlobalKey();
  late Future<ProblemModel?> _problemDataFuture;
  final ProblemDetailScreenService _service = ProblemDetailScreenService();
  bool isEditMode = false; // State variable to control the view mode

  @override
  void initState() {
    super.initState();
    _problemDataFuture =
        _service.fetchProblemDetails(context, widget.problemId);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      appBar: AppBar(
        title: buildAppBarTitle(),
        actions: isEditMode
            ? null
            : [
                PopupMenuButton<String>(
                  onSelected: (String result) {
                    if (result == 'share_problem') {
                      _shareProblem();
                    } else if (result == 'shart_answer') {
                      _shareAnswer();
                    } else if (result == 'edit') {
                      setState(() {
                        isEditMode = true; // Switch to edit mode
                      });
                    } else if (result == 'delete') {
                      _service.deleteProblem(
                        context,
                        widget.problemId,
                        () {
                          Navigator.of(context).pop(true); // 이전 화면으로 이동
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const DecorateText(
                                text: '문제가 삭제되었습니다.',
                                fontSize: 20,
                                color: Colors.white,
                              ),
                              backgroundColor: themeProvider.primaryColor,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        (errorMessage) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: DecorateText(
                                text: errorMessage,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                        value: 'share_problem',
                        child: DecorateText(
                          text: '문제 공유하기',
                          fontSize: 18,
                          color: themeProvider.primaryColor,
                        )),
                    PopupMenuItem<String>(
                        value: 'share_answer',
                        child: DecorateText(
                          text: '정답 공유하기',
                          fontSize: 18,
                          color: themeProvider.primaryColor,
                        )),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: DecorateText(
                        text: '수정하기',
                        fontSize: 18,
                        color: Colors.blue,
                      ),
                    ),
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
        leading: isEditMode
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: themeProvider.primaryColor),
                onPressed: () {
                  setState(() {
                    isEditMode = false; // Switch back to view mode
                  });
                },
              )
            : null,
      ),
      body: isEditMode
          ? FutureBuilder<ProblemModel?>(
              future: _problemDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('에러 발생'));
                } else if (snapshot.hasData && snapshot.data != null) {
                  return ProblemRegisterScreen(problem: snapshot.data!);
                } else {
                  return buildNoDataScreen();
                }
              },
            )
          : Column(
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
                    provider:
                        Provider.of<ProblemsProvider>(context, listen: false),
                    currentId: widget.problemId!,
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildAppBarTitle() {
    final themeProvider = Provider.of<ThemeHandler>(context);
    return FutureBuilder<ProblemModel?>(
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
              text: '문제 상세', fontSize: 24, color: themeProvider.primaryColor);
        }
      },
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
                buildIconTextRow(
                  Icons.calendar_today,
                  '푼 날짜',
                  UnderlinedText(text: formattedDate, fontSize: 18),
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
                buildImageSection(
                  context,
                  problemModel.processImageUrl,
                  '문제',
                  themeProvider.primaryColor,
                ),
                const SizedBox(height: 30.0),
                buildSolutionExpansionTile(problemModel),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildIconTextRow(IconData icon, String label, Widget trailing) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Row(
      children: [
        Icon(icon, color: themeProvider.primaryColor),
        const SizedBox(width: 8),
        DecorateText(
            text: label, fontSize: 20, color: themeProvider.primaryColor),
        const Spacer(),
        trailing,
      ],
    );
  }

  Widget buildImageSection(
      BuildContext context, String? imageUrl, String label, Color color) {
    final mediaQuery = MediaQuery.of(context);
    final themeProvider = Provider.of<ThemeHandler>(context);

    // 화면의 너비에 따라 이미지 크기 비율을 다르게 설정
    double maxImageHeight = mediaQuery.size.height * 0.9; // 기본 크기
    if (mediaQuery.size.width > 600) {
      // 가로 모드나 태블릿 같이 큰 화면일 때
      maxImageHeight = mediaQuery.size.height * 0.6; // 크기를 줄임
    } else if (mediaQuery.size.width > 800) {
      // 더 큰 화면일 때
      maxImageHeight = mediaQuery.size.height * 0.5; // 크기를 더 줄임
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.camera_alt, color: color),
              const SizedBox(width: 8.0),
              DecorateText(text: label, fontSize: 20, color: color),
            ],
          ),
        ),
        const SizedBox(height: 20.0),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxImageHeight, // 이미지의 최대 높이 설정
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImage(imagePath: imageUrl),
                  ),
                );
              },
              child: DisplayImage(
                imagePath: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSolutionExpansionTile(ProblemModel problemModel) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return ExpansionTile(
      title: buildCenteredTitle('해설 및 풀이 확인', themeProvider.primaryColor),
      children: [
        const SizedBox(height: 10.0),
        buildSectionWithMemo(problemModel),
        const SizedBox(height: 20.0),
        buildImageSection(
          context,
          problemModel.problemImageUrl,
          '원본 이미지',
          themeProvider.primaryColor,
        ),
        const SizedBox(height: 20.0),
        buildImageSection(
          context,
          problemModel.answerImageUrl,
          '해설 이미지',
          themeProvider.primaryColor,
        ),
        const SizedBox(height: 20.0),
        buildImageSection(
          context,
          problemModel.solveImageUrl,
          '풀이 이미지',
          themeProvider.primaryColor,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  Widget buildCenteredTitle(String text, Color color) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 8.0),
          DecorateText(text: text, fontSize: 24, color: color),
        ],
      ),
    );
  }

  Widget buildSectionWithMemo(ProblemModel problemModel) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 좌측 정렬
        children: [
          buildIconTextRow(Icons.edit, '한 줄 메모', Container()),
          const SizedBox(height: 8.0),
          UnderlinedText(
            text: problemModel.memo?.isNotEmpty == true
                ? problemModel.memo!
                : '작성한 메모가 없습니다!',
          ),
        ],
      ),
    );
  }

  // 문제 공유하기 기능
  Future<void> _shareProblem() async {
    await _shareContent(_problemShareKey);
  }

  // 정답 공유하기 기능
  Future<void> _shareAnswer() async {
    await _shareContent(_answerShareKey);
  }

  Future<void> _shareContent(GlobalKey boundaryKey) async {
    try {
      RenderRepaintBoundary boundary = boundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/shared_image.png').create();
      await file.writeAsBytes(pngBytes);

      final XFile xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: '내 오답노트를 공유합니다!');
    } catch (e) {
      log(e.toString());
    }
  }

  Widget buildNoDataScreen() {
    return const Center(child: DecorateText(text: "문제 정보를 가져올 수 없습니다."));
  }
}
