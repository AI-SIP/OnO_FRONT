import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Tag/TagModel.dart';
import '../../Module/Dialog/SnackBarDialog.dart';
import '../../Module/Image/ImagePickerHandler.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/FoldersProvider.dart';
import '../../Provider/ProblemsProvider.dart';
import '../../Provider/ScreenIndexProvider.dart';
import '../../Provider/UserProvider.dart';
import '../../Service/Api/FileUpload/FileUploadService.dart';
import '../../Service/Api/Problem/ProblemService.dart';
import '../../Service/Api/Tag/TagService.dart';
import '../../Util/AppErrorReporter.dart';
import 'TagSelectionScreen.dart';
import 'Widget/ProblemDraftCard.dart';

class MultiProblemRegisterScreen extends StatefulWidget {
  final int? initialFolderId;

  const MultiProblemRegisterScreen({
    super.key,
    this.initialFolderId,
  });

  @override
  State<MultiProblemRegisterScreen> createState() =>
      _MultiProblemRegisterScreenState();
}

class _MultiProblemRegisterScreenState
    extends State<MultiProblemRegisterScreen> {
  static const double _indicatorItemExtent = 48;

  final PageController _pageController = PageController();
  final ScrollController _indicatorScrollController = ScrollController();
  final TagService _tagService = TagService();
  final FileUploadService _fileUploadService = FileUploadService();
  final ProblemService _problemService = ProblemService();

  final List<_ProblemDraft> _drafts = [];
  final List<TagModel> _availableTags = [];

  int _currentIndex = 0;
  double _indicatorViewportWidth = 0;
  bool _isLoadingTags = false;
  bool _isSubmitting = false;
  bool _isApplyingAutoTitle = false;

  @override
  void initState() {
    super.initState();
    _drafts.add(
      _ProblemDraft(
        solvedAt: DateTime.now(),
        folderId: widget.initialFolderId,
      ),
    );
    _refreshAutoTitles();
    _loadTags();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _indicatorScrollController.dispose();
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoadingTags = true);
    try {
      final fetched = await _tagService.getMyTags();
      fetched.sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;
      setState(() {
        _availableTags
          ..clear()
          ..addAll(fetched);
      });
    } catch (e) {
      log('태그 목록 조회 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingTags = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildTopBar(themeProvider),
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _drafts.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          _centerIndicatorOn(index);
        },
        itemBuilder: (context, index) {
          final draft = _drafts[index];
          return ProblemDraftCard(
            problemImages: draft.problemImages,
            answerImages: draft.answerImages,
            titleController: draft.titleController,
            memoController: draft.memoController,
            selectedDate: draft.solvedAt,
            selectedFolderId: draft.folderId,
            selectedTagIds: draft.tagIds,
            availableTags: _availableTags,
            isLoadingTags: _isLoadingTags,
            onAddProblemImage: () => _pickImages(index, isProblemImage: true),
            onAddAnswerImage: () => _pickImages(index, isProblemImage: false),
            onRemoveProblemImage: (imageIndex) => setState(
              () => draft.problemImages.removeAt(imageIndex),
            ),
            onRemoveAnswerImage: (imageIndex) => setState(
              () => draft.answerImages.removeAt(imageIndex),
            ),
            onTitleChanged: (_) {
              if (!_isApplyingAutoTitle) {
                draft.hasUserEditedTitle = true;
              }
            },
            onDateChanged: (date) => setState(() => draft.solvedAt = date),
            onFolderPicked: (folderId) => _updateDraftFolder(index, folderId),
            onTagsChanged: (result) => _applyTags(index, result),
            onTagRemoved: (tagId) => setState(() => draft.tagIds.remove(tagId)),
          );
        },
      ),
      bottomNavigationBar: _buildBottomActions(themeProvider),
    );
  }

  PreferredSizeWidget _buildTopBar(ThemeHandler themeProvider) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(112),
      child: SafeArea(
        bottom: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
          child: Column(
            children: [
              SizedBox(
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: themeProvider.primaryColor,
                        ),
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(
                      height: 48,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          StandardText(
                            text: '오답노트 여러장 작성',
                            fontSize: 15,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                    if (_drafts.length > 1)
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: _isSubmitting ? null : _removeCurrentDraft,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _buildPageIndicator(themeProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(ThemeHandler themeProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _indicatorViewportWidth = constraints.maxWidth;
        return Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            controller: _indicatorScrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_drafts.length, (index) {
                final isSelected = index == _currentIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: _isSubmitting ? null : () => _moveToPage(index),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 44,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? themeProvider.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: themeProvider.primaryColor
                                      .withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: StandardText(
                          text: '${index + 1}',
                          fontSize: 13,
                          color: isSelected
                              ? Colors.white
                              : themeProvider.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActions(ThemeHandler themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextButton(
              onPressed: _isSubmitting ? null : _submitAll,
              style: TextButton.styleFrom(
                backgroundColor: themeProvider.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: StandardText(
                text: '${_drafts.length}개 등록하기',
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextButton(
              onPressed: _isSubmitting || _currentIndex == 0
                  ? null
                  : _moveToPreviousDraft,
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: StandardText(
                text: '이전',
                fontSize: 15,
                color: _currentIndex == 0 ? Colors.grey[400]! : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextButton(
              onPressed: _isSubmitting ? null : _moveToNextDraft,
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: const StandardText(
                text: '다음',
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages(int draftIndex,
      {required bool isProblemImage}) async {
    final imagePicker = ImagePickerHandler();
    imagePicker.showImagePicker(
      context,
      (XFile? file) {
        if (file == null || !mounted) return;
        setState(() {
          final target = _drafts[draftIndex];
          if (isProblemImage) {
            target.problemImages.add(file);
          } else {
            target.answerImages.add(file);
          }
        });
      },
      onMultipleImagesPicked: (files) {
        if (files.isEmpty || !mounted) return;
        setState(() {
          final target = _drafts[draftIndex];
          if (isProblemImage) {
            target.problemImages.addAll(files);
          } else {
            target.answerImages.addAll(files);
          }
        });
      },
    );
  }

  void _applyTags(int draftIndex, TagSelectionResult result) {
    setState(() {
      _drafts[draftIndex].tagIds
        ..clear()
        ..addAll(result.selectedTagIds);
      _mergeAvailableTags(result.availableTags);
    });
  }

  void _updateDraftFolder(int draftIndex, int? folderId) {
    setState(() {
      _drafts[draftIndex].folderId = folderId;
      _refreshAutoTitles();
    });
  }

  void _mergeAvailableTags(List<TagModel> tags) {
    final existingIds = _availableTags.map((tag) => tag.tagId).toSet();
    for (final tag in tags) {
      if (!existingIds.contains(tag.tagId)) {
        _availableTags.add(tag);
        existingIds.add(tag.tagId);
      }
    }
    _availableTags.sort((a, b) => a.name.compareTo(b.name));
  }

  void _moveToPreviousDraft() {
    if (_currentIndex == 0) return;
    _moveToPage(_currentIndex - 1);
  }

  void _moveToNextDraft() {
    if (_currentIndex < _drafts.length - 1) {
      _moveToPage(_currentIndex + 1);
      return;
    }

    final previous = _drafts[_currentIndex];
    setState(() {
      _drafts.add(previous.nextDraft());
      _currentIndex = _drafts.length - 1;
      _refreshAutoTitles();
    });
    _moveToPage(_currentIndex);
  }

  void _removeCurrentDraft() {
    if (_drafts.length <= 1) return;

    final removedIndex = _currentIndex;
    final removedDraft = _drafts.removeAt(removedIndex);
    removedDraft.dispose();

    setState(() {
      if (_currentIndex >= _drafts.length) {
        _currentIndex = _drafts.length - 1;
      }
      _refreshAutoTitles();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pageController.hasClients) return;
      _pageController.jumpToPage(_currentIndex);
      _centerIndicatorOn(_currentIndex);
    });
  }

  void _moveToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _centerIndicatorOn(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_indicatorScrollController.hasClients ||
          _indicatorViewportWidth <= 0) {
        return;
      }

      final targetOffset = (index * _indicatorItemExtent) -
          (_indicatorViewportWidth / 2) +
          (_indicatorItemExtent / 2);
      final clampedOffset = targetOffset.clamp(
        0.0,
        _indicatorScrollController.position.maxScrollExtent,
      );

      _indicatorScrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _submitAll() async {
    final invalidIndex = _drafts.indexWhere((draft) {
      return draft.problemImages.isEmpty;
    });
    if (invalidIndex != -1) {
      await _moveToInvalidDraft(invalidIndex);
      if (!mounted) return;
      SnackBarDialog.showSnackBar(
        context: context,
        message: '문제 이미지를 추가해 주세요.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final progress = ValueNotifier<int>(0);
    setState(() => _isSubmitting = true);
    _showProgressDialog(progress);

    try {
      for (var index = 0; index < _drafts.length; index++) {
        await _registerDraft(_drafts[index], index);
        progress.value = index + 1;
      }
    } catch (e, stackTrace) {
      log('멀티 오답노트 등록 실패: $e');
      log(stackTrace.toString());
      unawaited(
        AppErrorReporter.report(
          e,
          stackTrace,
          source: 'multi_problem_register',
          severity: AppErrorSeverity.error,
        ),
      );
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        SnackBarDialog.showSnackBar(
          context: context,
          message: '오답노트 등록에 실패했습니다. 잠시 후 다시 시도해주세요.',
          backgroundColor: Colors.red,
        );
      }
      progress.dispose();
      return;
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    progress.dispose();
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    Provider.of<ScreenIndexProvider>(context, listen: false)
        .setSelectedIndex(0);
    SnackBarDialog.showSnackBar(
      context: context,
      message: '${_drafts.length}개의 문제가 등록되었습니다.',
      backgroundColor: themeProvider.primaryColor,
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _moveToInvalidDraft(int index) async {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _showProgressDialog(ValueNotifier<int> progress) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final themeProvider = Provider.of<ThemeHandler>(dialogContext);
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            child: ValueListenableBuilder<int>(
              valueListenable: progress,
              builder: (context, value, _) {
                final total = _drafts.length;
                final progressValue = total == 0 ? 0.0 : value / total;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.library_add_check_outlined,
                        color: themeProvider.primaryColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const StandardText(
                      text: '오답노트 등록 중',
                      fontSize: 17,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 6),
                    StandardText(
                      text: '$value / $total',
                      fontSize: 13,
                      color: Colors.grey[600]!,
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 8,
                        backgroundColor:
                            themeProvider.primaryColor.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          themeProvider.primaryColor,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _registerDraft(_ProblemDraft draft, int index) async {
    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);

    final problemImageUrls =
        await _fileUploadService.uploadMultipleImageFiles(draft.problemImages);
    final answerImageUrls =
        await _fileUploadService.uploadMultipleImageFiles(draft.answerImages);
    final reference = _generateReference(draft, index);

    final registeredProblemId = await _problemService.registerProblemV2(
      problemId: null,
      memo: draft.memoController.text.trim(),
      reference: reference,
      folderId: draft.folderId,
      solvedAt: draft.solvedAt,
      problemImageUrls: problemImageUrls,
      answerImageUrls: answerImageUrls,
      tagIds: draft.tagIds.toList(),
    );

    await _runPostSaveTask(
      () => _problemService.requestProblemAnalysis(
        registeredProblemId,
        showErrorSnackBar: false,
      ),
      source: 'multi_problem_register_analysis_request',
    );

    await _runPostSaveTask(
      () => problemsProvider.fetchProblem(
        registeredProblemId,
        showErrorSnackBar: false,
      ),
      source: 'multi_problem_register_detail_refresh',
    );
    await problemsProvider.updateProblemCount(1);

    await _runPostSaveTask(
      () => userProvider.fetchUserInfo(showErrorSnackBar: false),
      source: 'multi_problem_register_user_refresh',
    );

    if (draft.folderId != null) {
      await _runPostSaveTask(
        () => foldersProvider.refreshFolder(draft.folderId!),
        source: 'multi_problem_register_folder_refresh',
      );
    } else {
      final rootFolder = foldersProvider.rootFolder;
      if (rootFolder != null) {
        await _runPostSaveTask(
          () => foldersProvider.refreshFolder(rootFolder.folderId),
          source: 'multi_problem_register_root_refresh',
        );
      }
    }
  }

  String _generateReference(_ProblemDraft targetDraft, int targetIndex) {
    final title = targetDraft.titleController.text.trim();
    if (title.isNotEmpty) return title;

    return _buildAutoTitle(targetDraft, targetIndex);
  }

  void _refreshAutoTitles() {
    _isApplyingAutoTitle = true;
    for (var i = 0; i < _drafts.length; i++) {
      final draft = _drafts[i];
      if (!draft.hasUserEditedTitle) {
        draft.titleController.text = _buildAutoTitle(draft, i);
      }
    }
    _isApplyingAutoTitle = false;
  }

  String _buildAutoTitle(_ProblemDraft targetDraft, int targetIndex) {
    final folderName = _resolveFolderName(targetDraft.folderId);
    var order = 0;
    for (var i = 0; i <= targetIndex; i++) {
      if (_drafts[i].folderId == targetDraft.folderId) {
        order++;
      }
    }
    return '$folderName $order';
  }

  String _resolveFolderName(int? folderId) {
    if (folderId == null) return '오답노트';

    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    final currentFolder = foldersProvider.currentFolder;
    if (currentFolder != null && currentFolder.folderId == folderId) {
      return currentFolder.folderName;
    }
    for (final folder in foldersProvider.folders) {
      if (folder.folderId == folderId) {
        return folder.folderName;
      }
    }
    return '오답노트';
  }

  Future<void> _runPostSaveTask(
    Future<void> Function() task, {
    required String source,
  }) async {
    try {
      await task();
    } catch (e, stackTrace) {
      log('Post-save task failed ($source): $e');
      unawaited(
        AppErrorReporter.report(
          e,
          stackTrace,
          source: source,
          severity: AppErrorSeverity.warning,
        ),
      );
    }
  }
}

class _ProblemDraft {
  DateTime solvedAt;
  int? folderId;
  bool hasUserEditedTitle;
  final TextEditingController titleController;
  final TextEditingController memoController;
  final Set<int> tagIds;
  final List<XFile> problemImages;
  final List<XFile> answerImages;

  _ProblemDraft({
    required this.solvedAt,
    required this.folderId,
    TextEditingController? titleController,
    TextEditingController? memoController,
    Set<int>? tagIds,
    List<XFile>? problemImages,
    List<XFile>? answerImages,
  })  : hasUserEditedTitle = false,
        titleController = titleController ?? TextEditingController(),
        memoController = memoController ?? TextEditingController(),
        tagIds = tagIds ?? <int>{},
        problemImages = problemImages ?? <XFile>[],
        answerImages = answerImages ?? <XFile>[];

  _ProblemDraft nextDraft() {
    return _ProblemDraft(
      solvedAt: solvedAt,
      folderId: folderId,
      tagIds: Set<int>.from(tagIds),
    );
  }

  void dispose() {
    titleController.dispose();
    memoController.dispose();
  }
}
