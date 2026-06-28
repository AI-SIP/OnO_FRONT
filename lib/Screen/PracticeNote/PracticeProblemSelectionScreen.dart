import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteDetailModel.dart';
import 'package:ono/Model/Tag/TagModel.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/PracticeNote/PracticeTitleWriteScreen.dart';
import 'package:ono/Service/Api/Tag/TagService.dart';
import 'package:provider/provider.dart';

import '../../Model/Folder/FolderThumbnailModel.dart';
import '../../Model/PracticeNote/PracticeNoteRegisterModel.dart';
import '../../Model/PracticeNote/PracticeNoteUpdateModel.dart';
import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Problem/ProblemThumbnailCard.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/NoteIconHandler.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/FoldersProvider.dart';
import '../../Provider/ProblemsProvider.dart';
import '../../Util/AppErrorReporter.dart';
import '../../Util/AppSnackBar.dart';

enum _PracticeSearchMode { folder, tag, title }

class PracticeProblemSelectionScreen extends StatefulWidget {
  final PracticeNoteDetailModel? practiceModel;

  const PracticeProblemSelectionScreen({super.key, this.practiceModel});

  @override
  _PracticeProblemSelectionScreenState createState() =>
      _PracticeProblemSelectionScreenState();
}

class _PracticeProblemSelectionScreenState
    extends State<PracticeProblemSelectionScreen> {
  _PracticeSearchMode _searchMode = _PracticeSearchMode.folder;

  int? selectedFolderId;
  List<ProblemModel> selectedProblems = [];
  List<FolderThumbnailModel> allFolders = [];
  late final List<int> _originalProblemIds;

  final TagService _tagService = TagService();
  final TextEditingController _titleQueryController = TextEditingController();
  Timer? _titleDebounce;
  List<TagModel> _tags = [];
  int? _selectedTagId;
  bool _isLoadingTags = false;
  String _titleQuery = '';

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
    _titleQueryController.addListener(_onTitleQueryChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialFolders();
      _loadTags();
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
    _titleQueryController.removeListener(_onTitleQueryChanged);
    _titleDebounce?.cancel();
    _titleQueryController.dispose();
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

  void _onTitleQueryChanged() {
    if (_searchMode != _PracticeSearchMode.title) return;
    _titleDebounce?.cancel();
    _titleDebounce = Timer(const Duration(milliseconds: 300), () {
      final query = _titleQueryController.text.trim();
      if (query == _titleQuery) return;
      _searchTitleProblems(query, isInitial: true);
    });
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
    } catch (e, stackTrace) {
      await _reportAndShowLoadError(
        e,
        stackTrace,
        source: 'practice_selection_load_folders',
        message: '폴더 목록을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFolders = false;
        });
      }
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
    } catch (e, stackTrace) {
      await _reportAndShowLoadError(
        e,
        stackTrace,
        source: 'practice_selection_load_more_folders',
        message: '폴더 목록을 더 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFolders = false;
        });
      }
    }
  }

  Future<void> _loadTags() async {
    setState(() => _isLoadingTags = true);
    try {
      final fetched = await _tagService.getMyTags();
      fetched.sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;
      setState(() {
        _tags = fetched;
        if (_tags.isNotEmpty) {
          _selectedTagId = _tags.first.tagId;
        }
      });
    } catch (e, stackTrace) {
      await _reportAndShowLoadError(
        e,
        stackTrace,
        source: 'practice_selection_load_tags',
        message: '태그 목록을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingTags = false);
      }
    }
  }

  Future<void> _switchSearchMode(_PracticeSearchMode mode) async {
    if (_searchMode == mode) return;

    setState(() {
      _searchMode = mode;
      _currentFolderProblems = [];
      _problemCursor = null;
      _problemHasNext = false;
      _isLoadingProblems = false;
    });

    if (mode == _PracticeSearchMode.folder) {
      if (selectedFolderId != null) {
        await _loadInitialProblems(selectedFolderId!);
      }
      return;
    }

    if (mode == _PracticeSearchMode.tag) {
      if (_selectedTagId != null) {
        await _loadTagProblems(_selectedTagId!, isInitial: true);
      }
      return;
    }

    final query = _titleQueryController.text.trim();
    _titleQuery = query;
    if (query.isNotEmpty) {
      await _searchTitleProblems(query, isInitial: true);
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
    } catch (e, stackTrace) {
      await _reportAndShowLoadError(
        e,
        stackTrace,
        source: 'practice_selection_load_folder_problems',
        message: '문제 목록을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProblems = false;
        });
      }
    }
  }

  Future<void> _loadTagProblems(int tagId, {required bool isInitial}) async {
    if (_isLoadingProblems) return;

    if (isInitial) {
      setState(() {
        _selectedTagId = tagId;
        _isLoadingProblems = true;
        _currentFolderProblems = [];
        _problemCursor = null;
        _problemHasNext = false;
      });
    } else {
      if (!_problemHasNext) return;
      setState(() {
        _isLoadingProblems = true;
      });
    }

    try {
      final problemsProvider = context.read<ProblemsProvider>();
      final response = await problemsProvider.loadMoreTagProblemsV2(
        tagId: tagId,
        cursor: isInitial ? null : _problemCursor,
        size: 20,
      );

      if (!mounted) return;
      setState(() {
        if (isInitial) {
          _currentFolderProblems = response.content;
        } else {
          _currentFolderProblems.addAll(response.content);
        }
        _problemCursor = response.nextCursor;
        _problemHasNext = response.hasNext;
      });
    } catch (e, stackTrace) {
      await _reportAndShowLoadError(
        e,
        stackTrace,
        source: 'practice_selection_load_tag_problems',
        message: '태그 문제를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProblems = false;
        });
      }
    }
  }

  Future<void> _searchTitleProblems(String query,
      {required bool isInitial}) async {
    if (_isLoadingProblems) return;

    final trimmed = query.trim();
    _titleQuery = trimmed;

    if (trimmed.isEmpty) {
      setState(() {
        _currentFolderProblems = [];
        _problemCursor = null;
        _problemHasNext = false;
        _isLoadingProblems = false;
      });
      return;
    }

    if (isInitial) {
      setState(() {
        _isLoadingProblems = true;
        _currentFolderProblems = [];
        _problemCursor = null;
        _problemHasNext = false;
      });
    } else {
      if (!_problemHasNext) return;
      setState(() {
        _isLoadingProblems = true;
      });
    }

    try {
      final problemsProvider = context.read<ProblemsProvider>();
      final response = await problemsProvider.loadMoreTitleProblemsV2(
        query: trimmed,
        cursor: isInitial ? null : _problemCursor,
        size: 20,
      );

      if (!mounted) return;
      setState(() {
        if (isInitial) {
          _currentFolderProblems = response.content;
        } else {
          _currentFolderProblems.addAll(response.content);
        }
        _problemCursor = response.nextCursor;
        _problemHasNext = response.hasNext;
      });
    } catch (e, stackTrace) {
      await _reportAndShowLoadError(
        e,
        stackTrace,
        source: 'practice_selection_search_title_problems',
        message: '검색 결과를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProblems = false;
        });
      }
    }
  }

  Future<void> _loadMoreProblems() async {
    if (_isLoadingProblems || !_problemHasNext) return;

    if (_searchMode == _PracticeSearchMode.folder) {
      if (selectedFolderId == null) return;
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
      } catch (e, stackTrace) {
        await _reportAndShowLoadError(
          e,
          stackTrace,
          source: 'practice_selection_load_more_folder_problems',
          message: '문제 목록을 더 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingProblems = false;
          });
        }
      }
      return;
    }

    if (_searchMode == _PracticeSearchMode.tag) {
      if (_selectedTagId == null) return;
      await _loadTagProblems(_selectedTagId!, isInitial: false);
      return;
    }

    await _searchTitleProblems(_titleQuery, isInitial: false);
  }

  Future<void> _reportAndShowLoadError(
    Object error,
    StackTrace stackTrace, {
    required String source,
    required String message,
  }) async {
    await AppErrorReporter.report(
      error,
      stackTrace,
      source: source,
      severity: AppErrorSeverity.error,
    );

    if (mounted) {
      AppSnackBar.showError(message);
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              final useFolderSplit =
                  _searchMode == _PracticeSearchMode.folder &&
                      constraints.maxWidth >= 600;

              return Column(
                children: [
                  SizedBox(height: screenHeight * 0.012),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildSearchModeSelector(themeProvider),
                  ),
                  SizedBox(height: useFolderSplit ? 16 : 24),
                  if (useFolderSplit)
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            width: constraints.maxWidth * 0.30,
                            child: _buildSideFolderList(themeProvider),
                          ),
                          Container(width: 1, color: Colors.grey[200]),
                          Expanded(
                            child: _buildProblemList(
                              context,
                              themeProvider,
                              expand: false,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _buildSearchFilter(context, themeProvider),
                    SizedBox(
                      height:
                          _searchMode == _PracticeSearchMode.folder ? 16 : 26,
                    ),
                    _buildProblemList(context, themeProvider),
                  ],
                  _buildSubmitButton(context, themeProvider),
                ],
              );
            },
          ),
        ));
  }

  AppBar _buildAppBar(ThemeHandler themeProvider) {
    return AppBar(
      centerTitle: true,
      title: StandardText(
        text: '추가할 오답노트 선택',
        fontSize: 18,
        color: themeProvider.primaryColor,
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildSearchFilter(BuildContext context, ThemeHandler themeProvider) {
    if (_searchMode == _PracticeSearchMode.folder) {
      return _buildFolderList(context, themeProvider);
    }
    if (_searchMode == _PracticeSearchMode.tag) {
      return _buildTagFilterBar(themeProvider);
    }
    return _buildTitleSearchBar(themeProvider);
  }

  Widget _buildSearchModeSelector(ThemeHandler themeProvider) {
    Widget modeChip({
      required _PracticeSearchMode mode,
      required String label,
    }) {
      final selected = _searchMode == mode;
      return Expanded(
        child: InkWell(
          onTap: () => _switchSearchMode(mode),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? themeProvider.primaryColor.withOpacity(0.08)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    selected ? themeProvider.primaryColor : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _modeIcon(mode),
                  size: 15,
                  color:
                      selected ? themeProvider.primaryColor : Colors.grey[600]!,
                ),
                const SizedBox(width: 5),
                StandardText(
                  text: label,
                  fontSize: 12,
                  color:
                      selected ? themeProvider.primaryColor : Colors.grey[700]!,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          modeChip(mode: _PracticeSearchMode.folder, label: '폴더'),
          const SizedBox(width: 6),
          modeChip(mode: _PracticeSearchMode.tag, label: '태그'),
          const SizedBox(width: 6),
          modeChip(mode: _PracticeSearchMode.title, label: '제목'),
        ],
      ),
    );
  }

  IconData _modeIcon(_PracticeSearchMode mode) {
    switch (mode) {
      case _PracticeSearchMode.folder:
        return Icons.folder_outlined;
      case _PracticeSearchMode.tag:
        return Icons.sell_outlined;
      case _PracticeSearchMode.title:
        return Icons.title_outlined;
    }
  }

  Widget _buildTagFilterBar(ThemeHandler themeProvider) {
    if (_isLoadingTags) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: CircularProgressIndicator(),
      );
    }

    if (_tags.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: StandardText(
            text: '생성된 태그가 없습니다.',
            fontSize: 13,
            color: Colors.grey[600]!,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _tags.map((tag) {
              final selected = _selectedTagId == tag.tagId;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => _loadTagProblems(tag.tagId, isInitial: true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? themeProvider.primaryColor.withOpacity(0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? themeProvider.primaryColor
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: StandardText(
                      text: '#${tag.name}',
                      fontSize: 12,
                      color: selected
                          ? themeProvider.primaryColor
                          : Colors.grey[700]!,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSearchBar(ThemeHandler themeProvider) {
    final baseTextStyle = const StandardText(text: '').getTextStyle();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _titleQueryController,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) => _searchTitleProblems(value, isInitial: true),
        style: baseTextStyle.copyWith(
          fontSize: 14,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: '제목으로 검색 (예: 수특)',
          hintStyle: baseTextStyle.copyWith(
            color: Colors.grey[500],
            fontSize: 13,
          ),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: themeProvider.primaryColor.withOpacity(0.5),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFolderList(BuildContext context, ThemeHandler themeProvider) {
    double screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    final folderGap = isWide ? 18.0 : 12.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
    final rootFolderId = context.read<FoldersProvider>().rootFolder?.folderId;
    final displayName =
        folder.folderId == rootFolderId ? '책장' : folder.folderName;

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
              text: displayName.length > 10
                  ? '${displayName.substring(0, 10)}..'
                  : displayName,
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

  Widget _buildSideFolderList(ThemeHandler themeProvider) {
    final rootFolderId = context.read<FoldersProvider>().rootFolder?.folderId;
    return Container(
      color: Colors.grey[50],
      child: ListView.builder(
        controller: _folderScrollController,
        itemCount:
            allFolders.length + (_folderHasNext || _isLoadingFolders ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == allFolders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final folder = allFolders[index];
          final isSelected = selectedFolderId == folder.folderId;
          final displayName =
              folder.folderId == rootFolderId ? '책장' : folder.folderName;

          return InkWell(
            onTap: () async {
              if (selectedFolderId == folder.folderId) return;
              setState(() => selectedFolderId = folder.folderId);
              await _loadInitialProblems(folder.folderId);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              color: isSelected
                  ? themeProvider.primaryColor.withValues(alpha: 0.08)
                  : Colors.transparent,
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.folder : Icons.folder_outlined,
                    size: 18,
                    color: isSelected
                        ? themeProvider.primaryColor
                        : Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StandardText(
                      text: displayName,
                      fontSize: 13,
                      color: isSelected
                          ? themeProvider.primaryColor
                          : Colors.black54,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.normal,
                      fontFamily:
                          isSelected ? 'PretendardBold' : 'PretendardLight',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProblemList(
    BuildContext context,
    ThemeHandler themeProvider, {
    bool expand = true,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16),
  }) {
    final list = Padding(
      padding: padding,
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
                    final isSelected = selectedProblems.any((selectedProblem) =>
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
    );

    return expand ? Expanded(child: list) : list;
  }

  Widget _buildEmptyProblemMessage() {
    final message = _searchMode == _PracticeSearchMode.title
        ? (_titleQuery.isEmpty ? '검색어를 입력해주세요.' : '검색 결과가 없습니다.')
        : '작성한 오답노트가 없습니다!';

    if (_searchMode == _PracticeSearchMode.title && _titleQuery.isEmpty) {
      return Center(
        child: StandardText(
          text: message,
          color: Colors.grey[600]!,
          fontSize: 15,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/Icon/PencilDetail.svg',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 16),
                StandardText(
                  text: message,
                  color: Colors.black,
                  fontSize: 16,
                ),
              ],
            ),
          ),
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
    final title =
        problem.reference?.isNotEmpty == true ? problem.reference! : '제목 없음';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ProblemThumbnailCard(
        title: title,
        imageUrl: problemImageUrl,
        tags: problem.tags,
        solveCount: problem.solveCount,
        lastSolvedAt: problem.lastSolvedAt,
        themeProvider: themeProvider,
        trailing: isSelected
            ? Icon(Icons.check_circle,
                color: themeProvider.primaryColor, size: 25)
            : const Icon(Icons.circle_outlined, color: Colors.grey),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, ThemeHandler themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
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
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Expanded(
                child: Center(
                  child: StandardText(
                    text: "다음",
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
      ),
    );
  }

  void _showSelectProblemDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const StandardText(
                      text: '문제 선택 필요',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const StandardText(
                  text: '하나 이상의 문제를 선택해주세요!',
                  fontSize: 15,
                  color: Colors.black87,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      backgroundColor: themeProvider.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const StandardText(
                      text: '확인',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute}';
  }
}
