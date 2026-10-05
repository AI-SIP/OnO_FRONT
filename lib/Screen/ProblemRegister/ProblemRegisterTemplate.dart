import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Model/Problem/ProblemRegisterModel.dart';
import '../../Model/Tag/TagModel.dart';
import '../../Module/Dialog/LoadingDialog.dart';
import '../../Module/Dialog/SnackBarDialog.dart';
import '../../Module/Image/ImagePickerHandler.dart';
import '../../Module/Text/mobile_font_size.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Module/Util/FolderPickerDialog.dart';
import '../../Module/Util/FolderPickerWidget.dart';
import '../../Provider/FoldersProvider.dart';
import '../../Provider/MissionProvider.dart';
import '../../Provider/ReviewDueProvider.dart';
import '../../Provider/ProblemsProvider.dart';
import '../../Provider/ScreenIndexProvider.dart';
import '../../Provider/UserProvider.dart';
import '../../Service/Api/FileUpload/FileUploadService.dart';
import '../../Service/Api/Problem/ProblemService.dart';
import '../../Service/Api/Tag/TagService.dart';
import '../../Service/HomeWidget/HomeWidgetSyncService.dart';
import '../../Util/AiAnalysisPreference.dart';
import '../../Util/AppErrorReporter.dart';
import 'TagSelectionScreen.dart';
import 'Widget/AiAnalysisToggle.dart';
import 'Widget/DatePickerWidget.dart';
import 'Widget/ImageGridWidget.dart';
import 'Widget/LabeledTextField.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Module/Motion/TossDialog.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Util/AppAnalytics.dart';
import 'Widget/FirstNoteGuide.dart';
import '../../Module/Design/AppToast.dart';
import '../../Util/AppNavigator.dart';
import 'ProblemRegisterScreen.dart';

class ProblemRegisterTemplate extends StatefulWidget {
  final ProblemModel? problemModel;
  final bool isEditMode;
  final int? initialFolderId;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;

  /// 저장하지 않은 입력이 있는지 여기에 적는다. 화면이 뒤로 가기 전에 물어볼지 정한다.
  final ValueNotifier<bool>? unsavedChanges;

  const ProblemRegisterTemplate({
    Key? key,
    this.problemModel,
    required this.isEditMode,
    this.initialFolderId,
    this.onCancel,
    this.onSubmit,
    this.unsavedChanges,
  }) : super(key: key);

  @override
  ProblemRegisterTemplateState createState() => ProblemRegisterTemplateState();
}

class ProblemRegisterTemplateState extends State<ProblemRegisterTemplate> {
  late DateTime _selectedDate;
  late int? _selectedFolderId;
  final _titleCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  final List<XFile> _problemImages = [];
  final List<XFile> _answerImages = [];
  final List<String> _existingProblemImageUrls = [];
  final List<String> _existingAnswerImageUrls = [];
  final List<String> _deletedImageUrls = []; // 삭제할 이미지 URL 추적
  final FileUploadService _fileUploadService = FileUploadService();
  final TagService _tagService = TagService();
  final Map<String, Future<void>> _uploadTasks = {};
  final Set<String> _canceledUploadLocalPaths = {};
  final List<TagModel> _availableTags = [];
  final List<TagModel> _recommendedTags = [];
  final Set<int> _selectedTagIds = {};
  bool _isLoadingTags = false;
  bool _isLoadingRecommendations = false;
  bool _hasUserEditedTitle = false;
  bool _isApplyingDefaultTitle = false;
  String? _currentAutoTitle;

  /// 등록한 뒤 AI 분석을 요청할지. 마지막으로 고른 값을 기기에서 읽어 온다.
  bool _aiAnalysisEnabled = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isEditMode) {
      AiAnalysisPreference.load().then((enabled) {
        if (mounted) setState(() => _aiAnalysisEnabled = enabled);
      });
    }
    final problemModel = widget.problemModel;
    _selectedDate = problemModel?.solvedAt ?? DateTime.now();
    if (widget.isEditMode) {
      _selectedFolderId = problemModel?.folderId;
      // 기존 이미지 URL 로드
      _existingProblemImageUrls.addAll(
        problemModel?.problemImageDataList
                ?.map((img) => img.imageUrl)
                .toList() ??
            [],
      );
      _existingAnswerImageUrls.addAll(
        problemModel?.answerImageDataList
                ?.map((img) => img.imageUrl)
                .toList() ??
            [],
      );
    } else {
      final folderProvider =
          Provider.of<FoldersProvider>(context, listen: false);
      _selectedFolderId = widget.initialFolderId ??
          problemModel?.folderId ??
          folderProvider.currentFolder?.folderId;
    }
    _titleCtrl.text = problemModel?.reference ?? '';
    if (!widget.isEditMode && _titleCtrl.text.trim().isEmpty) {
      _setDefaultTitleForFolder(_selectedFolderId);
    }
    _memoCtrl.text = problemModel?.memo ?? '';
    _selectedTagIds.addAll(problemModel?.tagIdList ?? []);
    _initialTitle = _titleCtrl.text;
    _initialMemo = _memoCtrl.text;
    _initialTagIds = Set.of(_selectedTagIds);
    _initialFolderId = _selectedFolderId;
    _initialDate = _selectedDate;
    _initialProblemImageUrls = List.of(_existingProblemImageUrls);
    _initialAnswerImageUrls = List.of(_existingAnswerImageUrls);
    _titleCtrl.addListener(_syncUnsavedChanges);
    _memoCtrl.addListener(_syncUnsavedChanges);
    _loadMyTags();
    _loadRecommendedTags(imageUrls: _existingProblemImageUrls);
  }

  // 수정 화면에서 바뀐 것이 있는지 비교할 처음 값.
  late final String _initialTitle;
  late final String _initialMemo;
  late final Set<int> _initialTagIds;
  late final int? _initialFolderId;
  late final DateTime _initialDate;
  late final List<String> _initialProblemImageUrls;
  late final List<String> _initialAnswerImageUrls;

  /// 화면을 다시 그릴 때마다 저장하지 않은 입력이 있는지 다시 본다.
  ///
  /// 사진, 태그, 공책, 날짜는 모두 setState 로 바뀌어서 자리마다 따로 챙기지
  /// 않고 여기서 한 번에 맞춘다. 글자는 컨트롤러 리스너로 맞춘다.
  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _syncUnsavedChanges();
  }

  void _syncUnsavedChanges() {
    final notifier = widget.unsavedChanges;
    if (notifier == null) return;
    final changed = _hasUnsavedChanges();
    if (notifier.value == changed) return;
    // 공책을 바꾸면 자동 제목이 그리는 중에 바뀔 수 있다. 그리는 중에 바깥
    // 화면을 다시 그리게 하면 안 되므로 다음 프레임으로 미룬다.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) notifier.value = _hasUnsavedChanges();
      });
      return;
    }
    notifier.value = changed;
  }

  bool _hasUnsavedChanges() {
    if (_problemImages.isNotEmpty || _answerImages.isNotEmpty) return true;
    if (!widget.isEditMode) {
      // 제목은 공책 이름으로 자동으로 채워지므로, 직접 고쳤을 때만 쓴 것으로 본다.
      return _existingProblemImageUrls.isNotEmpty ||
          _existingAnswerImageUrls.isNotEmpty ||
          _memoCtrl.text.trim().isNotEmpty ||
          (_hasUserEditedTitle && _titleCtrl.text.trim().isNotEmpty) ||
          _selectedTagIds.isNotEmpty;
    }
    return _deletedImageUrls.isNotEmpty ||
        _titleCtrl.text != _initialTitle ||
        _memoCtrl.text != _initialMemo ||
        !setEquals(_selectedTagIds, _initialTagIds) ||
        _selectedFolderId != _initialFolderId ||
        _selectedDate != _initialDate ||
        !listEquals(_existingProblemImageUrls, _initialProblemImageUrls) ||
        !listEquals(_existingAnswerImageUrls, _initialAnswerImageUrls);
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_syncUnsavedChanges);
    _memoCtrl.removeListener(_syncUnsavedChanges);
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final foldersProvider = Provider.of<FoldersProvider>(context);
    if (foldersProvider.folders.isEmpty &&
        foldersProvider.currentFolder == null) {
      return;
    }
    if (!widget.isEditMode && !_hasUserEditedTitle) {
      _setDefaultTitleForFolder(_selectedFolderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    final spacing = isWide ? 50.0 : 30.0; // 태블릿: 50px, 모바일: 30px

    // 스크롤은 이 위젯을 감싸는 ProblemRegisterScreen 이 맡는다. 여기서도
    // SingleChildScrollView 를 두면 스크롤이 겹쳐서, 안쪽이 무한 높이를 받아
    // 스크롤 기능을 잃고 아래쪽 내용까지 내려가지 못한다.
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DatePickerWidget(
              selectedDate: _selectedDate,
              onDateChanged: (d) => setState(() => _selectedDate = d),
            ),
            SizedBox(height: spacing),
            FolderPickerWidget(
              selectedId: _selectedFolderId,
              onPicked: _updateSelectedFolder,
            ),
            SizedBox(height: spacing),
            _buildImageSections(isWide: isWide),
            SizedBox(height: spacing),
            LabeledTextField(
              label: '제목',
              hintText: '오답노트의 제목을 작성해 주세요!',
              icon: Icons.info,
              controller: _titleCtrl,
              maxLength: ProblemRegisterModel.referenceMaxLength,
              showClearButton: true,
              onChanged: (_) {
                if (!_isApplyingDefaultTitle) {
                  _hasUserEditedTitle = true;
                }
              },
            ),
            SizedBox(height: spacing),
            _buildTagSection(context),
            SizedBox(height: spacing),
            LabeledTextField(
              label: '메모',
              controller: _memoCtrl,
              icon: Icons.edit,
              hintText: '기록하고 싶은 내용을 간단하게 작성해 주세요!',
              maxLines: 3,
              maxLength: ProblemRegisterModel.memoMaxLength,
            ),
            if (!widget.isEditMode) ...[
              SizedBox(height: spacing),
              AiAnalysisToggle(
                value: _aiAnalysisEnabled,
                color: Provider.of<ThemeHandler>(context).primaryColor,
                onChanged: _changeAiAnalysis,
              ),
            ],
          ],
        ));
  }

  void _changeAiAnalysis(bool enabled) {
    setState(() => _aiAnalysisEnabled = enabled);
    unawaited(AiAnalysisPreference.save(enabled));
    AppAnalytics.logEvent('ai_analysis_toggle', {
      'enabled': enabled,
      'mode': 'single',
    });
  }

  Widget _buildImageSections({required bool isWide}) {
    final problemSection = _buildImageSectionContainer(
      child: ImageGridWidget(
        label: '문제 이미지',
        files: _problemImages,
        existingImageUrls: _existingProblemImageUrls,
        uploadingPaths: _uploadTasks.keys.toSet(),
        failedPaths: _failedUploadPaths,
        onRetry: (i) => _retryUpload(_problemImages[i], isProblemImage: true),
        onAdd: _pickProblemImage,
        onRemove: widget.isEditMode
            ? (i) => setState(() => _problemImages.removeAt(i))
            : _removePendingProblemImage,
        onRemoveExisting: (i) {
          widget.isEditMode
              ? setState(() {
                  final removedUrl = _existingProblemImageUrls.removeAt(i);
                  _deletedImageUrls.add(removedUrl);
                })
              : _removeUploadedProblemImage(i);
        },
        titleIconPadding: const EdgeInsets.all(8),
        titleIconSize: 20,
        titleIconBorderRadius: 8,
      ),
    );
    final answerSection = _buildImageSectionContainer(
      child: ImageGridWidget(
        label: '해설 이미지',
        files: _answerImages,
        existingImageUrls: _existingAnswerImageUrls,
        uploadingPaths: _uploadTasks.keys.toSet(),
        failedPaths: _failedUploadPaths,
        onRetry: (i) => _retryUpload(_answerImages[i], isProblemImage: false),
        onAdd: _pickAnswerImage,
        onRemove: widget.isEditMode
            ? (i) => setState(() => _answerImages.removeAt(i))
            : _removePendingAnswerImage,
        onRemoveExisting: (i) {
          widget.isEditMode
              ? setState(() {
                  final removedUrl = _existingAnswerImageUrls.removeAt(i);
                  _deletedImageUrls.add(removedUrl);
                })
              : _removeUploadedAnswerImage(i);
        },
        titleIconPadding: const EdgeInsets.all(8),
        titleIconSize: 20,
        titleIconBorderRadius: 8,
      ),
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(child: problemSection),
          const SizedBox(width: 30),
          Expanded(child: answerSection),
        ],
      );
    }

    return Column(
      children: [
        problemSection,
        const SizedBox(height: 30),
        answerSection,
      ],
    );
  }

  void _updateSelectedFolder(int? folderId) {
    setState(() => _selectedFolderId = folderId);
    if (!widget.isEditMode && !_hasUserEditedTitle) {
      _setDefaultTitleForFolder(folderId);
    }
  }

  void _setDefaultTitleForFolder(int? folderId) {
    final nextTitle =
        '${_resolveFolderName(folderId)} ${_existingProblemCountForFolder(folderId) + 1}';
    if (_currentAutoTitle == nextTitle && _titleCtrl.text == nextTitle) {
      return;
    }

    _isApplyingDefaultTitle = true;
    _currentAutoTitle = nextTitle;
    _titleCtrl.text = _currentAutoTitle!;
    _isApplyingDefaultTitle = false;
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
    final cachedName = FolderPickerDialog.getFolderNameByFolderId(folderId);
    if (cachedName != null) return cachedName;
    return '오답노트';
  }

  int _existingProblemCountForFolder(int? folderId) {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);

    if (folderId == null) {
      return foldersProvider.rootFolder?.problemIdList.length ?? 0;
    }

    final currentFolder = foldersProvider.currentFolder;
    if (currentFolder != null && currentFolder.folderId == folderId) {
      return currentFolder.problemIdList.length;
    }

    for (final folder in foldersProvider.folders) {
      if (folder.folderId == folderId) {
        return folder.problemIdList.length;
      }
    }

    return 0;
  }

  Widget _buildImageSectionContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Future<void> _pickProblemImage() async {
    final imagePicker = ImagePickerHandler();
    imagePicker.showImagePicker(
      context,
      (XFile? file) {
        if (file != null) {
          if (widget.isEditMode) {
            setState(() => _problemImages.add(file));
          } else {
            _uploadImageImmediately(file, isProblemImage: true);
          }
        }
      },
      onMultipleImagesPicked: (List<XFile> files) {
        if (widget.isEditMode) {
          setState(() => _problemImages.addAll(files));
        } else {
          for (final file in files) {
            _uploadImageImmediately(file, isProblemImage: true);
          }
        }
      },
    );
  }

  Future<void> _pickAnswerImage() async {
    final imagePicker = ImagePickerHandler();
    imagePicker.showImagePicker(
      context,
      (XFile? file) {
        if (file != null) {
          if (widget.isEditMode) {
            setState(() => _answerImages.add(file));
          } else {
            _uploadImageImmediately(file, isProblemImage: false);
          }
        }
      },
      onMultipleImagesPicked: (List<XFile> files) {
        if (widget.isEditMode) {
          setState(() => _answerImages.addAll(files));
        } else {
          for (final file in files) {
            _uploadImageImmediately(file, isProblemImage: false);
          }
        }
      },
    );
  }

  void _removePendingProblemImage(int index) {
    if (index < 0 || index >= _problemImages.length) return;
    final removed = _problemImages.removeAt(index);
    _canceledUploadLocalPaths.add(removed.path);
    _failedUploadPaths.remove(removed.path);
    setState(() {});
  }

  void _removePendingAnswerImage(int index) {
    if (index < 0 || index >= _answerImages.length) return;
    final removed = _answerImages.removeAt(index);
    _canceledUploadLocalPaths.add(removed.path);
    _failedUploadPaths.remove(removed.path);
    setState(() {});
  }

  Future<void> _removeUploadedProblemImage(int index) async {
    if (index < 0 || index >= _existingProblemImageUrls.length) return;
    final removedUrl = _existingProblemImageUrls.removeAt(index);
    setState(() {});
    await _deleteUploadedImage(removedUrl);
    await _loadRecommendedTags(imageUrls: _existingProblemImageUrls);
  }

  Future<void> _removeUploadedAnswerImage(int index) async {
    if (index < 0 || index >= _existingAnswerImageUrls.length) return;
    final removedUrl = _existingAnswerImageUrls.removeAt(index);
    setState(() {});
    await _deleteUploadedImage(removedUrl);
  }

  Future<void> _deleteUploadedImage(String imageUrl) async {
    try {
      await _fileUploadService.deleteImage(imageUrl);
    } catch (e) {
      if (!mounted) return;
      SnackBarDialog.showSnackBar(
        context: context,
        message: '이미지 삭제에 실패했어요.',
        backgroundColor: Colors.red,
      );
    }
  }

  /// 사진을 고른 순서. 업로드는 끝나는 순서가 제각각이라, 올라간 주소를 이
  /// 순서대로 끼워 넣는다. 전에는 끝난 순서대로 붙어서 여러 쪽짜리 문제의
  /// 쪽 순서가 바뀔 수 있었다.
  int _pickSequence = 0;
  final Map<String, int> _pickOrderByPath = {};
  final Map<String, int> _pickOrderByUrl = {};

  /// 올리지 못한 사진. 목록에서 빼지 않고 남겨 두어 눌러서 다시 올리게 한다.
  final Set<String> _failedUploadPaths = {};

  void _uploadImageImmediately(XFile file, {required bool isProblemImage}) {
    _pickOrderByPath[file.path] = _pickSequence++;
    setState(() {
      if (isProblemImage) {
        _problemImages.add(file);
      } else {
        _answerImages.add(file);
      }
    });

    _startUpload(file, isProblemImage: isProblemImage);
  }

  void _startUpload(XFile file, {required bool isProblemImage}) {
    final task = _uploadSingleImage(file, isProblemImage: isProblemImage);
    _uploadTasks[file.path] = task;
  }

  void _retryUpload(XFile file, {required bool isProblemImage}) {
    if (!_failedUploadPaths.remove(file.path)) return;
    setState(() {});
    _startUpload(file, isProblemImage: isProblemImage);
  }

  void _insertInPickOrder(List<String> urls, String url, int order) =>
      insertInPickOrder(urls, _pickOrderByUrl, url, order);

  Future<void> _uploadSingleImage(
    XFile file, {
    required bool isProblemImage,
  }) async {
    try {
      final imageUrl = await _fileUploadService.uploadImageFile(file);

      if (_canceledUploadLocalPaths.contains(file.path)) {
        await _deleteUploadedImage(imageUrl);
        return;
      }

      if (!mounted) return;
      final order = _pickOrderByPath[file.path] ?? _pickSequence++;
      setState(() {
        if (isProblemImage) {
          _problemImages.removeWhere((f) => f.path == file.path);
          _insertInPickOrder(_existingProblemImageUrls, imageUrl, order);
        } else {
          _answerImages.removeWhere((f) => f.path == file.path);
          _insertInPickOrder(_existingAnswerImageUrls, imageUrl, order);
        }
      });
      if (isProblemImage) {
        await _loadRecommendedTags(imageUrls: _existingProblemImageUrls);
      }
    } catch (e) {
      if (!mounted) return;
      // 지운 사진이면 남길 것이 없다.
      if (_canceledUploadLocalPaths.contains(file.path)) return;
      setState(() => _failedUploadPaths.add(file.path));
      AppToast.error('사진을 올리지 못했어요. 사진을 눌러 다시 올려 주세요.');
    } finally {
      _canceledUploadLocalPaths.remove(file.path);
      _uploadTasks.remove(file.path);
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _waitForPendingUploads() async {
    if (_uploadTasks.isEmpty) return;
    await Future.wait(_uploadTasks.values.toList());
  }

  Future<void> _loadMyTags() async {
    setState(() => _isLoadingTags = true);
    try {
      final fetched = await _tagService.getMyTags();
      _availableTags
        ..clear()
        ..addAll(fetched);

      final detailTags = widget.problemModel?.tags ?? const <TagModel>[];
      final existingIds = _availableTags.map((e) => e.tagId).toSet();
      for (final tag in detailTags) {
        if (!existingIds.contains(tag.tagId)) {
          _availableTags.add(tag);
        }
      }
      _availableTags.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      debugPrint('태그 목록 조회 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingTags = false);
      }
    }
  }

  void _mergeIntoAvailableTags(List<TagModel> tags) {
    final existingIds = _availableTags.map((e) => e.tagId).toSet();
    for (final tag in tags) {
      if (!existingIds.contains(tag.tagId)) {
        _availableTags.add(tag);
        existingIds.add(tag.tagId);
      }
    }
    _availableTags.sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> _loadRecommendedTags({List<String>? imageUrls}) async {
    if (!mounted) return;
    setState(() => _isLoadingRecommendations = true);
    try {
      final recommended = await _tagService.recommendTags(imageUrls: imageUrls);
      // 추천을 몇 개 보여 줬는지. 아래 tag_recommend_apply 와 나눠 보면
      // 추천을 얼마나 받아들이는지 나온다.
      AppAnalytics.logEvent('tag_recommend_shown', {
        'count': recommended.length,
        'with_image': imageUrls?.isNotEmpty ?? false,
      });
      if (!mounted) return;
      setState(() {
        _recommendedTags
          ..clear()
          ..addAll(recommended);
        _mergeIntoAvailableTags(recommended);
      });
    } catch (e) {
      debugPrint('태그 추천 조회 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingRecommendations = false);
      }
    }
  }

  void _applyRecommendedTag(TagModel tag) {
    if (_selectedTagIds.contains(tag.tagId)) return;
    if (_selectedTagIds.length >= 5) {
      SnackBarDialog.showSnackBar(
        context: context,
        message: '태그는 최대 5개까지만 선택할 수 있어요.',
        backgroundColor: Colors.orange,
      );
      return;
    }
    AppAnalytics.logEvent('tag_recommend_apply', {'mode': 'single'});
    setState(() {
      _selectedTagIds.add(tag.tagId);
      _mergeIntoAvailableTags([tag]);
    });
  }

  void _removeSelectedTag(int tagId) {
    if (!_selectedTagIds.contains(tagId)) return;
    setState(() {
      _selectedTagIds.remove(tagId);
    });
  }

  Future<void> _openTagSelectionScreen() async {
    final result = await Navigator.of(context).push<TagSelectionResult>(
      TossPageRoute(
        builder: (_) => TagSelectionScreen(
          initialTags: List<TagModel>.from(_availableTags),
          initialSelectedTagIds: Set<int>.from(_selectedTagIds),
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedTagIds
        ..clear()
        ..addAll(result.selectedTagIds);
      _availableTags
        ..clear()
        ..addAll(result.availableTags);
    });
  }

  Widget _buildTagSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Icon(
                  Icons.local_offer,
                  color: themeProvider.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              StandardText(
                text: '태그',
                fontSize: MobileFontSize.reduced(context, 16),
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 8),
              StandardText(
                text: '${_selectedTagIds.length}/5',
                fontSize: 13,
                color: Colors.grey[600]!,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoadingTags ? null : _openTagSelectionScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  minimumSize: const Size(0, 44),
                  visualDensity: VisualDensity.compact,
                ),
                child: _isLoadingTags
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const StandardText(
                        text: '태그 추가',
                        color: Colors.white,
                        fontSize: 13,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: AppColors.border),
            ),
            child: _selectedTagIds.isEmpty
                ? StandardText(
                    text: '선택된 태그가 없어요.',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTags
                        .where((tag) => _selectedTagIds.contains(tag.tagId))
                        .map((tag) => Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.small),
                                    border: Border.all(
                                      color: themeProvider.primaryColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: StandardText(
                                    text: '#${tag.name}',
                                    fontSize: 12,
                                    color: themeProvider.primaryColor,
                                  ),
                                ),
                                Positioned(
                                  top: -5,
                                  right: -5,
                                  child: PressableScale(
                                    scale: 0.85,
                                    onTap: () => _removeSelectedTag(tag.tagId),
                                    child: Container(
                                      width: 15,
                                      height: 15,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.remove,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ))
                        .toList(),
                  ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            // 서버는 사진과 상관없이 최근에 쓴 태그를 준다. 전에는 문제 사진이
            // 올라가야 보여서, 태그를 먼저 고르려는 사람은 찾지 못했다.
            child: _recommendedTags.isEmpty && !_isLoadingRecommendations
                ? const SizedBox.shrink()
                : Padding(
                    key: const ValueKey('recommended_tags'),
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 4),
                            StandardText(
                              text: '최근 사용 태그',
                              fontSize: 14,
                              color: Colors.grey[700]!,
                            ),
                            const Spacer(),
                            if (_isLoadingRecommendations)
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: themeProvider.primaryColor,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_recommendedTags.isEmpty &&
                            !_isLoadingRecommendations)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: StandardText(
                              text: '최근 사용 태그가 없어요.',
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _recommendedTags.map((tag) {
                              final isSelected =
                                  _selectedTagIds.contains(tag.tagId);
                              return Material(
                                color: Colors.transparent,
                                child: PressableScale(
                                  haptic: HapticLevel.selection,
                                  onTap: () => _applyRecommendedTag(tag),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 11, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? themeProvider.primaryColor
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.small),
                                      border: Border.all(
                                        color: isSelected
                                            ? themeProvider.primaryColor
                                            : themeProvider.primaryColor
                                                .withOpacity(0.35),
                                        width: isSelected ? 1.4 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isSelected) ...[
                                          Icon(
                                            Icons.check,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        StandardText(
                                          text: '#${tag.name}',
                                          fontSize: 12,
                                          color: isSelected
                                              ? Colors.white
                                              : themeProvider.primaryColor,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void resetAll() {
    setState(() {
      for (final file in _problemImages) {
        _canceledUploadLocalPaths.add(file.path);
      }
      for (final file in _answerImages) {
        _canceledUploadLocalPaths.add(file.path);
      }
      _titleCtrl.clear();
      _memoCtrl.clear();
      _problemImages.clear();
      _answerImages.clear();
      _failedUploadPaths.clear();
      _existingProblemImageUrls.clear();
      _existingAnswerImageUrls.clear();
      _deletedImageUrls.clear();
      _selectedTagIds.clear();
      _recommendedTags.clear();
    });
  }

  /// 작성 완료를 처리하는 중인지. 사진 업로드를 기다리는 동안에는 로딩 창이
  /// 아직 없어서, 버튼을 한 번 더 누르면 같은 오답노트가 두 번 만들어졌다.
  bool _isSubmitting = false;

  /// 방금 등록한 오답노트. 첫 오답노트면 바로 풀어 보라고 권할 때 쓴다.
  int? _registeredProblemId;

  /// 서버에 오답노트 수를 물어 방금 쓴 것이 첫 오답노트인지 본다. 앱이 들고
  /// 있는 개수는 로그인할 때 받지 않아서 믿을 수 없다. 묻지 못하면 아니라고 본다.
  Future<bool> _isFirstNote() async {
    try {
      final count = await Provider.of<ProblemsProvider>(context, listen: false)
          .getUserProblemCount(showErrorSnackBar: false);
      return count == 1;
    } catch (_) {
      return false;
    }
  }

  Future<void> submit() async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    try {
      await _submit();
    } finally {
      _isSubmitting = false;
    }
  }

  Future<void> _submit() async {
    // 등록이 끝나면 resetAll 이 입력값을 비운다. 무엇을 채워 올렸는지는
    // 지금 잡아 둔다.
    final analyticsParams = <String, Object?>{
      'problem_image_count':
          _problemImages.length + _existingProblemImageUrls.length,
      'answer_image_count':
          _answerImages.length + _existingAnswerImageUrls.length,
      'tag_count': _selectedTagIds.length,
      'has_memo': _memoCtrl.text.trim().isNotEmpty,
      'auto_title': !_hasUserEditedTitle,
    };

    // 제목 필수 입력 검증
    if (_titleCtrl.text.trim().isEmpty) {
      AppAnalytics.logEvent('problem_register_blocked', {'reason': 'title'});
      _showTitleRequiredDialog(context);
      return;
    }

    // 문제 이미지 필수 입력 검증 (신규 등록 시에만)
    if (!widget.isEditMode &&
        _problemImages.isEmpty &&
        _existingProblemImageUrls.isEmpty) {
      AppAnalytics.logEvent('problem_register_blocked', {'reason': 'image'});
      _showProblemImageRequiredDialog(context);
      return;
    }

    final canPopBeforeSubmit = Navigator.of(context).canPop();
    // 사진 업로드를 기다리는 동안에도 로딩 창을 띄워 둔다. 전에는 이 사이에
    // 아무 표시가 없었다. 로딩 창은 한 번만 띄운다. 닫자마자 다시 띄우면
    // 닫히는 쪽의 정리가 늦게 돌아 다음 hide 가 먹히지 않는다.
    LoadingDialog.show(
        context, widget.isEditMode ? '오답노트 수정 중...' : '오답노트 작성 중...');

    if (!widget.isEditMode) {
      await _waitForPendingUploads();
      if (!mounted) return;
      // 올리지 못한 사진을 빼고 저장하면 쪽이 빠진 오답노트가 된다.
      if (_failedUploadPaths.isNotEmpty) {
        LoadingDialog.hide(context);
        AppToast.error('올리지 못한 사진이 있어요. 다시 올리거나 지운 뒤 저장해 주세요.');
        return;
      }
      if (_existingProblemImageUrls.isEmpty) {
        LoadingDialog.hide(context);
        _showProblemImageRequiredDialog(context);
        return;
      }
    }

    bool shouldPop = false;
    bool isFirstNote = false;
    bool loadingHidden = false;
    try {
      if (widget.isEditMode) {
        await _updateProblem();
        shouldPop = canPopBeforeSubmit;
      } else {
        await _registerProblem();
        shouldPop = canPopBeforeSubmit;
        // 로딩 창이 떠 있는 동안 물어서 화면이 닫히기 전에 멈칫하지 않게 한다.
        isFirstNote = _registeredProblemId != null && await _isFirstNote();
      }
    } catch (e, stackTrace) {
      debugPrint('오답노트 ${widget.isEditMode ? "수정" : "등록"} 실패: $e');
      debugPrint(stackTrace.toString());
      if (mounted) {
        LoadingDialog.hide(context);
        loadingHidden = true;
        SnackBarDialog.showSnackBar(
          context: context,
          message: widget.isEditMode
              ? '오답노트 수정에 실패했어요. 잠시 후 다시 시도해 주세요.'
              : '오답노트 등록에 실패했어요. 잠시 후 다시 시도해 주세요.',
          backgroundColor: Colors.red,
        );
      }
      unawaited(
        AppErrorReporter.report(
          e,
          stackTrace,
          source: widget.isEditMode ? 'problem_update' : 'problem_register',
          severity: AppErrorSeverity.error,
        ),
      );
      return;
    } finally {
      if (mounted && !loadingHidden) {
        LoadingDialog.hide(context);
      }
    }

    if (!mounted) return;

    AppAnalytics.logEvent(
      widget.isEditMode ? 'problem_updated' : 'problem_created',
      {
        if (!widget.isEditMode) 'mode': 'single',
        if (!widget.isEditMode) 'count': 1,
        if (!widget.isEditMode) 'ai_analysis': _aiAnalysisEnabled,
        ...analyticsParams,
      },
    );

    // 1차에서는 행동 응답에 미션 진행도가 실려 오지 않는다. 등록이 끝난 뒤
    // 다시 조회해야 오답노트 미션이 바로 반영된다.
    unawaited(
      Provider.of<MissionProvider>(context, listen: false).fetchMissions(),
    );
    // 홈의 추천 복습도 다시 받는다. 전에는 앱을 다시 켜야 새 문제가 보였다.
    if (!widget.isEditMode) {
      unawaited(
        Provider.of<ReviewDueProvider>(context, listen: false).fetchReviewDue(),
      );
    }

    // 첫 오답노트면 저장 알림 대신 다음에 할 일을 알려 준다. 등록 화면이
    // 닫히거나 탭이 바뀐 뒤에 뜨도록 다음 프레임에 띄운다.
    final registeredProblemId = _registeredProblemId;
    if (isFirstNote && registeredProblemId != null) {
      final accent =
          Provider.of<ThemeHandler>(context, listen: false).primaryColor;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showFirstNoteGuide(
          problemId: registeredProblemId,
          accentColor: accent,
        );
      });
    } else {
      showSuccessDialog(context);
    }

    if (shouldPop) {
      Navigator.of(context).pop(true);
      return;
    }

    Provider.of<ScreenIndexProvider>(context, listen: false)
        .setSelectedIndex(0);
  }

  void _showTitleRequiredDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    showTossDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    StandardText(
                      text: '경고',
                      fontSize: MobileFontSize.reduced(context, 18),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 내용
                StandardText(
                  text: '제목을 입력해 주세요!',
                  fontSize: MobileFontSize.reduced(context, 15),
                  color: AppColors.textPrimary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 액션 버튼
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      backgroundColor: themeProvider.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                    ),
                    child: const StandardText(
                      text: '확인',
                      fontSize: 15,
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

  void _showProblemImageRequiredDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    showTossDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    StandardText(
                      text: '경고',
                      fontSize: MobileFontSize.reduced(context, 18),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 내용
                StandardText(
                  text: '문제 이미지를 추가해 주세요!',
                  fontSize: MobileFontSize.reduced(context, 15),
                  color: AppColors.textPrimary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 액션 버튼
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      backgroundColor: themeProvider.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                    ),
                    child: const StandardText(
                      text: '확인',
                      fontSize: 15,
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

  /// 오답노트 등록
  Future<void> _registerProblem() async {
    debugPrint('register problem');

    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    final problemService = ProblemService();
    final registeredProblemId =
        _registeredProblemId = await problemService.registerProblemV2(
      problemId: null,
      memo: ProblemRegisterModel.clampMemo(_memoCtrl.text),
      reference: ProblemRegisterModel.clampReference(_titleCtrl.text),
      solvedAt: _selectedDate,
      folderId: _selectedFolderId,
      problemImageUrls: _existingProblemImageUrls,
      answerImageUrls: _existingAnswerImageUrls,
      tagIds: _selectedTagIds.toList(),
    );

    // 홈 화면 위젯의 오늘 칸을 새로 맞춘다. 기다리지 않는다.
    unawaited(HomeWidgetSyncService.instance.sync(force: true));

    // 등록 후 분석/캐시 갱신은 후처리이므로 실패해도 등록 성공을 막지 않습니다.
    // AI 분석을 끈 채로 등록하면 요청하지 않는다. 문제 상세에서 따로 할 수 있다.
    if (_aiAnalysisEnabled) {
      await _runPostSaveTask(
        () => problemService.requestProblemAnalysis(
          registeredProblemId,
          showErrorSnackBar: false,
        ),
        source: 'problem_register_analysis_request',
      );
    }

    // Provider를 통해 문제 조회 및 상태 업데이트
    await _runPostSaveTask(
      () => problemsProvider.fetchProblem(
        registeredProblemId,
        showErrorSnackBar: false,
      ),
      source: 'problem_register_detail_refresh',
    );
    await problemsProvider.updateProblemCount(1);
    if (!context.mounted) return;
    // requestReview may show a fallback dialog, so keep the mounted guard above.
    // ignore: use_build_context_synchronously
    await _runPostSaveTask(
      () => problemsProvider.requestReview(context),
      source: 'problem_register_review_request',
    );

    // 2. 유저 정보 갱신 (경험치 업데이트)
    await _runPostSaveTask(
      () => userProvider.fetchUserInfo(showErrorSnackBar: false),
      source: 'problem_register_user_refresh',
    );

    // 3. 폴더 갱신 (화면 전환 전에 먼저 캐시 삭제 및 타임스탬프 업데이트)
    if (_selectedFolderId != null) {
      await foldersProvider.refreshFolder(_selectedFolderId!);
    } else {
      // 루트 폴더 갱신 (타임스탬프 업데이트됨)
      final rootFolder = foldersProvider.rootFolder;
      if (rootFolder != null) {
        await foldersProvider.refreshFolder(rootFolder.folderId);
      }
    }

    debugPrint('problem register complete - problemId: $registeredProblemId');

    resetAll();
  }

  /// 오답노트 수정
  Future<void> _updateProblem() async {
    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);
    final problemId = widget.problemModel!.problemId;
    final originalFolderId = widget.problemModel!.folderId;

    // 문제 기본 정보 업데이트
    final problemRegisterModel = ProblemRegisterModel(
      problemId: problemId,
      memo: ProblemRegisterModel.clampMemo(_memoCtrl.text),
      reference: ProblemRegisterModel.clampReference(_titleCtrl.text),
      solvedAt: _selectedDate,
      folderId: _selectedFolderId,
      imageDataDtoList: [],
      tagIds: _selectedTagIds.toList(),
    );

    await problemsProvider.updateProblem(problemRegisterModel);

    // 폴더 갱신 (새 폴더와 기존 폴더 모두)
    await _refreshFolders(originalFolderId);

    // 삭제할 이미지 삭제
    await _deleteRemovedImages(problemsProvider, problemId);
    // 새로 추가된 이미지 업데이트
    await _uploadAndRegisterNewImages(problemsProvider, problemId);

    resetAll();
  }

  /// 삭제된 이미지들을 서버에서 삭제
  Future<void> _deleteRemovedImages(
      ProblemsProvider problemsProvider, int problemId) async {
    if (_deletedImageUrls.isEmpty) {
      return;
    }

    for (var imageUrl in _deletedImageUrls) {
      debugPrint('이미지 삭제: $imageUrl');
      await problemsProvider.deleteProblemImageData(imageUrl);
    }

    await problemsProvider.fetchProblem(problemId);
  }

  /// 새로 추가된 이미지들을 업로드하고 서버에 등록
  Future<void> _uploadAndRegisterNewImages(
      ProblemsProvider problemsProvider, int problemId) async {
    // 이미지가 없으면 리턴
    if (_problemImages.isEmpty && _answerImages.isEmpty) {
      return;
    }

    // 파일 리스트 생성
    final List<File> imageFiles = [];
    final List<String> imageTypes = [];

    // 문제 이미지 추가
    for (var xFile in _problemImages) {
      imageFiles.add(File(xFile.path));
      imageTypes.add('PROBLEM_IMAGE');
    }

    // 해설 이미지 추가
    for (var xFile in _answerImages) {
      imageFiles.add(File(xFile.path));
      imageTypes.add('ANSWER_IMAGE');
    }

    // 서버로 직접 전송 (multipart)
    await problemsProvider.registerProblemImageData(
      problemId: problemId,
      problemImages: imageFiles,
      problemImageTypes: imageTypes,
    );
  }

  /// 폴더 컨텐츠 갱신 (수정 시 기존 폴더와 새 폴더 모두 갱신)
  Future<void> _refreshFolders(int? originalFolderId) async {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);

    // 새 폴더 갱신 (_selectedFolderId가 null이면 루트 폴더)
    if (_selectedFolderId != null) {
      await foldersProvider.refreshFolder(_selectedFolderId!);
    } else {
      // 루트 폴더 갱신
      final rootFolder = foldersProvider.rootFolder;
      if (rootFolder != null) {
        await foldersProvider.refreshFolder(rootFolder.folderId);
      }
    }

    // 기존 폴더가 새 폴더와 다르면 기존 폴더도 갱신
    if (originalFolderId != null && originalFolderId != _selectedFolderId) {
      await foldersProvider.refreshFolder(originalFolderId);
    }
  }

  Future<void> _runPostSaveTask(
    Future<void> Function() task, {
    required String source,
  }) async {
    try {
      await task();
    } catch (e, stackTrace) {
      debugPrint('Post-save task failed ($source): $e');
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

  void showSuccessDialog(BuildContext context) {
    if (widget.isEditMode) {
      final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
      SnackBarDialog.showSnackBar(
          context: context,
          message: "오답노트가 성공적으로 저장됐어요.",
          backgroundColor: themeProvider.primaryColor);
      return;
    }

    // 문제집 몇 쪽을 이어서 올릴 때 매번 + 버튼부터 다시 눌러야 했다. 같은
    // 공책으로 작성 화면을 바로 다시 연다.
    final folderId = _selectedFolderId;
    AppToast.show(
      message: '오답노트를 저장했어요',
      type: ToastType.success,
      duration: const Duration(seconds: 4),
      actionLabel: '하나 더 쓰기',
      onAction: () {
        AppAnalytics.logEvent('problem_register_another', {});
        AppNavigator.navigatorKey.currentState?.push(
          TossPageRoute(
            builder: (_) => ProblemRegisterScreen(
              problemModel: null,
              isEditMode: false,
              initialFolderId: folderId,
            ),
          ),
        );
      },
    );
  }
}

/// 고른 순서를 지키며 올라간 주소를 끼워 넣는다.
///
/// [orderByUrl] 에 없는 주소(수정 화면에서 이미 있던 사진)는 맨 앞 순서로 본다.
@visibleForTesting
void insertInPickOrder(
  List<String> urls,
  Map<String, int> orderByUrl,
  String url,
  int order,
) {
  orderByUrl[url] = order;
  final index = urls.indexWhere((u) => (orderByUrl[u] ?? -1) > order);
  if (index < 0) {
    urls.add(url);
  } else {
    urls.insert(index, url);
  }
}
