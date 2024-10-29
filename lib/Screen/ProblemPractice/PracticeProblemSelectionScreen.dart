import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ono/GlobalModule/Theme/SnackBarDialog.dart';
import 'package:provider/provider.dart';
import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../Model/TemplateType.dart';
import '../../Provider/FoldersProvider.dart';
import '../../Provider/ProblemPracticeProvider.dart';
import '../../Model/FolderThumbnailModel.dart';
import '../../Model/ProblemModel.dart';
import '../../GlobalModule/Theme/NoteIconHandler.dart';
import '../../GlobalModule/Image/DisplayImage.dart';

class PracticeProblemSelectionScreen extends StatefulWidget {
  const PracticeProblemSelectionScreen({Key? key}) : super(key: key);

  @override
  _PracticeProblemSelectionScreenState createState() =>
      _PracticeProblemSelectionScreenState();
}

class _PracticeProblemSelectionScreenState
    extends State<PracticeProblemSelectionScreen> {
  int? selectedFolderId;
  List<int> selectedProblems = [];
  List<FolderThumbnailModel> allFolderThumbnails = [];

  @override
  void initState() {
    super.initState();
    _fetchFolders();
  }

  Future<void> _fetchFolders() async {
    final foldersProvider =
    Provider.of<FoldersProvider>(context, listen: false);
    List<FolderThumbnailModel> folders =
    await foldersProvider.fetchAllFolderThumbnails();
    setState(() {
      allFolderThumbnails = folders;
    });
  }

  @override
  Widget build(BuildContext context) {
    final problemPracticeProvider =
    Provider.of<ProblemPracticeProvider>(context, listen: false);
    final foldersProvider = Provider.of<FoldersProvider>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: StandardText(
          text: '복습할 문제 선택',
          fontSize: 20,
          color: themeProvider.primaryColor,
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: screenHeight * 0.035), // AppBar와 폴더 목록 사이 여백 증가
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: allFolderThumbnails.length,
                itemBuilder: (context, index) {
                  final folder = allFolderThumbnails[index];
                  return GestureDetector(
                    onTap: () async {
                      setState(() {
                        selectedFolderId = folder.folderId;
                      });
                      await foldersProvider.fetchFolderContents(
                          folderId: folder.folderId);
                    },
                    child: Padding(
                      padding: EdgeInsets.only(
                        right : screenWidth * 0.04, // 첫 번째 노트만 왼쪽 여백 조정
                      ),
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            NoteIconHandler.getNoteIcon(index),
                            width: 60,
                            height: 60,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: screenWidth * 0.2, // 일정 너비로 설정하여 이름이 잘리면 ... 처리
                            child: StandardText(
                              text: folder.folderName.length > 10
                                  ? '${folder.folderName.substring(0, 10)}..'
                                  : folder.folderName,
                              fontSize: 14,
                              color: Colors.black,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20), // 폴더 목록과 문제 목록 사이 여백
          Expanded(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 30), // 문제 목록 좌우 패딩
              child: foldersProvider.problems.isNotEmpty
                  ? ListView.builder(
                itemCount: foldersProvider.problems.length,
                itemBuilder: (context, index) {
                  final problem = foldersProvider.problems[index];
                  final isSelected =
                  selectedProblems.contains(problem.problemId);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedProblems.remove(problem.problemId);
                        } else {
                          selectedProblems.add(problem.problemId);
                        }
                      });
                    },
                    child: _problemTileContent(
                        problem, themeProvider, isSelected),
                  );
                },
              ): SingleChildScrollView(
                child: Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.15), // 아이콘과 텍스트 사이 간격 조정
                      SvgPicture.asset(
                        'assets/Icon/PencilDetail.svg', // 아이콘 경로 설정
                        width: 100, // 원하는 아이콘 크기
                        height: 100,
                      ),
                      const SizedBox(height: 16), // 아이콘과 텍스트 사이 간격 조정
                      const StandardText(
                        text: "작성한 오답노트가 없습니다!",
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ],
                  ),
                ),
              )
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.only(bottom: 16.0),
            width: MediaQuery.of(context).size.width * 0.8, // 버튼 너비를 화면의 80%로 설정
            child: ElevatedButton(
              onPressed: selectedProblems.isNotEmpty
                  ? () async {
                await problemPracticeProvider.submitPracticeProblems(selectedProblems);
                SnackBarDialog.showSnackBar(
                  context: context,
                  message: '복습 루틴이 생성되었습니다.',
                  backgroundColor: themeProvider.primaryColor,
                );
              }
                  : () {
                _showSelectProblemDialog(context); // 문제 선택 경고 다이얼로그 표시
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: themeProvider.primaryColor, // 버튼 색상 설정
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // 버튼 모양 유지
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Center(
                      child: StandardText(
                        text: "루틴 만들기",
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: StandardText(
                      text: selectedProblems.length.toString(),
                      fontSize: 16,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _problemTileContent(
      ProblemModel problem, ThemeHandler themeProvider, bool isSelected) {
    final imageUrl = (problem.templateType == TemplateType.simple)
        ? problem.problemImageUrl
        : problem.processImageUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 문제 이미지
          SizedBox(
            width: 50,
            height: 70,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: DisplayImage(
                imagePath: imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    _getTemplateIcon(problem.templateType!),
                    const SizedBox(width: 8),
                    Flexible(
                      child: StandardText(
                        text: (problem.reference != null &&
                            problem.reference!.isNotEmpty)
                            ? problem.reference!
                            : '제목 없음',
                        color: themeProvider.primaryColor,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                StandardText(
                  text: problem.createdAt != null
                      ? '작성 일시: ${formatDateTime(problem.createdAt!)}'
                      : '작성 일시: 정보 없음',
                  fontSize: 12,
                  color: themeProvider.desaturateColor,
                ),
              ],
            ),
          ),
          isSelected
              ? Icon(Icons.check_circle, color: themeProvider.primaryColor, size: 25,)
              : const Icon(Icons.circle_outlined, color: Colors.grey,),
        ],
      ),
    );
  }

  Widget _getTemplateIcon(TemplateType templateType) {
    return SvgPicture.asset(
      templateType.templateThumbnailImage,
      width: 20,
      height: 20,
    );
  }

  String formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute}';
  }

  void _showSelectProblemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const StandardText(text: "경고", fontSize: 18, color: Colors.black,),
          content: const StandardText(text: "하나 이상의 문제를 선택해주세요!", fontSize: 15, color: Colors.black),
          actions: <Widget>[
            TextButton(
              child: const StandardText(text: "확인", fontSize: 14, color: Colors.red,),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}