import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteDetailModel.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/PracticeNote/PracticeTitleWriteScreen.dart';
import 'package:provider/provider.dart';

import '../../Model/Folder/FolderThumbnailModel.dart';
import '../../Model/PracticeNote/PracticeNoteRegisterModel.dart';
import '../../Model/PracticeNote/PracticeNoteUpdateModel.dart';
import '../../Model/Problem/ProblemModel.dart';
import '../../Model/Problem/TemplateType.dart';
import '../../Module/Image/DisplayImage.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/NoteIconHandler.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/FoldersProvider.dart';
import '../../Provider/ProblemsProvider.dart';

class PracticeProblemSelectionScreen extends StatefulWidget {
  final PracticeNoteDetailModel? practiceModel;

  const PracticeProblemSelectionScreen({super.key, this.practiceModel});

  @override
  _PracticeProblemSelectionScreenState createState() =>
      _PracticeProblemSelectionScreenState();
}

class _PracticeProblemSelectionScreenState
    extends State<PracticeProblemSelectionScreen> {
  int? selectedFolderId;
  List<ProblemModel> selectedProblems = [];
  List<FolderThumbnailModel> allFolders = [];
  late final List<int> _originalProblemIds;

  // 폴더 페이징 상태
  int? _folderCursor;
  bool _folderHasNext = false;
  bool _isLoadingFolders = false;

  // 문제 페이징 상태
  List<ProblemModel> _currentFolderProblems = [];
  int? _problemCursor;
  bool _problemHasNext = false;
  bool _isLoadingProblems = false;

  late ScrollController _folderScrollController;
  late ScrollController _problemScrollController;

  @override
  void initState() {
    super.initState();
    _folderScrollController = ScrollController();
    _problemScrollController = ScrollController();
    _folderScrollController.addListener(_onFolderScroll);
    _problemScrollController.addListener(_onProblemScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialFolders();
      if (widget.practiceModel != null) {
        _originalProblemIds = widget.practiceModel!.problemIdList;
        _fetchProblems();
      } else {
        _originalProblemIds = [];
      }
    });
  }

  @override
  void dispose() {
    _folderScrollController.removeListener(_onFolderScroll);
    _problemScrollController.removeListener(_onProblemScroll);
    _folderScrollController.dispose();
    _problemScrollController.dispose();
    super.dispose();
  }

  void _onFolderScroll() {
    if (_folderScrollController.position.pixels >=
        _folderScrollController.position.maxScrollExtent * 0.8) {
      if (_folderHasNext && !_isLoadingFolders) {
        _loadMoreFolders();
      }
    }
  }

  void _onProblemScroll() {
    if (_problemScrollController.position.pixels >=
        _problemScrollController.position.maxScrollExtent * 0.8) {
      if (_problemHasNext && !_isLoadingProblems) {
        _loadMoreProblems();
      }
    }
  }

  Future<void> _fetchProblems() async {
    final practiceNoteProvider = context.read<ProblemPracticeProvider>();

    await practiceNoteProvider.moveToPractice(widget.practiceModel!.practiceId);
    final problemModelList = practiceNoteProvider.currentProblems;
    setState(() => selectedProblems = problemModelList);
  }

  Future<void> _loadInitialFolders() async {
    setState(() {
      _isLoadingFolders = true;
    });

    try {
      final foldersProvider = context.read<FoldersProvider>();
      final response =
          await foldersProvider.folderService.getAllFolderThumbnailsV2(
        cursor: null,
        size: 20,
      );

      setState(() {
        allFolders = response.content;
        _folderCursor = response.nextCursor;
        _folderHasNext = response.hasNext;

        // 첫 번째 폴더를 선택하고 해당 폴더의 문제 로드
        if (allFolders.isNotEmpty) {
          selectedFolderId = allFolders[0].folderId;
          _loadInitialProblems(allFolders[0].folderId);
        }
      });
    } catch (e) {
      print('Error loading folders: $e');
    } finally {
      setState(() {
        _isLoadingFolders = false;
      });
    }
  }

  Future<void> _loadMoreFolders() async {
    if (_isLoadingFolders || !_folderHasNext) return;

    setState(() {
      _isLoadingFolders = true;
    });

    try {
      final foldersProvider = context.read<FoldersProvider>();
      final response =
          await foldersProvider.folderService.getAllFolderThumbnailsV2(
        cursor: _folderCursor,
        size: 20,
      );

      setState(() {
        allFolders.addAll(response.content);
        _folderCursor = response.nextCursor;
        _folderHasNext = response.hasNext;
      });
    } catch (e) {
      print('Error loading more folders: $e');
    } finally {
      setState(() {
        _isLoadingFolders = false;
      });
    }
  }

  Future<void> _loadInitialProblems(int folderId) async {
    setState(() {
      _isLoadingProblems = true;
      _currentFolderProblems = [];
      _problemCursor = null;
      _problemHasNext = false;
    });

    try {
      final problemsProvider = context.read<ProblemsProvider>();
      final response = await problemsProvider.loadMoreFolderProblemsV2(
        folderId: folderId,
        cursor: null,
        size: 20,
      );

      setState(() {
        _currentFolderProblems = response.content;
        _problemCursor = response.nextCursor;
        _problemHasNext = response.hasNext;
      });
    } catch (e) {
      print('Error loading problems: $e');
    } finally {
      setState(() {
        _isLoadingProblems = false;
      });
    }
  }

  Future<void> _loadMoreProblems() async {
    if (_isLoadingProblems || !_problemHasNext || selectedFolderId == null)
      return;

    setState(() {
      _isLoadingProblems = true;
    });

    try {
      final problemsProvider = context.read<ProblemsProvider>();
      final response = await problemsProvider.loadMoreFolderProblemsV2(
        folderId: selectedFolderId!,
        cursor: _problemCursor,
        size: 20,
      );

      setState(() {
        _currentFolderProblems.addAll(response.content);
        _problemCursor = response.nextCursor;
        _problemHasNext = response.hasNext;
      });
    } catch (e) {
      print('Error loading more problems: $e');
    } finally {
      setState(() {
        _isLoadingProblems = false;
      });
    }
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
            await foldersProvider.moveToRootFolder();
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
    final isWide = screenWidth >= 600;
    final folderGap = isWide ? 18.0 : 12.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: SizedBox(
        height: 120,
        child: ListView.builder(
          controller: _folderScrollController,
          scrollDirection: Axis.horizontal,
          itemCount:
              allFolders.length + (_folderHasNext || _isLoadingFolders ? 1 : 0),
          itemBuilder: (context, index) {
            // 로딩 인디케이터
            if (index == allFolders.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final folder = allFolders[index];
            return GestureDetector(
              onTap: () async {
                setState(() {
                  selectedFolderId = folder.folderId;
                });
                // 선택한 폴더의 문제들을 불러옵니다
                await _loadInitialProblems(folder.folderId);
              },
              child: Padding(
                padding: EdgeInsets.only(right: folderGap),
                child: _buildFolderThumbnail(folder, themeProvider),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFolderThumbnail(
      FolderThumbnailModel folder, ThemeHandler themeProvider) {
    bool isSelected = selectedFolderId == folder.folderId; // 선택된 폴더인지 확인
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    final folderNameWidth = isWide ? 120.0 : screenWidth * 0.2;

    return Opacity(
      opacity: isSelected ? 1.0 : 0.5, // 선택된 폴더가 아니라면 흐리게 표시
      child: Column(
        children: [
          SvgPicture.asset(
            NoteIconHandler.getNoteIcon(allFolders.indexOf(folder)),
            width: 60,
            height: 60,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: folderNameWidth,
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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: _isLoadingProblems && _currentFolderProblems.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _currentFolderProblems.isNotEmpty
                ? ListView.builder(
                    controller: _problemScrollController,
                    itemCount: _currentFolderProblems.length +
                        (_problemHasNext || _isLoadingProblems ? 1 : 0),
                    itemBuilder: (context, index) {
                      // 로딩 인디케이터
                      if (index == _currentFolderProblems.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final problem = _currentFolderProblems[index];
                      final isSelected = selectedProblems.any(
                          (selectedProblem) =>
                              selectedProblem.problemId == problem.problemId);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedProblems.removeWhere(
                                  (p) => p.problemId == problem.problemId);
                            } else {
                              selectedProblems.add(problem);
                            }
                          });
                        },
                        child: _problemTileContent(
                            problem, themeProvider, isSelected),
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
    final problemImageUrl = problem.problemImageDataList != null &&
            problem.problemImageDataList!.isNotEmpty
        ? problem.problemImageDataList!.first.imageUrl
        : null;

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
                imagePath: problemImageUrl,
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
                    //_getTemplateIcon(problem.templateType!),
                    //const SizedBox(width: 8),
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
      width: MediaQuery.of(context).size.width * 0.7,
      child: ElevatedButton(
        onPressed: selectedProblems.isNotEmpty
            ? () {
                final newIds =
                    selectedProblems.map((p) => p.problemId).toList();

                // 추가된 문제: newIds 에는 있지만 원본에는 없는 것
                final addList = newIds
                    .where((id) => !_originalProblemIds.contains(id))
                    .toList();
                // 삭제된 문제: 원본에는 있고 newIds에는 없는 것
                final removeList = _originalProblemIds
                    .where((id) => !newIds.contains(id))
                    .toList();

                if (widget.practiceModel != null) {
                  // 수정 모드
                  final updateModel = PracticeNoteUpdateModel(
                    practiceNoteId: widget.practiceModel!.practiceId,
                    practiceTitle: widget.practiceModel!.practiceTitle,
                    addProblemIdList: addList,
                    removeProblemIdList: removeList,
                  );
                  // 다음 화면으로 updateModel 넘기기
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PracticeTitleWriteScreen(
                        practiceNoteUpdateModel: updateModel,
                        practiceNoteDetailModel: widget.practiceModel!,
                      ),
                    ),
                  );
                } else {
                  // 신규 등록 모드 → 기존대로 RegisterModel
                  final registerModel = PracticeNoteRegisterModel(
                    practiceId: null,
                    practiceTitle: "",
                    registerProblemIdList: newIds,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PracticeTitleWriteScreen(
                        practiceRegisterModel: registerModel,
                      ),
                    ),
                  );
                }
              }
            : () => _showSelectProblemDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: themeProvider.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(10),
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
                fontSize: 12,
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
