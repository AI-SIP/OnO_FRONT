import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Service/ScreenUtil/ProblemDetailShareService.dart';
import 'package:provider/provider.dart';
import '../GlobalModule/Theme/DecorateText.dart';
import '../GlobalModule/Image/DisplayImage.dart';
import '../GlobalModule/Image/FullScreenImage.dart';
import '../GlobalModule/Theme/GridPainter.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../GlobalModule/Theme/UnderlinedText.dart';
import '../Model/ProblemModel.dart';
import '../GlobalModule/Util/NavigationButtons.dart';
import '../Service/ScreenUtil/ProblemDetailScreenService.dart';
import 'ProblemRegisterScreen.dart';

class ProblemDetailScreen extends StatefulWidget {
  final int? problemId;

  const ProblemDetailScreen({super.key, required this.problemId});

  @override
  _ProblemDetailScreenState createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends State<ProblemDetailScreen> {
  final GlobalKey _globalKey = GlobalKey();
  late Future<ProblemModel?> _problemDataFuture;
  final ProblemDetailScreenService _service = ProblemDetailScreenService();
  final ProblemDetailShareService _shareService = ProblemDetailShareService();
  bool isEditMode = false;

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
        onSelected: (String result) {
          /*
          if (result == 'share') {
            _shareService.shareProblemAsImage(_globalKey);
          }
           */
          if (result == 'edit') {
            setState(() {
              isEditMode = true;
            });
          } else if (result == 'delete') {
            deleteProblemDialog(context, themeProvider);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          /*
          PopupMenuItem<String>(
            value: 'share',
            child: DecorateText(
              text: '문제 공유하기',
              fontSize: 18,
              color: themeProvider.primaryColor,
            ),
          ),

           */
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
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 30.0),
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

    return RepaintBoundary(
        key: _globalKey,
        child: Stack(
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
                    buildSolutionExpansionTile(problemModel),
                    const SizedBox(height: 20.0),
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  // 토글 눌렀을 때 나오는 항목 위젯 구성 함수
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

  // 가운데 위젯이 오도록 하는 함수
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

  // 데이터가 없을 때 띄워주는 경고 메시지
  Widget buildNoDataScreen() {
    return const Center(child: DecorateText(text: "문제 정보를 가져올 수 없습니다.", fontSize: 28,));
  }
}
