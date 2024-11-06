import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ono/Model/ProblemPracticeModel.dart';
import 'package:ono/Screen/ProblemPractice/PracticeTitleWriteScreen.dart';
import 'package:provider/provider.dart';
import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../Model/ProblemPracticeRegisterModel.dart';
import '../../Model/TemplateType.dart';
import '../../Provider/FoldersProvider.dart';
import '../../Model/FolderThumbnailModel.dart';
import '../../Model/ProblemModel.dart';
import '../../GlobalModule/Theme/NoteIconHandler.dart';
import '../../GlobalModule/Image/DisplayImage.dart';

class PracticeProblemSelectionScreen extends StatefulWidget {
  final ProblemPracticeModel? practiceModel;

  const PracticeProblemSelectionScreen({Key? key, this.practiceModel})
      : super(key: key);

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

    if (widget.practiceModel != null) {
      selectedProblems = widget.practiceModel!.problemIds!;
    }
  }

  Future<void> _fetchFolders() async {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    List<FolderThumbnailModel> folders =
        await foldersProvider.fetchAllFolderThumbnails();
    setState(() {
      allFolderThumbnails = folders;
      selectedFolderId = allFolderThumbnails[0].folderId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    double screenHeight = MediaQuery.of(context).size.height;
    final foldersProvider = Provider.of<FoldersProvider>(context);

    return PopScope(
        canPop: true,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            await foldersProvider.fetchRootFolderContents();
            return;
          }
        },
        child: Scaffold(
          appBar: _buildAppBar(themeProvider),
          backgroundColor: Colors.white,
          body: Column(
            children: [
              SizedBox(height: screenHeight * 0.035),
              _buildFolderList(context, themeProvider),
              const SizedBox(height: 20),
              _buildProblemList(context, themeProvider),
              _buildSubmitButton(context, themeProvider),
            ],
          ),
        ));
  }

  AppBar _buildAppBar(ThemeHandler themeProvider) {
    return AppBar(
      centerTitle: true,
      title: StandardText(
        text: '복습할 문제 선택',
        fontSize: 20,
        color: themeProvider.primaryColor,
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildFolderList(BuildContext context, ThemeHandler themeProvider) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
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
                await Provider.of<FoldersProvider>(context, listen: false)
                    .fetchFolderContents(folderId: folder.folderId);
              },
              child: Padding(
                padding: EdgeInsets.only(right: screenWidth * 0.04),
                child: _buildFolderThumbnail(folder, themeProvider),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFolderThumbnail(FolderThumbnailModel folder, ThemeHandler themeProvider) {
    bool isSelected = selectedFolderId == folder.folderId; // 선택된 폴더인지 확인

    return Opacity(
      opacity: isSelected ? 1.0 : 0.5, // 선택된 폴더가 아니라면 흐리게 표시
      child: Column(
        children: [
          SvgPicture.asset(
            NoteIconHandler.getNoteIcon(allFolderThumbnails.indexOf(folder)),
            width: 60,
            height: 60,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.2,
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
    );
  }

  Widget _buildProblemList(BuildContext context, ThemeHandler themeProvider) {
    final foldersProvider = Provider.of<FoldersProvider>(context);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
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
                        isSelected
                            ? selectedProblems.remove(problem.problemId)
                            : selectedProblems.add(problem.problemId);
                      });
                    },
                    child:
                        _problemTileContent(problem, themeProvider, isSelected),
                  );
                },
              )
            : _buildEmptyProblemMessage(),
      ),
    );
  }

  Widget _buildEmptyProblemMessage() {
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            SvgPicture.asset(
              'assets/Icon/PencilDetail.svg',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 16),
            const StandardText(
              text: "작성한 오답노트가 없습니다!",
              color: Colors.black,
              fontSize: 16,
            ),
          ],
        ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _getTemplateIcon(problem.templateType!),
                    const SizedBox(width: 8),
                    Flexible(
                      child: StandardText(
                        text: problem.reference?.isNotEmpty == true
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
              ? Icon(Icons.check_circle,
                  color: themeProvider.primaryColor, size: 25)
              : const Icon(Icons.circle_outlined, color: Colors.grey),
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

  Widget _buildSubmitButton(BuildContext context, ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      width: MediaQuery.of(context).size.width * 0.8,
      child: ElevatedButton(
        onPressed: selectedProblems.isNotEmpty
            ? () {
                ProblemPracticeRegisterModel practiceRegisterModel;

                if (widget.practiceModel != null) {
                  practiceRegisterModel = ProblemPracticeRegisterModel(
                      practiceId: widget.practiceModel!.practiceId,
                      practiceTitle: widget.practiceModel!.practiceTitle,
                      registerProblemIds: selectedProblems);
                } else {
                  practiceRegisterModel = ProblemPracticeRegisterModel(
                      practiceTitle: "", registerProblemIds: selectedProblems);
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PracticeTitleWriteScreen(
                      practiceRegisterModel: practiceRegisterModel,
                    ),
                  ),
                );
              }
            : () => _showSelectProblemDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: themeProvider.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(
              child: Center(
                child: StandardText(
                  text: "다음",
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
    );
  }

  void _showSelectProblemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const StandardText(
            text: "경고",
            fontSize: 18,
            color: Colors.black,
          ),
          content: const StandardText(
            text: "하나 이상의 문제를 선택해주세요!",
            fontSize: 15,
            color: Colors.black,
          ),
          actions: <Widget>[
            TextButton(
              child: const StandardText(
                text: "확인",
                fontSize: 14,
                color: Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute}';
  }
}
