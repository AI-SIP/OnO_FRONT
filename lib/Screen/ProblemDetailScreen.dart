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
import '../Service/ScreenUtil/ProblemDetailScreenService.dart';

class ProblemDetailScreen extends StatefulWidget {
  final int? problemId;

  const ProblemDetailScreen({super.key, required this.problemId});

  @override
  _ProblemDetailScreenState createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends State<ProblemDetailScreen> {
  late Future<ProblemModel?> _problemDataFuture;
  final ProblemDetailScreenService _service = ProblemDetailScreenService();

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
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'edit') {
                //_editProblem(context, widget.problemId);
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
                      ),
                    );
                  },
                );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          alignment: Alignment.centerLeft, // 좌측 정렬
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start, // 좌측 정렬
            children: [
              Icon(Icons.camera_alt, color: color),
              const SizedBox(width: 8.0),
              DecorateText(text: label, fontSize: 20, color: color),
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
                  builder: (context) => FullScreenImage(imagePath: imageUrl),
                ),
              );
            },
            child: DisplayImage(
              imagePath: imageUrl,
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
          DecorateText(text: text, fontSize: 20, color: color),
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

  Widget buildNoDataScreen() {
    return const Center(child: DecorateText(text: "문제 정보를 가져올 수 없습니다."));
  }
}
