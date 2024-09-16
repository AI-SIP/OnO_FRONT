import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:provider/provider.dart';
import '../GlobalModule/Theme/DecorateText.dart';
import '../GlobalModule/Image/DisplayImage.dart';
import '../GlobalModule/Image/FullScreenImage.dart';
import '../GlobalModule/Theme/GridPainter.dart';
import '../GlobalModule/Theme/SnackBarDialog.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../GlobalModule/Theme/UnderlinedText.dart';
import '../Model/ProblemModel.dart';
import '../GlobalModule/Util/NavigationButtons.dart';
import '../Service/ScreenUtil/ProblemDetailScreenService.dart';
import 'AnswerShareScreen.dart';
import 'ProblemRegisterScreen.dart';
import 'ProblemShareScreen.dart';

class ProblemDetailScreen extends StatefulWidget {
  final int? problemId;

  const ProblemDetailScreen({super.key, required this.problemId});

  @override
  _ProblemDetailScreenState createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends State<ProblemDetailScreen> {
  late Future<ProblemModel?> _problemDataFuture;
  final ProblemDetailScreenService _service = ProblemDetailScreenService();
  bool isEditMode = false;

  static const String shareProblemValue = 'share_problem';
  static const String shareAnswerValue = 'share_answer';
  static const String editValue = 'edit';
  static const String deleteValue = 'delete';

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
      appBar: buildAppBar(themeProvider),
      body: buildBody(context),
    );
  }

  // AppBar 구성 함수
  AppBar buildAppBar(ThemeHandler themeProvider) {
    return AppBar(
      title: buildAppBarTitle(),
      actions: isEditMode ? null : buildAppBarActions(themeProvider),
      leading: isEditMode ? buildBackButton(themeProvider) : null,
    );
  }

  // AppBar의 동작 및 메뉴 버튼
  List<Widget> buildAppBarActions(ThemeHandler themeProvider) {

    return [
      PopupMenuButton<String>(
        onSelected: (String result) async{
          final problemData = await _problemDataFuture;
          if (result == shareProblemValue) {
            if (problemData != null) {
              // Navigate to ProblemShareScreen and wait for result
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProblemShareScreen(problem: problemData),
                ),
              );
            }
          }
          else if (result == shareAnswerValue) {
            if (problemData != null) {
              // Navigate to ProblemShareScreen and wait for result
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AnswerShareScreen(problem: problemData),
                ),
              );
            }
          }
          else if (result == editValue) {
            setState(() {
              isEditMode = true;
            });
          } else if (result == deleteValue) {
            deleteProblemDialog(context, themeProvider);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[

          PopupMenuItem<String>(
            value: 'share_problem',
            child: DecorateText(
              text: '문제 공유하기',
              fontSize: 18,
              color: themeProvider.primaryColor,
            ),
          ),
          PopupMenuItem<String>(
            value: 'share_answer',
            child: DecorateText(
              text: '정답 공유하기',
              fontSize: 18,
              color: themeProvider.primaryColor,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'edit',
            child: DecorateText(
              text: '문제 수정하기',
              fontSize: 18,
              color: Colors.blue,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'delete',
            child: DecorateText(
              text: '문제 삭제하기',
              fontSize: 18,
              color: Colors.red,
            ),
          ),
        ],
      ),
    ];
  }

// 뒤로 가기 버튼 함수
  IconButton buildBackButton(ThemeHandler themeProvider) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: themeProvider.primaryColor),
      onPressed: () {
        setState(() {
          isEditMode = false;
        });
      },
    );
  }

// 문제 삭제 처리 함수
  void deleteProblemDialog(BuildContext context, ThemeHandler themeProvider) {
    _service.deleteProblem(
      context,
      widget.problemId,
      () {
        Navigator.of(context).pop(true);
        if (mounted) {
          SnackBarDialog.showSnackBar(
            context: context,
            message: '문제가 삭제되었습니다!',
            backgroundColor: Theme.of(context).primaryColor,
          );
        }
      },
      (errorMessage) {
        if (mounted) {
          SnackBarDialog.showSnackBar(
            context: context,
            message: errorMessage,
            backgroundColor: Colors.red,
          );
        }
      },
    );
  }

// 화면의 본문(body)을 구성하는 함수
  Widget buildBody(BuildContext context) {
    return isEditMode ? buildEditMode(context) : buildViewMode(context);
  }

// 수정 모드일 때의 화면 구성
  Widget buildEditMode(BuildContext context) {
    return FutureBuilder<ProblemModel?>(
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
    );
  }

// 뷰 모드일 때의 화면 구성
  Widget buildViewMode(BuildContext context) {
    return Column(
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
        buildNavigationButtons(context),
      ],
    );
  }

  // 네비게이션 버튼 구성 함수
  Widget buildNavigationButtons(BuildContext context) {
    // 기기의 높이 정보를 가져옴
    double screenHeight = MediaQuery.of(context).size.height;

    // 화면 높이에 따라 패딩 값을 동적으로 설정
    double topPadding = screenHeight >= 1000 ? 25.0 : 15.0;
    double bottomPadding = screenHeight >= 1000 ? 30.0 : 25.0;
    double topBottomPadding = screenHeight >= 1000 ? 25.0 : 25.0; // 아이패드 13인치(높이 1024 이상) 기준으로 35, 그 외는 20

    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: NavigationButtons(
        context: context,
        provider: Provider.of<FoldersProvider>(context, listen: false),
        currentId: widget.problemId!,
      ),
    );
  }

  // 상단 앱 바 구성 함수
  Widget buildAppBarTitle() {
    final themeProvider = Provider.of<ThemeHandler>(context);
    return FutureBuilder<ProblemModel?>(
      future: _problemDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DecorateText(text: '로딩 중...');
        } else if (snapshot.hasError) {
          return const DecorateText(text: '에러 발생');
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

  // 문제 상세 화면 구성 함수
  Widget buildProblemDetails(BuildContext context, ProblemModel problemModel) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 600) {
      // 화면 너비가 600 이상일 때 좌우로 배치
      return Stack(
        children: [
          buildBackground(themeProvider),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 좌측 영역 (푼 날짜와 문제 출처)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 30.0),
                            buildSolvedDate(context, problemModel),
                            const SizedBox(height: 30.0),
                            buildProblemReference(context, problemModel),
                          ],
                        ),
                      ),
                      const SizedBox(width: 30.0), // 좌우 간격을 위한 여백
                      // 우측 영역 (문제 이미지)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 25.0),
                            // 이미지 상단 정렬 및 하단 여백 최소화
                            buildProblemImage(context, problemModel),
                            const SizedBox(height: 30.0),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // 해설 및 풀이 확인 토글은 스크롤 시 나타나도록 설정
                  const SizedBox(height: 15.0),
                  buildSolutionExpansionTile(problemModel),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // 화면 너비가 600 이하일 때 기존 세로 배치 유지
      return Stack(
        children: [
          buildBackground(themeProvider),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 좌측 정렬
                children: [
                  const SizedBox(height: 16.0),
                  buildSolvedDate(context, problemModel),
                  const SizedBox(height: 25.0),
                  buildProblemReference(context, problemModel),
                  const SizedBox(height: 30.0),
                  buildProblemImage(context, problemModel),
                  const SizedBox(height: 30.0),
                  buildSolutionExpansionTile(problemModel), // 스크롤 시 보여지는 영역
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  // 토글 눌렀을 때 나오는 항목 위젯 구성 함수
  Widget buildSolutionExpansionTile(ProblemModel problemModel) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // 화면 크기에 따라 한 줄에 몇 개의 항목을 배치할지 설정
    int crossAxisCount;
    if (screenWidth > 1100) {
      crossAxisCount = 3;  // 가로가 1100 이상이면 3개
    } else if (screenWidth >= 600) {
      crossAxisCount = 2;  // 가로가 600에서 1100 사이면 2개
    } else {
      crossAxisCount = 1;  // 가로가 600 이하이면 1개
    }

    double childAspectRatio = 0.65;

    return ExpansionTile(
      title: Container(

        padding: const EdgeInsets.all(8.0), // 여백 추가
        child: buildCenteredTitle('해설 및 풀이 확인', themeProvider.primaryColor),
      ),
      children: [
        const SizedBox(height: 10.0),
        buildSectionWithMemo(problemModel),
        const SizedBox(height: 20.0),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 20.0,
          crossAxisSpacing: 20.0,
          childAspectRatio: childAspectRatio,
          children: [
            buildImageSection(
              context,
              problemModel.problemImageUrl,
              '원본 이미지',
              themeProvider.primaryColor,
            ),
            buildImageSection(
              context,
              problemModel.answerImageUrl,
              '해설 이미지',
              themeProvider.primaryColor,
            ),
            buildImageSection(
              context,
              problemModel.solveImageUrl,
              '풀이 이미지',
              themeProvider.primaryColor,
            ),
          ],
        ),
      ],
    );
  }

  // 배경 구현 함수
  Widget buildBackground(ThemeHandler themeProvider) {
    return CustomPaint(
      size: Size.infinite,
      painter: GridPainter(gridColor: themeProvider.primaryColor),
    );
  }

  // 푼 날짜 위젯 구현 함수
  Widget buildSolvedDate(BuildContext context, ProblemModel problemModel) {
    final formattedDate =
        DateFormat('yyyy년 M월 d일').format(problemModel.solvedAt!);
    return buildIconTextRow(
      Icons.calendar_today,
      '푼 날짜',
      UnderlinedText(text: formattedDate, fontSize: 18),
    );
  }

  // 문제 출처 위젯 구현 함수
  Widget buildProblemReference(
      BuildContext context, ProblemModel problemModel) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // 레이블을 위로 정렬
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: themeProvider.primaryColor),
                  const SizedBox(width: 8),
                  DecorateText(
                    text: '문제 출처',
                    fontSize: 20,
                    color: themeProvider.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              UnderlinedText(
                text: problemModel.reference ?? '출처 없음',
                fontSize: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 문제 보정 이미지 구현 위젯
  Widget buildProblemImage(BuildContext context, ProblemModel problemModel) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    return buildImageSection(
      context,
      problemModel.processImageUrl,
      '문제',
      themeProvider.primaryColor,
    );
  }

  // 메모 위젯 구현 함수
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

  // 이미지 띄워주는 위젯 구현 함수
  Widget buildImageSection(BuildContext context, String? imageUrl, String label, Color color) {
    final mediaQuery = MediaQuery.of(context);
    final themeProvider = Provider.of<ThemeHandler>(context);

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
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImage(imagePath: imageUrl),
                ),
              );
            },
            child: Container(
              width: mediaQuery.size.width * 0.8, // 부모 크기 기준
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withOpacity(0.1), // 배경색 추가
                borderRadius: BorderRadius.circular(10), // 모서리 둥글게 설정
              ),
              child: AspectRatio(
                aspectRatio: 0.8, // 원하는 비율로 이미지의 높이를 조정
                child: DisplayImage(
                  imagePath: imageUrl,
                  fit: BoxFit.contain, // 이미지 전체를 보여주기 위한 설정
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  // 한 줄에 아이콘과 텍스트가 동시에 오도록 하는 함수
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

  // 가운데 밑줄이 있는 텍스트 위젯을 만드는 함수
  Widget buildCenteredTitle(String text, Color color) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 8.0),
          UnderlinedText(
            text: text,
            fontSize: 24,
            color: color,
            fontWeight: FontWeight.bold, // 굵은 텍스트로 설정
          ),
        ],
      ),
    );
  }

  // 데이터가 없을 때 띄워주는 경고 메시지
  Widget buildNoDataScreen() {
    return const Center(child: DecorateText(text: "문제 정보를 가져올 수 없습니다.", fontSize: 28,));
  }
}
