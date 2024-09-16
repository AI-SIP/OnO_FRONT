import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ono/GlobalModule/Theme/SnackBarDialog.dart';
import 'package:ono/Model/LoginStatus.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:provider/provider.dart';
import '../GlobalModule/Theme/DecorateText.dart';
import '../GlobalModule/Image/DisplayImage.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../GlobalModule/Util/FolderSelectionDialog.dart';
import '../Model/ProblemRegisterModel.dart';
import '../Service/ScreenUtil/DirectoryScreenService.dart';
import '../Model/ProblemModel.dart';
import '../Model/FolderThumbnailModel.dart';
import '../Service/Auth/AuthService.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  _DirectoryScreenState createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final String defaultImage = 'assets/no_image.png';
  String _selectedSortOption = 'newest';
  final String _directoryName = '메인';

  late DirectoryScreenService _directoryService;

  @override
  void initState() {
    super.initState();
    _directoryService = DirectoryScreenService(
      Provider.of<FoldersProvider>(context, listen: false),
    );

    _directoryService.sortProblems(_selectedSortOption);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);
    final foldersProvider = Provider.of<FoldersProvider>(context);

    return Scaffold(
      appBar: _buildAppBar(themeProvider, foldersProvider), // 상단 AppBar 추가
      body: !(authService.isLoggedIn == LoginStatus.login)
          ? _buildLoginPrompt(themeProvider)
          : RefreshIndicator(
              onRefresh: () async {
                _directoryService.sortProblems(_selectedSortOption);
                await _directoryService.fetchProblems();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    _buildSortDropdown(themeProvider),
                    _buildFolderAndProblemGrid(themeProvider),
                  ],
                ),
              ),
            ),
    );
  }

  AppBar _buildAppBar(
      ThemeHandler themeProvider, FoldersProvider foldersProvider) {
    return AppBar(
      elevation: 0, // AppBar 그림자 제거
      centerTitle: true, // 제목을 항상 가운데로 배치
      title: DecorateText(
        text: foldersProvider.currentFolder?.folderName ?? _directoryName,
        fontSize: 24,
        color: themeProvider.primaryColor,
      ),
      leading: foldersProvider.currentFolder?.parentFolder != null
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: themeProvider.primaryColor,
              ),
              onPressed: () {
                foldersProvider.moveToParentFolder(
                    foldersProvider.currentFolder!.parentFolder?.folderId);
              },
            )
          : null, // 루트 폴더일 경우 leading 버튼 없음
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0), // 우측에 여백 추가
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.create_new_folder,
                  color: themeProvider.primaryColor,
                  size: 24,
                ),
                onPressed: () => _showCreateFolderDialog(), // 폴더 생성 다이얼로그 호출
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'rename') {
                    _showRenameFolderDialog(foldersProvider);
                  } else if (value == 'move') {
                    _showMoveFolderDialog(foldersProvider); // 폴더 이동 다이얼로그 호출
                  } else if (value == 'delete') {
                    _showDeleteFolderDialog(foldersProvider);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: DecorateText(
                      text: '폴더 이름 수정하기',
                      fontSize: 18,
                      color: Colors.blue,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'move',
                    child: DecorateText(
                      text: '폴더 위치 변경하기',
                      fontSize: 18,
                      color: Colors.purple,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: DecorateText(
                      text: '폴더 삭제하기',
                      fontSize: 18,
                      color: Colors.red,
                    ),
                  ),
                ],
                icon: Icon(
                  Icons.more_vert,
                  color: themeProvider.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 폴더 생성 다이얼로그 출력
  Future<void> _showCreateFolderDialog() async {
    await _showFolderNameDialog(
      dialogTitle: '폴더 생성',
      defaultFolderName: '', // 폴더 생성 시에는 기본값이 없음
      onFolderNameSubmitted: (folderName) async {
        await _createFolder(folderName);
      },
    );
  }

  Future<void> _createFolder(String folderName) async {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    await foldersProvider.createFolder(folderName);
  }

  Future<void> _showRenameFolderDialog(FoldersProvider foldersProvider) async {
    await _showFolderNameDialog(
      dialogTitle: '폴더 이름 변경',
      defaultFolderName: foldersProvider.currentFolder?.folderName ?? '',
      onFolderNameSubmitted: (newName) async {
        await _renameFolder(newName);
      },
    );
  }

  Future<void> _renameFolder(
    String newName,
  ) async {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    await foldersProvider.updateFolder(newName, null);
  }

  // 폴더 이동 다이얼로그 출력
  Future<void> _showMoveFolderDialog(FoldersProvider foldersProvider) async {
    // 루트 폴더인지 확인
    if (foldersProvider.currentFolder?.parentFolder == null) {
      _showCannotMoveRootFolderDialog();
      return;
    }

    final selectedFolder = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => FolderSelectionDialog(),
    );

    if (selectedFolder != null) {
      final selectedFolderId = selectedFolder['folderId'];
      await foldersProvider.updateFolder(null, selectedFolderId); // 부모 폴더 변경
    }
  }

  // 루트 폴더 위치 변경 시 경고 다이얼로그 출력
  Future<void> _showCannotMoveRootFolderDialog() async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: DecorateText(
            text: '폴더 위치 변경 불가',
            fontSize: 24,
            color: themeProvider.primaryColor,
          ),
          content: DecorateText(
            text: '메인 폴더는 위치를 변경할 수 없습니다.',
            fontSize: 20,
            color: themeProvider.primaryColor,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const DecorateText(
                text: '확인',
                fontSize: 20,
                color: Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteFolderDialog(FoldersProvider foldersProvider) async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    bool isRootFolder = foldersProvider.currentFolder?.parentFolder == null;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: DecorateText(
            text: '폴더 삭제',
            fontSize: 24,
            color: themeProvider.primaryColor,
          ),
          content: DecorateText(
            text: isRootFolder ? '메인 폴더는 삭제할 수 없습니다!' : '정말로 이 폴더를 삭제하시겠습니까?',
            fontSize: 20,
            color: themeProvider.primaryColor,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const DecorateText(
                text: '취소',
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            if (!isRootFolder) // 루트 폴더가 아닌 경우에만 삭제 버튼을 표시
              TextButton(
                onPressed: () async {
                  if (foldersProvider.currentFolder != null) {
                    await foldersProvider
                        .deleteFolder(foldersProvider.currentFolder!.folderId);
                    Navigator.pop(context); // 다이얼로그 닫기
                  }
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

  Widget _buildLoginPrompt(ThemeHandler themeProvider) {
    return Center(
      child: DecorateText(
        text: '로그인을 통해 작성한 오답노트를 확인해보세요!',
        fontSize: 24,
        color: themeProvider.primaryColor,
      ),
    );
  }

  Future<void> _showFolderNameDialog({
    required String dialogTitle,
    required String defaultFolderName,
    required Function(String) onFolderNameSubmitted,
  }) async {
    TextEditingController folderNameController =
        TextEditingController(text: defaultFolderName);
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: DecorateText(
            text: dialogTitle,
            fontSize: 24,
            color: themeProvider.primaryColor,
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: TextField(
              controller: folderNameController,
              style: TextStyle(
                color: themeProvider.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'font1',
              ),
              decoration: InputDecoration(
                hintText: '폴더 이름을 입력하세요',
                hintStyle: TextStyle(
                  color: themeProvider.desaturateColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'font1',
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: themeProvider.primaryColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: themeProvider.primaryColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: themeProvider.primaryColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 20.0, horizontal: 12.0),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const DecorateText(
                text: '취소',
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () async {
                if (folderNameController.text.isNotEmpty) {
                  onFolderNameSubmitted(folderNameController.text);
                  Navigator.pop(context);
                }
              },
              child: DecorateText(
                text: '확인',
                fontSize: 20,
                color: themeProvider.primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSortDropdown(ThemeHandler themeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0), // 왼쪽 여백 추가
          child: Consumer<FoldersProvider>(
            builder: (context, foldersProvider, child) {
              int problemCount = foldersProvider.problems.length;
              return DecorateText(
                text: '문제 수 : $problemCount',
                fontSize: 18,
                color: themeProvider.primaryColor,
              );
            },
          ),
        ),
        DropdownButton<String>(
          value: _selectedSortOption,
          iconEnabledColor: themeProvider.primaryColor,
          underline: Container(),
          items: [
            DropdownMenuItem(
              value: 'name',
              child: DecorateText(
                text: '이름순',
                fontSize: 18,
                color: themeProvider.primaryColor,
              ),
            ),
            DropdownMenuItem(
              value: 'newest',
              child: DecorateText(
                text: '최신순',
                fontSize: 18,
                color: themeProvider.primaryColor,
              ),
            ),
            DropdownMenuItem(
              value: 'oldest',
              child: DecorateText(
                text: '오래된순',
                fontSize: 18,
                color: themeProvider.primaryColor,
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedSortOption = value!;
              _directoryService.sortProblems(_selectedSortOption);
            });
          },
        ),
      ],
    );
  }

  Widget _buildFolderAndProblemGrid(ThemeHandler themeProvider) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 가로/세로 모드에 따라 그리드 레이아웃을 변경
          int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
          if (constraints.maxWidth > 900) {
            crossAxisCount = 4;
          }

          return Consumer<FoldersProvider>(
            builder: (context, foldersProvider, child) {
              var folders = foldersProvider.currentFolder?.subFolders ?? [];
              var problems = foldersProvider.problems;

              if (folders.isEmpty && problems.isEmpty) {
                return Center(
                  child: DecorateText(
                    text: '폴더나 문제가 등록되어 있지 않습니다!',
                    fontSize: 24,
                    color: themeProvider.primaryColor,
                  ),
                );
              }

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: folders.length + problems.length,
                itemBuilder: (context, index) {
                  if (index < folders.length) {
                    var folder = folders[index];
                    return _buildFolderTile(folder, themeProvider);
                  } else {
                    var problem = problems[index - folders.length];
                    return _buildProblemTile(problem, themeProvider);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFolderTile(
      FolderThumbnailModel folder, ThemeHandler themeProvider) {
    return GestureDetector(
      onTap: () {
        // 폴더를 클릭했을 때 해당 폴더로 이동
        Provider.of<FoldersProvider>(context, listen: false)
            .fetchFolderContents(folderId: folder.folderId);
      },
      child: DragTarget<ProblemModel>(
        onAccept: (problem) async {
          // 문제를 드롭하면 폴더로 이동
          await _moveProblemToFolder(problem, folder.folderId);
        },
        builder: (context, candidateData, rejectedData) {
          return LayoutBuilder(
            builder: (context, constraints) {
              double height = constraints.maxHeight * 0.8;
              double width = constraints.maxWidth * 0.9;
              return GridTile(
                child: Column(
                  children: <Widget>[
                    Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Icon(
                        Icons.folder,
                        color: themeProvider.primaryColor,
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      folder.folderName,
                      style: TextStyle(
                        fontFamily: 'font1',
                        color: themeProvider.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }

  Widget _buildProblemTile(ProblemModel problem, ThemeHandler themeProvider) {
    return GestureDetector(
      onTap: () {
        // 문제를 터치했을 때 페이지로 이동
        _directoryService.navigateToProblemDetail(context, problem.problemId);
      },
      child: LongPressDraggable<ProblemModel>(
        data: problem,
        delay: const Duration(milliseconds: 500), // 딜레이를 500ms로 줄임
        onDragStarted: () {
          HapticFeedback.lightImpact(); // 드래그 시작 시 가벼운 햅틱 피드백 제공
        },
        feedback: Material(
          child: SizedBox(
            width: 100,
            height: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: DisplayImage(
                imagePath: problem.processImageUrl,
                fit: BoxFit.cover, // 문제 썸네일을 드래그 시 보여줌
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5, // 드래그 중일 때의 UI
          child: _problemTileContent(problem, themeProvider),
        ),
        child: _problemTileContent(problem, themeProvider), // 기본 UI
      ),
    );
  }

  Widget _problemTileContent(ProblemModel problem, ThemeHandler themeProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double height = constraints.maxHeight * 0.8;
        double width = constraints.maxWidth * 0.9;
        return GridTile(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: themeProvider.primaryColor,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6.0),
                    child: DisplayImage(
                      imagePath: problem.processImageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                problem.reference ?? '제목 없음',
                style: TextStyle(
                  fontFamily: 'font1',
                  color: themeProvider.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              DecorateText(
                text: problem.updateAt != null
                    ? '작성 일시 : ${formatDateTime(problem.createdAt!)}'
                    : '작성 일시 : 정보 없음',
                color: themeProvider.desaturateColor,
                fontSize: 12,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _moveProblemToFolder(ProblemModel problem, int? folderId) async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    if (problem.problemId == null || folderId == null) {
      log('Problem ID or folderId is null. Cannot move the problem.');
      return; // 문제 ID 또는 폴더 ID가 null이면 실행하지 않음
    }

    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    await foldersProvider.updateProblem(
      ProblemRegisterModel(
        problemId: problem.problemId,
        folderId: folderId, // 폴더 ID로 문제를 이동
        isProcess: false,
      ),
    );

    if (mounted) {
      SnackBarDialog.showSnackBar(
        context: context,
        message: '문제가 이동되었습니다!',
        backgroundColor: Theme.of(context).primaryColor,
      );
    }
  }
}
