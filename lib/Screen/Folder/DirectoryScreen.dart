import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Model/Folder/FolderModel.dart';
import 'package:ono/Model/Problem/ProblemRegisterModel.dart';
import 'package:ono/Module/Dialog/SnackBarDialog.dart';
import 'package:ono/Module/Theme/NoteIconHandler.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Model/Problem/ProblemThumbnailModel.dart';
import '../../Module/Image/DisplayImage.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Module/Util/FolderPickerDialog.dart';
import '../../Provider/UserProvider.dart';
import '../ProblemDetail/ProblemDetailScreen.dart';
import 'UserGuideScreen.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  _DirectoryScreenState createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  bool modalShown = false;
  bool _isSelectionMode = false; // 선택 모드 활성화 여부
  final List<int> _selectedFolderIds = []; // 선택된 폴더 ID 리스트
  final List<int> _selectedProblemIds = []; // 선택된 문제 ID 리스트

  @override
  void initState() {
    super.initState();
    _isSelectionMode = false; // 선택 모드 활성화 여부

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (!modalShown && userProvider.isFirstLogin) {
        modalShown = true;
        userProvider.changeIsFirstLogin();
        _showUserGuideModal();
      }
    });
  }

  void _showUserGuideModal() async {
    FirebaseAnalytics.instance.logEvent(name: 'show_user_guide_modal');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 스크롤 가능 모달 설정
      backgroundColor: Colors.transparent, // 투명 배경
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.6, // 화면 높이의 50% 차지
          child: UserGuideScreen(
            onFinish: () {
              Navigator.of(context).pop(); // 모달 닫기
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);
    final foldersProvider = Provider.of<FoldersProvider>(context);

    return PopScope(
        canPop: true,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            if (foldersProvider.currentFolder?.parentFolder?.folderId != null) {
              foldersProvider.moveToFolder(
                  foldersProvider.currentFolder?.parentFolder?.folderId);
            }
            return;
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(themeProvider, foldersProvider), // 상단 AppBar 추가
          body: !(authService.isLoggedIn == LoginStatus.login)
              ? _buildLoginPrompt(themeProvider)
              : RefreshIndicator(
                  onRefresh: () async {
                    await fetchFoldersAndProblems();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildProblemCountSection(themeProvider),
                        const SizedBox(
                          height: 10,
                        ),
                        _buildFolderAndProblemGrid(themeProvider),
                      ],
                    ),
                  ),
                ),
        ));
  }

  AppBar _buildAppBar(
      ThemeHandler themeProvider, FoldersProvider foldersProvider) {
    return AppBar(
      elevation: 0, // AppBar 그림자 제거
      centerTitle: true, // 제목을 항상 가운데로 배치
      backgroundColor: Colors.white,
      title: StandardText(
        text: _isSelectionMode
            ? '삭제할 항목 선택'
            : ((foldersProvider.currentFolder?.parentFolder?.folderId != null &&
                    foldersProvider.currentFolder?.folderName != null)
                ? foldersProvider.currentFolder!.folderName
                : '책장'),
        fontSize: 20,
        color: themeProvider.primaryColor,
      ),
      actions: [
        FloatingActionButton(
          heroTag: 'create_folder',
          onPressed: () {
            FirebaseAnalytics.instance
                .logEvent(name: 'folder_create_button_click');
            _showCreateFolderDialog(); // 기존에 상단에서 호출하던 폴더 생성 로직
          },
          backgroundColor: Colors.transparent,
          elevation: 0, // 그림자 제거
          child: SvgPicture.asset(
            "assets/Icon/addNote.svg",
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0), // 우측에 여백 추가
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _isSelectionMode ? Icons.close : Icons.more_vert,
                  color: themeProvider.primaryColor,
                ),
                onPressed: () {
                  if (_isSelectionMode) {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedFolderIds.clear();
                      _selectedProblemIds.clear();
                    });
                  } else {
                    _showActionDialog(foldersProvider, themeProvider);
                  }
                }, // 더보기 버튼을 눌렀을 때 다이얼로그
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
        final foldersProvider =
            Provider.of<FoldersProvider>(context, listen: false);
        await foldersProvider.createFolder(folderName);
      },
    );
  }

  void _showActionDialog(
      FoldersProvider foldersProvider, ThemeHandler themeProvider) {
    FirebaseAnalytics.instance
        .logEvent(name: 'directory_Screen_action_dialog_click');

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 20.0, horizontal: 10.0), // 패딩 추가
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0), // 타이틀 아래 여백 추가
                  child: StandardText(
                    text: '공책 편집하기', // 타이틀 텍스트
                    fontSize: 20,
                    color: themeProvider.primaryColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ListTile(
                    leading: const Icon(Icons.add, color: Colors.black),
                    title: const StandardText(
                      text: '공책 추가하기',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      FirebaseAnalytics.instance.logEvent(
                          name: 'directory_create_folder_button_click');
                      _showCreateFolderDialog();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0), // 텍스트 간격 조정
                  child: ListTile(
                    leading: const Icon(Icons.edit, color: Colors.black),
                    title: const StandardText(
                      text: '공책 이름 수정하기',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    onTap: () {
                      Navigator.pop(context);

                      FirebaseAnalytics.instance
                          .logEvent(name: 'directory_rename_button_click');

                      _showRenameFolderDialog(foldersProvider);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0), // 텍스트 간격 조정
                  child: ListTile(
                    leading: const Icon(Icons.folder_open, color: Colors.black),
                    title: const StandardText(
                      text: '공책 위치 변경하기',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    onTap: () {
                      Navigator.pop(context);

                      FirebaseAnalytics.instance
                          .logEvent(name: 'directory_path_change_button_click');

                      _showMoveFolderDialog(foldersProvider);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0), // 텍스트 간격 조정
                  child: ListTile(
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                    title: const StandardText(
                      text: '공책 편집하기',
                      fontSize: 16,
                      color: Colors.red,
                    ),
                    onTap: () {
                      Navigator.pop(context);

                      // 편집 모드 활성화
                      setState(() {
                        _isSelectionMode = true;
                      });

                      FirebaseAnalytics.instance
                          .logEvent(name: 'directory_enable_edit_mode');
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 정렬 옵션을 선택하는 다이얼로그
  Widget _buildProblemCountSection(ThemeHandler themeProvider) {
    return GestureDetector(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(top: 10, left: 10, right: 10), // 왼쪽 여백 추가
            child: Consumer<FoldersProvider>(
              builder: (context, foldersProvider, child) {
                int problemCount = foldersProvider.currentProblems.length;
                return StandardText(
                  text: '오답노트 수 : $problemCount',
                  fontSize: 15,
                  color: themeProvider.primaryColor,
                );
              },
            ),
          ),
        ],
      ),
    );
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
        newName, foldersProvider.currentFolder!.folderId, null);
  }

  // 폴더 이동 다이얼로그 출력
  Future<void> _showMoveFolderDialog(FoldersProvider foldersProvider) async {
    // 루트 폴더인지 확인
    if (foldersProvider.currentFolder?.parentFolder?.folderId == null) {
      _showCannotMoveRootFolderDialog();
      return;
    }

    final int? selectedFolderId = await showDialog<int?>(
      context: context,
      builder: (context) => const FolderPickerDialog(),
    );

    if (selectedFolderId != null) {
      await foldersProvider.updateFolder(
          foldersProvider.currentFolder!.folderName,
          foldersProvider.currentFolder!.folderId,
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
          title: const StandardText(
            text: '공책 위치 변경 불가',
            fontSize: 18,
            color: Colors.black,
          ),
          content: const StandardText(
            text: '책장의 위치를 변경할 수 없습니다.',
            fontSize: 16,
            color: Colors.black,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: StandardText(
            text: dialogTitle,
            fontSize: 18,
            color: Colors.black,
          ),
          content: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.001, // 좌우 여백 추가
            ),
            child: TextField(
              controller: folderNameController,
              style: standardTextStyle.copyWith(
                color: Colors.black,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: '공책 이름을 입력하세요',
                hintStyle: standardTextStyle.copyWith(
                  color: ThemeHandler.desaturatenColor(Colors.black),
                  fontSize: 14,
                ),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.5),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02,
                    horizontal: screenWidth * 0.03),
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

  Widget _buildFolderAndProblemGrid(ThemeHandler themeProvider) {
    return Expanded(
        child: Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Consumer<FoldersProvider>(
                builder: (context, foldersProvider, child) {
                  var subFolderIds =
                      foldersProvider.currentFolder?.subFolderList ?? [];
                  var currentProblems = foldersProvider.currentProblems;

                  if (subFolderIds.isEmpty && currentProblems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/Icon/GreenNote.svg', // 아이콘 경로
                            width: 100, // 적절한 크기 설정
                            height: 100,
                          ),
                          const SizedBox(height: 40), // 아이콘과 텍스트 사이 간격
                          const StandardText(
                            text: '작성한 오답노트를\n공책에 저장해 관리하세요!',
                            fontSize: 16,
                            color: Colors.black,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // 플로팅 버튼의 공책 생성 로직과 동일하게 동작
                              FirebaseAnalytics.instance
                                  .logEvent(name: 'folder_create_button_click');
                              _showCreateFolderDialog();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  themeProvider.primaryColor, // primaryColor 적용
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const StandardText(
                              text: '공책 추가하기',
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: subFolderIds.length + currentProblems.length,
                    itemBuilder: (context, index) {
                      if (index < subFolderIds.length) {
                        var subFolderId = subFolderIds[index].folderId;

                        var subFolder = foldersProvider.getFolder(subFolderId);
                        return _buildFolderTile(
                            subFolder, themeProvider, index);
                      } else {
                        var problem =
                            currentProblems[index - subFolderIds.length];
                        return _buildProblemTile(problem, themeProvider);
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        if (_isSelectionMode) _buildBottomActionButtons(themeProvider),
      ],
    ));
  }

  Widget _buildFolderTile(
      FolderModel folder, ThemeHandler themeProvider, int index) {
    final isSelected = _selectedFolderIds.contains(folder.folderId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // 아이템 간 간격 추가
      child: GestureDetector(
        onTap: () {
          // 폴더를 클릭했을 때 해당 폴더로 이동
          FirebaseAnalytics.instance
              .logEvent(name: 'move_to_folder', parameters: {
            'folder_id': folder.folderId,
          });

          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedFolderIds.remove(folder.folderId);
              } else {
                _selectedFolderIds.add(folder.folderId);
              }
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return const DirectoryScreen();
              }),
            );

            Provider.of<FoldersProvider>(context, listen: false)
                .moveToFolder(folder.folderId);
          }
        },
        child: LongPressDraggable<FolderModel>(
          data: folder,
          feedback: Material(
            child: SizedBox(
              width: 50,
              height: 70,
              child: SvgPicture.asset(
                NoteIconHandler.getNoteIcon(index), // 헬퍼 클래스로 아이콘 설정
                width: 50,
                height: 50,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _folderTileContent(folder, themeProvider, index),
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
              return DragTarget<FolderModel>(
                onAcceptWithDetails: (details) async {
                  // 폴더를 드롭하면 자식 폴더로 이동
                  await _moveFolderToNewParent(details.data, folder.folderId);
                },
                builder: (context, candidateData, rejectedData) {
                  return _folderTileContent(folder, themeProvider, index);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _folderTileContent(
      FolderModel folder, ThemeHandler themeProvider, int index) {
    final isSelected = _selectedFolderIds.contains(folder.folderId);
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.red)
                : SvgPicture.asset(
                    NoteIconHandler.getNoteIcon(index),
                    width: 30,
                    height: 30,
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StandardText(
                  text: folder.folderName.isNotEmpty
                      ? folder.folderName
                      : '제목 없음',
                  color: Colors.black,
                  fontSize: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemTile(ProblemModel problem, ThemeHandler themeProvider) {
    final isSelected = _selectedProblemIds.contains(problem.problemId);

    final imageUrl = null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // 아이템 간 간격 추가
      child: GestureDetector(
        onTap: () {
          FirebaseAnalytics.instance
              .logEvent(name: 'move_to_problem', parameters: {
            'problem_id': problem.problemId,
          });

          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedProblemIds.remove(problem.problemId);
              } else {
                _selectedProblemIds.add(problem.problemId);
              }
            });
          } else {
            navigateToProblemDetail(context, problem.problemId);
          }
        },
        child: LongPressDraggable<ProblemModel>(
          data: problem,
          feedback: Material(
            child: SizedBox(
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
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _problemTileContent(problem, themeProvider),
          ),
          onDragStarted: () {
            HapticFeedback.lightImpact();
          },
          child: DragTarget<FolderModel>(
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
    final isSelected = _selectedProblemIds.contains(problem.problemId);
    final imageUrl = null;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 70,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: isSelected
                  ? Icon(Icons.check, color: themeProvider.primaryColor)
                  : DisplayImage(
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
                    /*
                    _getTemplateIcon(problem.templateType!),
                    const SizedBox(width: 8),

                     */
                    Flexible(
                      child: StandardText(
                        text: (problem.reference != null &&
                                problem.reference!.isNotEmpty)
                            ? problem.reference!
                            : '제목 없음',
                        color: Colors.black,
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
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButtons(ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: () {
                // 선택 모드 취소
                setState(() {
                  _isSelectionMode = false;
                  _selectedFolderIds.clear();
                  _selectedProblemIds.clear();
                });
              },
              child: const StandardText(
                text: '취소하기',
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: () {
                if (_selectedFolderIds.isNotEmpty ||
                    _selectedProblemIds.isNotEmpty) {
                  _confirmDelete();
                }
              },
              child: const StandardText(
                text: '삭제하기',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedItems() async {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);

    try {
      // 선택된 폴더 삭제
      if (_selectedFolderIds.isNotEmpty) {
        await foldersProvider.deleteFolders(_selectedFolderIds);
      }

      // 선택된 문제 삭제
      if (_selectedProblemIds.isNotEmpty) {
        await problemsProvider.deleteProblems(_selectedProblemIds);
      }

      setState(() {
        _isSelectionMode = false;
        _selectedFolderIds.clear();
        _selectedProblemIds.clear();
      });

      // 삭제 성공 메시지
      SnackBarDialog.showSnackBar(
        context: context,
        message: '선택된 항목이 삭제되었습니다!',
        backgroundColor: Theme.of(context).primaryColor,
      );

      await foldersProvider
          .fetchFolderContent(foldersProvider.currentFolder!.folderId);
    } catch (e) {
      // 에러 처리
      log('Error deleting items: $e');
      SnackBarDialog.showSnackBar(
        context: context,
        message: '항목 삭제 중 오류가 발생했습니다.',
        backgroundColor: Colors.red,
      );
    }
  }

  void _confirmDelete() {
    final theme = Provider.of<ThemeHandler>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const StandardText(
          text: '삭제 확인',
          fontSize: 18,
          color: Colors.black,
        ),
        content: const StandardText(
          text: '선택한 항목을 정말 삭제하시겠습니까?',
          fontSize: 16,
          color: Colors.black,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), // 취소
            child: const StandardText(
              text: '취소',
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // 다이얼로그 닫고
              _deleteSelectedItems(); // 실제 삭제 실행
            },
            child: StandardText(
              text: '확인',
              fontSize: 14,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }

  Future<void> _moveFolderToNewParent(
      FolderModel folder, int? newParentFolderId) async {
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
    if (folderId == null) {
      log('Problem ID or folderId is null. Cannot move the problem.');
      return; // 문제 ID 또는 폴더 ID가 null이면 실행하지 않음
    }

    FirebaseAnalytics.instance.logEvent(name: 'problem_path_edit', parameters: {
      'problem_id': problem.problemId!,
      'target_folder_id': folderId,
    });

    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);
    await problemsProvider.updateProblem(ProblemRegisterModel(
      problemId: problem.problemId,
      folderId: folderId, // 폴더 ID로 문제를 이동
    ));

    if (mounted) {
      SnackBarDialog.showSnackBar(
        context: context,
        message: '오답노트가 이동되었습니다!',
        backgroundColor: Theme.of(context).primaryColor,
      );
    }
  }

  List<ProblemThumbnailModel> loadProblems() {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);

    if (foldersProvider.currentProblems.isNotEmpty) {
      return foldersProvider.currentProblems
          .map((problem) => ProblemThumbnailModel.fromProblem(problem))
          .toList();
    } else {
      log('No problems loaded');
      return [];
    }
  }

  Future<void> fetchFoldersAndProblems() async {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);

    await foldersProvider.fetchFolderContent(null);
  }

  void navigateToProblemDetail(BuildContext context, int problemId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        //builder: (context) => ProblemDetailScreen(problemId: problemId),
        builder: (context) => ProblemDetailScreen(problemId: problemId),
      ),
    ).then((value) {
      if (value == true) {
        fetchFoldersAndProblems();
      }
    });
  }
}
