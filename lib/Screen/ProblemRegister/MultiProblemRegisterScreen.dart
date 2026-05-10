import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/PracticeNote/PracticeNoteRegisterModel.dart';
import '../../Model/Tag/TagModel.dart';
import '../../Module/Dialog/SnackBarDialog.dart';
import '../../Module/Image/ImagePickerHandler.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Module/Util/FolderPickerWidget.dart';
import '../../Provider/FoldersProvider.dart';
import '../../Provider/PracticeNoteProvider.dart';
import '../../Provider/ProblemsProvider.dart';
import '../../Provider/ScreenIndexProvider.dart';
import '../../Provider/UserProvider.dart';
import '../../Service/Api/FileUpload/FileUploadService.dart';
import '../../Service/Api/Problem/ProblemService.dart';
import '../../Service/Api/Tag/TagService.dart';
import '../../Util/AppErrorReporter.dart';
import 'TagSelectionScreen.dart';
import 'Widget/DatePickerWidget.dart';
import 'Widget/ImageGridWidget.dart';
import 'Widget/LabeledTextField.dart';

enum _BatchRegisterStep {
  selectImages,
  editDetails,
}

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
  final ImagePickerHandler _imagePickerHandler = ImagePickerHandler();
  final TagService _tagService = TagService();
  final FileUploadService _fileUploadService = FileUploadService();
  final ProblemService _problemService = ProblemService();
  final ScrollController _commonPanelScrollController = ScrollController();

  final List<XFile> _problemImages = [];
  final List<_BatchProblemDraft> _drafts = [];
  final List<TagModel> _availableTags = [];
  final Set<int> _selectedTagIds = {};

  _BatchRegisterStep _step = _BatchRegisterStep.selectImages;
  DateTime _selectedDate = DateTime.now();
  int? _selectedFolderId;
  bool _isLoadingTags = false;
  bool _isSubmitting = false;
  bool _didOpenInitialGallery = false;
  bool _createPracticeSet = true;

  @override
  void initState() {
    super.initState();
    _selectedFolderId = widget.initialFolderId;
    _loadTags();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didOpenInitialGallery) return;
      _didOpenInitialGallery = true;
      _pickProblemImages();
    });
  }

  @override
  void dispose() {
    _commonPanelScrollController.dispose();
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
      appBar: _buildAppBar(themeProvider),
      body: _step == _BatchRegisterStep.selectImages
          ? _buildImageSelectionBody(themeProvider)
          : _buildDraftReviewBody(themeProvider),
      bottomNavigationBar: _step == _BatchRegisterStep.selectImages
          ? _buildCommonPanel(themeProvider)
          : _buildReviewBottomBar(themeProvider),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeHandler themeProvider) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: Icon(
          _step == _BatchRegisterStep.selectImages
              ? Icons.close
              : Icons.arrow_back,
          color: Colors.black87,
        ),
        onPressed: _isSubmitting
            ? null
            : () {
                if (_step == _BatchRegisterStep.editDetails) {
                  _returnToImageSelection();
                  return;
                }
                Navigator.pop(context);
              },
      ),
      title: StandardText(
        text: _step == _BatchRegisterStep.selectImages
            ? '오답노트 여러장 작성'
            : '오답노트 내용 확인',
        fontSize: 17,
        color: themeProvider.primaryColor,
        fontWeight: FontWeight.w600,
      ),
      centerTitle: true,
    );
  }

  Widget _buildImageSelectionBody(ThemeHandler themeProvider) {
    if (_problemImages.isEmpty) {
      return _buildEmptyImageState(themeProvider);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.collections,
                    size: 20,
                    color: themeProvider.primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StandardText(
                    text: '선택한 이미지 ${_problemImages.length}장',
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _pickProblemImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  icon: const Icon(Icons.add_photo_alternate, size: 17),
                  label: const StandardText(
                    text: '더 추가',
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeProvider.primaryColor.withValues(alpha: 0.36),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Material(
                  color: Colors.white,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: _problemImages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _problemImages.length) {
                        return _buildAddImageTile(themeProvider);
                      }
                      return _buildImageTile(themeProvider, index);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyImageState(ThemeHandler themeProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight = constraints.maxHeight < 260;
        final iconSize = isTight ? 56.0 : 76.0;
        final iconRadius = isTight ? 18.0 : 24.0;
        final iconGlyphSize = isTight ? 28.0 : 34.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(iconRadius),
                    ),
                    child: Icon(
                      Icons.collections_outlined,
                      color: themeProvider.primaryColor,
                      size: iconGlyphSize,
                    ),
                  ),
                  SizedBox(height: isTight ? 10 : 18),
                  StandardText(
                    text: '등록할 문제 이미지를 한 번에 선택해 주세요.',
                    fontSize: isTight ? 15 : 17,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isTight ? 4 : 8),
                  StandardText(
                    text: '이미지 1장당 오답노트 1개 초안이 생성됩니다.',
                    fontSize: isTight ? 12 : 14,
                    color: Colors.grey[600]!,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isTight ? 12 : 24),
                  SizedBox(
                    width: double.infinity,
                    height: isTight ? 42 : 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _pickProblemImages,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.photo_library_outlined, size: 20),
                      label: const StandardText(
                        text: '갤러리에서 선택',
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageTile(ThemeHandler themeProvider, int index) {
    final image = _problemImages[index];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(image.path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                color: Colors.grey[100],
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.grey[500],
                ),
              );
            },
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(999),
              ),
              child: StandardText(
                text: '${index + 1}',
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 6,
            child: InkWell(
              onTap: _isSubmitting ? null : () => _removeProblemImage(index),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageTile(ThemeHandler themeProvider) {
    return InkWell(
      onTap: _isSubmitting ? null : _pickProblemImages,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeProvider.primaryColor.withValues(alpha: 0.24),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: themeProvider.primaryColor,
              size: 28,
            ),
            const SizedBox(height: 8),
            StandardText(
              text: '더 추가',
              fontSize: 13,
              color: themeProvider.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftReviewBody(ThemeHandler themeProvider) {
    if (_drafts.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
      itemCount: _drafts.length + 1,
      separatorBuilder: (_, index) {
        return const SizedBox(height: 14);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: themeProvider.primaryColor.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color:
                            themeProvider.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.checklist_outlined,
                        color: themeProvider.primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const StandardText(
                      text: '내용 확인',
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildReviewSummaryChip(
                            themeProvider,
                            Icons.image_outlined,
                            '${_drafts.length}개',
                          ),
                          const SizedBox(width: 6),
                          _buildReviewSummaryChip(
                            themeProvider,
                            Icons.folder_outlined,
                            _resolveFolderName(_selectedFolderId),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildPracticeSetOption(themeProvider),
            ],
          );
        }

        final draftIndex = index - 1;
        return _buildDraftReviewItem(
          themeProvider,
          _drafts[draftIndex],
          draftIndex,
        );
      },
    );
  }

  Widget _buildReviewSummaryChip(
    ThemeHandler themeProvider,
    IconData icon,
    String text,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 118),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: themeProvider.primaryColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: StandardText(
              text: text,
              fontSize: 11,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftDetail(
    ThemeHandler themeProvider,
    _BatchProblemDraft draft,
    int index,
    VoidCallback refresh,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDraftHeader(themeProvider, index),
          const SizedBox(height: 14),
          _buildProblemImagePreview(themeProvider, draft),
          const SizedBox(height: 14),
          _buildAnswerImageSection(draft, refresh),
          const SizedBox(height: 14),
          LabeledTextField(
            label: '제목',
            hintText: '제목을 입력해 주세요',
            icon: Icons.title,
            controller: draft.titleController,
            showClearButton: true,
          ),
          const SizedBox(height: 14),
          _buildTagSection(
            themeProvider,
            selectedTagIds: draft.tagIds,
            onOpen: () => _openTagSelection(draft: draft, onChanged: refresh),
            onRemove: (tagId) {
              draft.tagIds.remove(tagId);
              refresh();
            },
            emptyText: '선택된 태그가 없습니다.',
          ),
          const SizedBox(height: 14),
          LabeledTextField(
            label: '메모',
            hintText: '메모를 입력해 주세요',
            icon: Icons.note_alt_outlined,
            controller: draft.memoController,
            maxLines: 4,
            showClearButton: true,
          ),
          const SizedBox(height: 14),
          DatePickerWidget(
            selectedDate: draft.solvedAt,
            onDateChanged: (date) {
              draft.solvedAt = date;
              refresh();
            },
          ),
          const SizedBox(height: 14),
          FolderPickerWidget(
            selectedId: draft.folderId,
            onPicked: (folderId) {
              draft.folderId = folderId;
              refresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDraftReviewItem(
    ThemeHandler themeProvider,
    _BatchProblemDraft draft,
    int index,
  ) {
    final selectedTagCount = draft.tagIds.length;
    final answerImageCount = draft.answerImages.length;
    final folderName = _resolveFolderName(draft.folderId);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(
                      File(draft.problemImage.path),
                      width: 78,
                      height: 78,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: StandardText(
                        text: '${index + 1}',
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StandardText(
                      text: _resolveDraftTitle(draft),
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildReviewMetaChip(
                          themeProvider,
                          Icons.folder_outlined,
                          folderName,
                        ),
                        _buildReviewMetaChip(
                          themeProvider,
                          Icons.local_offer_outlined,
                          '태그 $selectedTagCount',
                        ),
                        _buildReviewMetaChip(
                          themeProvider,
                          Icons.image_outlined,
                          '해설 $answerImageCount',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              children: [
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isSubmitting ? null : () => _openDraftEditor(index),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: themeProvider.primaryColor,
                      side: BorderSide(
                        color:
                            themeProvider.primaryColor.withValues(alpha: 0.34),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.edit_note_outlined, size: 17),
                    label: StandardText(
                      text: '수정',
                      fontSize: 13,
                      color: themeProvider.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 38,
                  height: 36,
                  child: IconButton(
                    onPressed: _isSubmitting ? null : () => _removeDraft(index),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 19),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewMetaChip(
    ThemeHandler themeProvider,
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: themeProvider.primaryColor.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(
              icon,
              size: 12,
              color: themeProvider.primaryColor,
            ),
          ),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 132),
            child: StandardText(
              text: text,
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftHeader(ThemeHandler themeProvider, int index) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.edit_note_outlined,
              color: themeProvider.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StandardText(
                  text: '문제 ${index + 1} 상세 정보',
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 3),
                StandardText(
                  text: '등록 전 내용을 확인해 주세요',
                  fontSize: 13,
                  color: Colors.grey[600]!,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: StandardText(
              text: '${index + 1}/${_drafts.length}',
              fontSize: 12,
              color: themeProvider.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemImagePreview(
    ThemeHandler themeProvider,
    _BatchProblemDraft draft,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.image,
                  color: themeProvider.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const StandardText(
                text: '문제 이미지',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: StandardText(
                  text: '1',
                  fontSize: 12,
                  color: themeProvider.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1.2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.file(
              File(draft.problemImage.path),
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerImageSection(
    _BatchProblemDraft draft,
    VoidCallback refresh,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: ImageGridWidget(
        label: '해설 이미지',
        files: draft.answerImages,
        onAdd: () => _pickAnswerImages(draft, onChanged: refresh),
        onRemove: (imageIndex) {
          draft.answerImages.removeAt(imageIndex);
          refresh();
        },
      ),
    );
  }

  Widget _buildCommonPanel(ThemeHandler themeProvider) {
    final canContinue = _problemImages.isNotEmpty && !_isSubmitting;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.46,
          child: Scrollbar(
            controller: _commonPanelScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _commonPanelScrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FolderPickerWidget(
                    selectedId: _selectedFolderId,
                    onPicked: _updateSelectedFolder,
                  ),
                  const SizedBox(height: 16),
                  _buildTagSection(
                    themeProvider,
                    selectedTagIds: _selectedTagIds,
                    onOpen: () => _openTagSelection(),
                    onRemove: (tagId) => setState(() {
                      _selectedTagIds.remove(tagId);
                    }),
                    emptyText: '선택된 태그가 없습니다.',
                  ),
                  const SizedBox(height: 16),
                  DatePickerWidget(
                    selectedDate: _selectedDate,
                    onDateChanged: (date) => setState(() {
                      _selectedDate = date;
                    }),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: canContinue ? _prepareDrafts : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.primaryColor,
                        disabledBackgroundColor: Colors.grey[300],
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.grey[600],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: StandardText(
                        text: _problemImages.isEmpty
                            ? '이미지를 선택해 주세요'
                            : '상세 정보 입력하기',
                        fontSize: 16,
                        color: _problemImages.isEmpty
                            ? Colors.grey[600]!
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeSetOption(ThemeHandler themeProvider) {
    return InkWell(
      onTap: _isSubmitting
          ? null
          : () => setState(() {
                _createPracticeSet = !_createPracticeSet;
              }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeProvider.primaryColor.withValues(alpha: 0.16),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.fact_check_outlined,
                color: themeProvider.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: StandardText(
                text: '이 오답노트들로 복습 세트 생성',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Checkbox(
              value: _createPracticeSet,
              activeColor: themeProvider.primaryColor,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: _isSubmitting
                  ? null
                  : (value) => setState(() {
                        _createPracticeSet = value ?? false;
                      }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewBottomBar(ThemeHandler themeProvider) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed:
                      _isSubmitting || _drafts.isEmpty ? null : _submitAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.primaryColor,
                    disabledBackgroundColor: Colors.grey[300],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: StandardText(
                    text: '${_drafts.length}개 등록하기',
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSection(
    ThemeHandler themeProvider, {
    required Set<int> selectedTagIds,
    required VoidCallback onOpen,
    required ValueChanged<int> onRemove,
    required String emptyText,
  }) {
    final selectedTags = _availableTags
        .where((tag) => selectedTagIds.contains(tag.tagId))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_offer,
                  color: themeProvider.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const StandardText(
                text: '태그',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              const SizedBox(width: 8),
              StandardText(
                text: '${selectedTagIds.length}/5',
                fontSize: 13,
                color: Colors.grey[600]!,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoadingTags || _isSubmitting ? null : onOpen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: selectedTags.isEmpty
                ? StandardText(
                    text: emptyText,
                    fontSize: 13,
                    color: Colors.grey[400]!,
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedTags.map((tag) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
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
                            child: GestureDetector(
                              onTap: _isSubmitting
                                  ? null
                                  : () => onRemove(tag.tagId),
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
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProblemImages() async {
    final pickedImages =
        await _imagePickerHandler.pickMultipleImagesFromGallery(context);
    if (!mounted || pickedImages.isEmpty) return;

    setState(() {
      _problemImages.addAll(pickedImages);
    });
  }

  Future<void> _pickAnswerImages(
    _BatchProblemDraft draft, {
    VoidCallback? onChanged,
  }) async {
    final pickedImages =
        await _imagePickerHandler.pickMultipleImagesFromGallery(context);
    if (!mounted || pickedImages.isEmpty) return;

    draft.answerImages.addAll(pickedImages);
    onChanged?.call();
    setState(() {});
  }

  void _removeProblemImage(int index) {
    setState(() {
      _problemImages.removeAt(index);
    });
  }

  void _updateSelectedFolder(int? folderId) {
    setState(() {
      _selectedFolderId = folderId;
    });
  }

  Future<void> _openTagSelection({
    _BatchProblemDraft? draft,
    VoidCallback? onChanged,
  }) async {
    final result = await Navigator.push<TagSelectionResult>(
      context,
      MaterialPageRoute(
        builder: (_) => TagSelectionScreen(
          initialTags: _availableTags,
          initialSelectedTagIds: draft == null ? _selectedTagIds : draft.tagIds,
        ),
      ),
    );

    if (result == null || !mounted) return;
    _availableTags
      ..clear()
      ..addAll(result.availableTags);

    if (draft == null) {
      _selectedTagIds
        ..clear()
        ..addAll(result.selectedTagIds);
    } else {
      draft.tagIds
        ..clear()
        ..addAll(result.selectedTagIds);
    }

    onChanged?.call();
    setState(() {});
  }

  void _prepareDrafts() {
    if (_problemImages.isEmpty) return;

    for (final draft in _drafts) {
      draft.dispose();
    }
    _drafts.clear();

    final titlePrefix = _resolvedTitlePrefix();
    final titleStartNumber = _existingProblemCountForFolder(_selectedFolderId);
    for (var index = 0; index < _problemImages.length; index++) {
      _drafts.add(
        _BatchProblemDraft(
          problemImage: _problemImages[index],
          title: '$titlePrefix - ${titleStartNumber + index + 1}',
          memo: '',
          folderId: _selectedFolderId,
          solvedAt: _selectedDate,
          tagIds: Set<int>.from(_selectedTagIds),
        ),
      );
    }

    setState(() {
      _step = _BatchRegisterStep.editDetails;
    });
  }

  void _returnToImageSelection() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    _drafts.clear();
    setState(() {
      _step = _BatchRegisterStep.selectImages;
    });
  }

  Future<void> _openDraftEditor(int index) async {
    final draft = _drafts[index];
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return StatefulBuilder(
            builder: (editorContext, editorSetState) {
              void refresh() {
                if (mounted) {
                  setState(() {});
                }
                editorSetState(() {});
              }

              return Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(
                  elevation: 0,
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(editorContext),
                  ),
                  title: StandardText(
                    text: '문제 ${index + 1} 내용 확인',
                    fontSize: 17,
                    color: themeProvider.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  centerTitle: true,
                ),
                body: _buildDraftDetail(
                  themeProvider,
                  draft,
                  index,
                  refresh,
                ),
                bottomNavigationBar: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(editorContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const StandardText(
                          text: '확인 완료',
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _removeDraft(int index) {
    final removedDraft = _drafts.removeAt(index);
    removedDraft.dispose();
    if (index < _problemImages.length) {
      _problemImages.removeAt(index);
    }

    setState(() {
      if (_drafts.isEmpty) {
        _step = _BatchRegisterStep.selectImages;
      }
    });
  }

  Future<void> _submitAll() async {
    if (_drafts.isEmpty) {
      SnackBarDialog.showSnackBar(
        context: context,
        message: '등록할 오답노트가 없습니다.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final draftsToRegister = List<_BatchProblemDraft>.from(_drafts);
    final progress = ValueNotifier<int>(0);
    final registeredProblemIds = <int>[];
    var successCount = 0;

    setState(() => _isSubmitting = true);
    _showProgressDialog(progress, draftsToRegister.length);

    try {
      for (var index = 0; index < draftsToRegister.length; index++) {
        final registeredProblemId =
            await _registerProblemDraft(draftsToRegister[index]);
        registeredProblemIds.add(registeredProblemId);
        successCount++;
        progress.value = successCount;
      }
    } catch (e, stackTrace) {
      log('배치 오답노트 등록 실패: $e');
      log(stackTrace.toString());
      unawaited(
        AppErrorReporter.report(
          e,
          stackTrace,
          source: 'batch_problem_register',
          severity: AppErrorSeverity.error,
        ),
      );
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _removeSuccessfulDrafts(successCount);
        SnackBarDialog.showSnackBar(
          context: context,
          message: successCount > 0
              ? '$successCount개 등록 완료, 남은 오답노트만 다시 시도해 주세요.'
              : '오답노트 등록에 실패했습니다. 잠시 후 다시 시도해주세요.',
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

    if (!mounted) {
      progress.dispose();
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();
    progress.dispose();
    if (_createPracticeSet) {
      await _createPracticeSetFromProblems(registeredProblemIds);
      if (!mounted) return;
    }
    Provider.of<ScreenIndexProvider>(context, listen: false)
        .setSelectedIndex(0);
    SnackBarDialog.showSnackBar(
      context: context,
      message: '${draftsToRegister.length}개의 문제가 등록되었습니다.',
      backgroundColor:
          Provider.of<ThemeHandler>(context, listen: false).primaryColor,
    );
    Navigator.of(context).pop(true);
  }

  Future<int> _registerProblemDraft(_BatchProblemDraft draft) async {
    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);

    final uploadedImageUrls = <String>[];
    late final int registeredProblemId;
    var isRegistered = false;

    try {
      final problemImageUrl =
          await _fileUploadService.uploadImageFile(draft.problemImage);
      uploadedImageUrls.add(problemImageUrl);

      final answerImageUrls = await _fileUploadService.uploadMultipleImageFiles(
        draft.answerImages,
      );
      uploadedImageUrls.addAll(answerImageUrls);

      registeredProblemId = await _problemService.registerProblemV2(
        problemId: null,
        memo: draft.memoController.text.trim(),
        reference: _resolveDraftTitle(draft),
        folderId: draft.folderId,
        solvedAt: draft.solvedAt,
        problemImageUrls: [problemImageUrl],
        answerImageUrls: answerImageUrls,
        tagIds: draft.tagIds.toList(),
      );
      isRegistered = true;
    } catch (_) {
      if (!isRegistered) {
        await _deleteUploadedImages(uploadedImageUrls);
      }
      rethrow;
    }

    await _runPostSaveTask(
      () => _problemService.requestProblemAnalysis(
        registeredProblemId,
        showErrorSnackBar: false,
      ),
      source: 'batch_problem_register_analysis_request',
    );
    await _runPostSaveTask(
      () => problemsProvider.fetchProblem(
        registeredProblemId,
        showErrorSnackBar: false,
      ),
      source: 'batch_problem_register_detail_refresh',
    );
    await problemsProvider.updateProblemCount(1);
    await _runPostSaveTask(
      () => userProvider.fetchUserInfo(showErrorSnackBar: false),
      source: 'batch_problem_register_user_refresh',
    );

    final refreshFolderId =
        draft.folderId ?? foldersProvider.rootFolder?.folderId;
    if (refreshFolderId != null) {
      await _runPostSaveTask(
        () => foldersProvider.refreshFolder(refreshFolderId),
        source: 'batch_problem_register_folder_refresh',
      );
    }

    return registeredProblemId;
  }

  Future<void> _createPracticeSetFromProblems(List<int> problemIds) async {
    if (problemIds.isEmpty) return;

    final practiceProvider =
        Provider.of<ProblemPracticeProvider>(context, listen: false);
    final practiceTitle = _resolveFolderName(_selectedFolderId);
    final registerModel = PracticeNoteRegisterModel(
      practiceId: null,
      practiceTitle: practiceTitle,
      registerProblemIdList: problemIds,
    );

    await _runPostSaveTask(
      () => practiceProvider.registerPractice(registerModel),
      source: 'batch_problem_register_practice_create',
    );
  }

  void _showProgressDialog(ValueNotifier<int> progress, int total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final themeProvider = Provider.of<ThemeHandler>(dialogContext);
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            child: ValueListenableBuilder<int>(
              valueListenable: progress,
              builder: (context, value, _) {
                final progressValue = total == 0 ? 0.0 : value / total;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 58,
                      height: 58,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 58,
                            height: 58,
                            child: CircularProgressIndicator(
                              value: progressValue,
                              strokeWidth: 5,
                              backgroundColor: themeProvider.primaryColor
                                  .withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                themeProvider.primaryColor,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.cloud_upload_outlined,
                            color: themeProvider.primaryColor,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const StandardText(
                      text: '이미지를 등록하고 있어요',
                      fontSize: 17,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 8),
                    StandardText(
                      text: '$value / $total',
                      fontSize: 14,
                      color: Colors.grey[600]!,
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 7,
                        backgroundColor:
                            themeProvider.primaryColor.withValues(alpha: 0.12),
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

  void _removeSuccessfulDrafts(int count) {
    if (count <= 0) return;

    final removeCount = count.clamp(0, _drafts.length);
    final removedDrafts = _drafts.take(removeCount).toList();
    _drafts.removeRange(0, removeCount);
    for (final draft in removedDrafts) {
      draft.dispose();
    }
    _problemImages.removeRange(0, count.clamp(0, _problemImages.length));

    if (_drafts.isEmpty) {
      setState(() {
        _step = _BatchRegisterStep.selectImages;
      });
      return;
    }

    setState(() {});
  }

  Future<void> _deleteUploadedImages(List<String> imageUrls) async {
    for (final imageUrl in imageUrls) {
      try {
        await _fileUploadService.deleteImage(imageUrl);
      } catch (e, stackTrace) {
        log('업로드 이미지 롤백 실패: $e');
        await AppErrorReporter.report(
          e,
          stackTrace,
          source: 'batch_problem_register_image_rollback',
          severity: AppErrorSeverity.warning,
        );
      }
    }
  }

  Future<void> _runPostSaveTask(
    Future<void> Function() task, {
    required String source,
  }) async {
    try {
      await task();
    } catch (e, stackTrace) {
      log('Post-save task failed ($source): $e');
      await AppErrorReporter.report(
        e,
        stackTrace,
        source: source,
        severity: AppErrorSeverity.warning,
      );
    }
  }

  String _resolvedTitlePrefix() {
    return _resolveFolderName(_selectedFolderId);
  }

  String _resolveDraftTitle(_BatchProblemDraft draft) {
    final typedTitle = draft.titleController.text.trim();
    if (typedTitle.isNotEmpty) return typedTitle;
    return _resolvedTitlePrefix();
  }

  String _resolveFolderName(int? folderId) {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    if (folderId == null) return '책장';

    final currentFolder = foldersProvider.currentFolder;
    if (currentFolder != null && currentFolder.folderId == folderId) {
      return currentFolder.folderName;
    }

    for (final folder in foldersProvider.folders) {
      if (folder.folderId == folderId) {
        return folder.folderName;
      }
    }

    return '책장';
  }

  int _existingProblemCountForFolder(int? folderId) {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    final targetFolderId = folderId ?? foldersProvider.rootFolder?.folderId;
    if (targetFolderId == null) return 0;

    final currentFolder = foldersProvider.currentFolder;
    if (currentFolder != null && currentFolder.folderId == targetFolderId) {
      return currentFolder.problemIdList.length;
    }

    for (final folder in foldersProvider.folders) {
      if (folder.folderId == targetFolderId) {
        return folder.problemIdList.length;
      }
    }

    return foldersProvider.getProblemsForFolder(targetFolderId).length;
  }
}

class _BatchProblemDraft {
  final XFile problemImage;
  final List<XFile> answerImages = [];
  final TextEditingController titleController;
  final TextEditingController memoController;
  final Set<int> tagIds;
  int? folderId;
  DateTime solvedAt;

  _BatchProblemDraft({
    required this.problemImage,
    required String title,
    required String memo,
    required this.folderId,
    required this.solvedAt,
    required this.tagIds,
  })  : titleController = TextEditingController(text: title),
        memoController = TextEditingController(text: memo);

  void dispose() {
    titleController.dispose();
    memoController.dispose();
  }
}
