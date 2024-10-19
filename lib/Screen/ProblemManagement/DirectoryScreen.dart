import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:ono/GlobalModule/Theme/SnackBarDialog.dart';
import 'package:ono/Model/LoginStatus.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:provider/provider.dart';
import '../../GlobalModule/Image/DisplayImage.dart';
import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../GlobalModule/Util/FolderSelectionDialog.dart';
import '../../Model/ProblemRegisterModel.dart';
import '../../Model/TemplateType.dart';
import '../../Service/ScreenUtil/DirectoryScreenService.dart';
import '../../Model/ProblemModel.dart';
import '../../Model/FolderThumbnailModel.dart';
import '../../Provider/UserProvider.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  _DirectoryScreenState createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final String defaultImage = 'assets/no_image.png';
  String _selectedSortOption = 'newest';

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
    final authService = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);
    final foldersProvider = Provider.of<FoldersProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
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
                    const SizedBox(height: 20,),
                    _buildFolderAndProblemGrid(themeProvider),
                  ],
                ),
              ),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 10), // 위치 조정 (약간 위로)
        child: FloatingActionButton(
          onPressed: () {
            FirebaseAnalytics.instance
                .logEvent(name: 'folder_create_button_click');
            _showCreateFolderDialog(); // 기존에 상단에서 호출하던 폴더 생성 로직
          },
          backgroundColor: themeProvider.primaryColor,
          shape: const CircleBorder(), // 동그란 모양 유지
          child: SvgPicture.asset("assets/Icon/add_note.svg", color: Colors.white,),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // 오른쪽 하단 기본 위치
    );
  }

  AppBar _buildAppBar(
      ThemeHandler themeProvider, FoldersProvider foldersProvider) {
    return AppBar(
      elevation: 0, // AppBar 그림자 제거
      centerTitle: true, // 제목을 항상 가운데로 배치
      backgroundColor: Colors.white,
      title: StandardText(
        text: (foldersProvider.currentFolder?.parentFolder != null &&
                foldersProvider.currentFolder?.folderName != null)
            ? foldersProvider.currentFolder!.folderName
            : '책장',
        fontSize: 20,
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
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'rename') {
                    FirebaseAnalytics.instance
                        .logEvent(name: 'folder_name_edit_button_click');
                    _showRenameFolderDialog(foldersProvider);
                  } else if (value == 'move') {
                    FirebaseAnalytics.instance
                        .logEvent(name: 'folder_path_move_button_click');
                    _showMoveFolderDialog(foldersProvider); // 폴더 이동 다이얼로그 호출
                  } else if (value == 'delete') {
                    FirebaseAnalytics.instance
                        .logEvent(name: 'folder_delete_button_click');
                    _showDeleteFolderDialog(foldersProvider);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'rename',
                    child: StandardText(
                      text: '공책 이름 수정하기',
                      fontSize: 14,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'move',
                    child: StandardText(
                      text: '공책 위치 변경하기',
                      fontSize: 14,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: StandardText(
                      text: '공책 삭제하기',
                      fontSize: 14,
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

  // 공책 생성 다이얼로그 출력
  Future<void> _showCreateFolderDialog() async {
    await _showFolderNameDialog(
      dialogTitle: '공책 추가',
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
      dialogTitle: '공책 이름 변경',
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
    await foldersProvider.updateFolder(
        newName, foldersProvider.currentFolderId, null);
  }

  // 폴더 이동 다이얼로그 출력
  Future<void> _showMoveFolderDialog(FoldersProvider foldersProvider) async {
    // 루트 폴더인지 확인
    if (foldersProvider.currentFolder?.parentFolder == null) {
      _showCannotMoveRootFolderDialog();
      return;
    }

    final int? selectedFolderId = await showDialog<int?>(
      context: context,
      builder: (context) => const FolderSelectionDialog(),
    );

    if (selectedFolderId != null) {
      await foldersProvider.updateFolder(
          foldersProvider.currentFolder!.folderName,
          foldersProvider.currentFolderId,
          selectedFolderId); // 부모 폴더 변경
    }
  }

  // 루트 폴더 위치 변경 시 경고 다이얼로그 출력
  Future<void> _showCannotMoveRootFolderDialog() async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: StandardText(
            text: '공책 위치 변경 불가',
            fontSize: 16,
            color: themeProvider.primaryColor,
          ),
          content: StandardText(
            text: '책장의 위치를 변경할 수 없습니다.',
            fontSize: 14,
            color: themeProvider.primaryColor,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const StandardText(
                text: '확인',
                fontSize: 14,
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
          backgroundColor: Colors.white,
          title: StandardText(
            text: '공책 삭제',
            fontSize: 16,
            color: themeProvider.primaryColor,
          ),
          content: StandardText(
            text: isRootFolder ? '책장은 삭제할 수 없습니다!' : '정말로 이 공책을 삭제하시겠습니까?',
            fontSize: 15,
            color: themeProvider.primaryColor,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const StandardText(
                text: '취소',
                fontSize: 14,
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
                    SnackBarDialog.showSnackBar(
                        context: context,
                        message: '공책이 삭제되었습니다!',
                        backgroundColor: themeProvider.primaryColor);
                  }
                },
                child: const StandardText(
                  text: '삭제',
                  fontSize: 14,
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
      child: StandardText(
        text: '로그인을 통해 작성한 오답노트를 확인해보세요!',
        fontSize: 16,
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
    final standardTextStyle = const StandardText(text: '').getTextStyle();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: StandardText(
            text: dialogTitle,
            fontSize: 18,
            color: themeProvider.primaryColor,
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: TextField(
              controller: folderNameController,
              style: standardTextStyle.copyWith(
                color: themeProvider.primaryColor,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: '공책 이름을 입력하세요',
                hintStyle: standardTextStyle.copyWith(
                  color: themeProvider.desaturateColor,
                  fontSize: 14,
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
              child: const StandardText(
                text: '취소',
                fontSize: 14,
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
              child: StandardText(
                text: '확인',
                fontSize: 14,
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
              return StandardText(
                text: '오답노트 수 : $problemCount',
                fontSize: 15,
                color: themeProvider.primaryColor,
              );
            },
          ),
        ),
        DropdownButton<String>(
          value: _selectedSortOption,
          iconEnabledColor: themeProvider.primaryColor,
          underline: Container(),
          dropdownColor: Colors.white,
          items: [
            DropdownMenuItem(
              value: 'name',
              child: StandardText(
                text: '이름순',
                fontSize: 14,
                color: themeProvider.primaryColor,
              ),
            ),
            DropdownMenuItem(
              value: 'newest',
              child: StandardText(
                text: '최신순',
                fontSize: 14,
                color: themeProvider.primaryColor,
              ),
            ),
            DropdownMenuItem(
              value: 'oldest',
              child: StandardText(
                text: '오래된순',
                fontSize: 14,
                color: themeProvider.primaryColor,
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedSortOption = value!;
              _directoryService.sortProblems(_selectedSortOption);

              FirebaseAnalytics.instance.logEvent(
                name: 'sort_option_button_click_$_selectedSortOption}',
              );
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
          return Consumer<FoldersProvider>(
            builder: (context, foldersProvider, child) {
              var folders = foldersProvider.currentFolder?.subFolders ?? [];
              var problems = foldersProvider.problems;

              if (folders.isEmpty && problems.isEmpty) {
                return Center(
                  child: StandardText(
                    text: '공책이나 오답 노트가 작성되어 있지 않습니다!',
                    fontSize: 16,
                    color: themeProvider.primaryColor,
                  ),
                );
              }

              return ListView.builder(
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

  Widget _buildFolderTile(FolderThumbnailModel folder, ThemeHandler themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // 아이템 간 간격 추가
      child: GestureDetector(
        onTap: () {
          // 폴더를 클릭했을 때 해당 폴더로 이동
          FirebaseAnalytics.instance.logEvent(name: 'move_to_folder', parameters: {
            'folder_id': folder.folderId,
          });
          Provider.of<FoldersProvider>(context, listen: false)
              .fetchFolderContents(folderId: folder.folderId);
        },
        child: LongPressDraggable<FolderThumbnailModel>(
          data: folder,
          feedback: Material(
            child: SizedBox(
              width: 75,
              height: 75,
              child: Icon(
                Icons.folder,
                color: themeProvider.primaryColor,
                size: 50,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _folderTileContent(folder, themeProvider),
          ),
          onDragStarted: () {
            HapticFeedback.lightImpact();
          },
          child: DragTarget<ProblemModel>(
            onAcceptWithDetails: (details) async {
              // 문제를 드롭하면 폴더로 이동
              await _moveProblemToFolder(details.data, folder.folderId);
            },
            builder: (context, candidateData, rejectedData) {
              return DragTarget<FolderThumbnailModel>(
                onAcceptWithDetails: (details) async {
                  // 폴더를 드롭하면 자식 폴더로 이동
                  await _moveFolderToNewParent(details.data, folder.folderId);
                },
                builder: (context, candidateData, rejectedData) {
                  return _folderTileContent(folder, themeProvider);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _folderTileContent(
      FolderThumbnailModel folder, ThemeHandler themeProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 아이콘
        Container(
          width: 75,
          height: 75,
          decoration: BoxDecoration(
            color: themeProvider.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(
            Icons.folder,
            color: themeProvider.primaryColor,
            size: 30,
          ),
        ),
        const SizedBox(width: 12), // 아이콘과 텍스트 간 간격
        // 폴더 정보 (이름)
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StandardText(
                text: folder.folderName,
                color: themeProvider.primaryColor,
                fontSize: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildProblemTile(ProblemModel problem, ThemeHandler themeProvider) {
    final imageUrl = (problem.templateType == TemplateType.simple)
        ? problem.problemImageUrl
        : problem.processImageUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // 아이템 간 간격 추가
      child: GestureDetector(
        onTap: () {
          FirebaseAnalytics.instance.logEvent(name: 'move_to_problem', parameters: {
            'problem_id': problem.problemId,
          });

          _directoryService.navigateToProblemDetail(context, problem.problemId);
        },
        child: LongPressDraggable<ProblemModel>(
          data: problem,
          feedback: Material(
            child: SizedBox(
              width: 75,
              height: 75,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: DisplayImage(
                  imagePath: imageUrl ?? defaultImage, // 이미지가 없을 경우 기본 이미지 사용
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _problemTileContent(problem, themeProvider),
          ),
          onDragStarted: () {
            HapticFeedback.lightImpact();
          },
          child: DragTarget<FolderThumbnailModel>(
            onAcceptWithDetails: (details) async {
              // 문제를 드롭하면 해당 폴더로 이동
              await _moveProblemToFolder(problem, details.data.folderId);
            },
            builder: (context, candidateData, rejectedData) {
              return _problemTileContent(problem, themeProvider);
            },
          ),
        ),
      ),
    );
  }

  Widget _problemTileContent(ProblemModel problem, ThemeHandler themeProvider) {
    final imageUrl = (problem.templateType == TemplateType.simple)
        ? problem.problemImageUrl
        : problem.processImageUrl;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 문제 이미지
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            imageUrl ?? defaultImage, // 이미지가 없을 경우 기본 이미지 사용
            width: 75,
            height: 75,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12), // 이미지와 텍스트 간 간격 추가
        // 문제 정보 (제목 및 작성 일시)
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              StandardText(
                text: problem.reference ?? '제목 없음',
                color: themeProvider.primaryColor,
                fontSize: 18,
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
      ],
    );
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }

  Widget _getTemplateIcon(
      TemplateType? templateType, ThemeHandler themeProvider) {
    switch (templateType) {
      case TemplateType.simple:
        return Icon(
          Icons.library_books_rounded,
          color: themeProvider.primaryColor,
          size: 14,
        );
      case TemplateType.clean:
        return Icon(
          Icons.brush,
          color: themeProvider.primaryColor,
          size: 14,
        );
      case TemplateType.special:
        return Icon(
          Icons.auto_awesome,
          color: themeProvider.primaryColor,
          size: 14,
        );
      default:
        return Icon(
          Icons.library_books_rounded,
          color: themeProvider.primaryColor,
          size: 14,
        );
    }
  }

  Future<void> _moveFolderToNewParent(
      FolderThumbnailModel folder, int? newParentFolderId) async {
    if (newParentFolderId == null) {
      log('New parent folder ID is null.');
      return;
    }

    FirebaseAnalytics.instance.logEvent(name: 'folder_move', parameters: {
      'folder_id': folder.folderId,
      'target_folder_id': newParentFolderId,
    });

    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    await foldersProvider.updateFolder(
        folder.folderName, folder.folderId, newParentFolderId);

    if (mounted) {
      SnackBarDialog.showSnackBar(
        context: context,
        message: '공책이 성공적으로 이동되었습니다!',
        backgroundColor: Theme.of(context).primaryColor,
      );
    }
  }

  Future<void> _moveProblemToFolder(ProblemModel problem, int? folderId) async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    if (folderId == null) {
      log('Problem ID or folderId is null. Cannot move the problem.');
      return; // 문제 ID 또는 폴더 ID가 null이면 실행하지 않음
    }

    FirebaseAnalytics.instance.logEvent(name: 'problem_path_edit', parameters: {
      'problem_id': problem.problemId!,
      'target_folder_id': folderId,
    });

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
        message: '오답노트가 이동되었습니다!',
        backgroundColor: Theme.of(context).primaryColor,
      );
    }
  }
}
