import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Model/Problem/ProblemRegisterModel.dart';
import '../../Model/Tag/TagModel.dart';
import '../../Module/Dialog/LoadingDialog.dart';
import '../../Module/Dialog/SnackBarDialog.dart';
import '../../Module/Image/ImagePickerHandler.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Module/Util/FolderPickerWidget.dart';
import '../../Provider/FoldersProvider.dart';
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

class ProblemRegisterTemplate extends StatefulWidget {
  final ProblemModel? problemModel;
  final bool isEditMode;
  final int? initialFolderId;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;

  const ProblemRegisterTemplate({
    Key? key,
    this.problemModel,
    required this.isEditMode,
    this.initialFolderId,
    this.onCancel,
    this.onSubmit,
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

  @override
  void initState() {
    super.initState();
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
    _loadMyTags();
    _loadRecommendedTags(imageUrls: _existingProblemImageUrls);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    final spacing = isWide ? 50.0 : 30.0; // 태블릿: 50px, 모바일: 30px

    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSections(isWide: isWide),
              SizedBox(height: spacing),
              LabeledTextField(
                label: '제목',
                hintText: '오답노트의 제목을 작성해주세요!',
                icon: Icons.info,
                controller: _titleCtrl,
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
                hintText: '기록하고 싶은 내용을 간단하게 작성해주세요!',
                maxLines: 3,
              ),
              SizedBox(height: spacing),
              DatePickerWidget(
                selectedDate: _selectedDate,
                onDateChanged: (d) => setState(() => _selectedDate = d),
              ),
              SizedBox(height: spacing),
              FolderPickerWidget(
                selectedId: _selectedFolderId,
                onPicked: _updateSelectedFolder,
              ),
            ],
          ),
        ));
  }

  Widget _buildImageSections({required bool isWide}) {
    final problemSection = _buildImageSectionContainer(
      child: ImageGridWidget(
        label: '문제 이미지',
        files: _problemImages,
        existingImageUrls: _existingProblemImageUrls,
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
    _isApplyingDefaultTitle = true;
    _titleCtrl.text =
        '${_resolveFolderName(folderId)} ${_existingProblemCountForFolder(folderId) + 1}';
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
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
    setState(() {});
  }

  void _removePendingAnswerImage(int index) {
    if (index < 0 || index >= _answerImages.length) return;
    final removed = _answerImages.removeAt(index);
    _canceledUploadLocalPaths.add(removed.path);
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
        message: '이미지 삭제에 실패했습니다.',
        backgroundColor: Colors.red,
      );
    }
  }

  void _uploadImageImmediately(XFile file, {required bool isProblemImage}) {
    setState(() {
      if (isProblemImage) {
        _problemImages.add(file);
      } else {
        _answerImages.add(file);
      }
    });

    final task = _uploadSingleImage(file, isProblemImage: isProblemImage);
    _uploadTasks[file.path] = task;
  }

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
      setState(() {
        if (isProblemImage) {
          _problemImages.removeWhere((f) => f.path == file.path);
          _existingProblemImageUrls.add(imageUrl);
        } else {
          _answerImages.removeWhere((f) => f.path == file.path);
          _existingAnswerImageUrls.add(imageUrl);
        }
      });
      if (isProblemImage) {
        await _loadRecommendedTags(imageUrls: _existingProblemImageUrls);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (isProblemImage) {
          _problemImages.removeWhere((f) => f.path == file.path);
        } else {
          _answerImages.removeWhere((f) => f.path == file.path);
        }
      });
      SnackBarDialog.showSnackBar(
        context: context,
        message: '이미지 업로드에 실패했습니다.',
        backgroundColor: Colors.red,
      );
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
      log('태그 목록 조회 실패: $e');
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
      if (!mounted) return;
      setState(() {
        _recommendedTags
          ..clear()
          ..addAll(recommended);
        _mergeIntoAvailableTags(recommended);
      });
    } catch (e) {
      log('태그 추천 조회 실패: $e');
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
      MaterialPageRoute(
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
                  color: themeProvider.primaryColor.withOpacity(0.1),
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
            child: _selectedTagIds.isEmpty
                ? StandardText(
                    text: '선택된 태그가 없습니다.',
                    fontSize: 13,
                    color: Colors.grey[400]!,
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
            child: _existingProblemImageUrls.isEmpty
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
                              text: '최근 사용 태그가 없습니다.',
                              fontSize: 13,
                              color: Colors.grey[400]!,
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
                                child: InkWell(
                                  onTap: () => _applyRecommendedTag(tag),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 11, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? themeProvider.primaryColor
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
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
      _existingProblemImageUrls.clear();
      _existingAnswerImageUrls.clear();
      _deletedImageUrls.clear();
      _selectedTagIds.clear();
      _recommendedTags.clear();
    });
  }

  Future<void> submit() async {
    // 제목 필수 입력 검증
    if (_titleCtrl.text.trim().isEmpty) {
      _showTitleRequiredDialog(context);
      return;
    }

    // 문제 이미지 필수 입력 검증 (신규 등록 시에만)
    if (!widget.isEditMode &&
        _problemImages.isEmpty &&
        _existingProblemImageUrls.isEmpty) {
      _showProblemImageRequiredDialog(context);
      return;
    }

    if (!widget.isEditMode) {
      await _waitForPendingUploads();
      if (!mounted) return;
      if (_existingProblemImageUrls.isEmpty) {
        _showProblemImageRequiredDialog(context);
        return;
      }
    }

    final canPopBeforeSubmit = Navigator.of(context).canPop();
    LoadingDialog.show(
        context, widget.isEditMode ? '오답노트 수정 중...' : '오답노트 작성 중...');
    bool shouldPop = false;
    bool loadingHidden = false;
    try {
      if (widget.isEditMode) {
        await _updateProblem();
        shouldPop = canPopBeforeSubmit;
      } else {
        await _registerProblem();
        shouldPop = canPopBeforeSubmit;
      }
    } catch (e, stackTrace) {
      log('오답노트 ${widget.isEditMode ? "수정" : "등록"} 실패: $e');
      log(stackTrace.toString());
      if (mounted) {
        LoadingDialog.hide(context);
        loadingHidden = true;
        SnackBarDialog.showSnackBar(
          context: context,
          message: widget.isEditMode
              ? '오답노트 수정에 실패했습니다. 잠시 후 다시 시도해주세요.'
              : '오답노트 등록에 실패했습니다. 잠시 후 다시 시도해주세요.',
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

    showSuccessDialog(context);

    if (shouldPop) {
      Navigator.of(context).pop(true);
      return;
    }

    Provider.of<ScreenIndexProvider>(context, listen: false)
        .setSelectedIndex(0);
  }

  void _showTitleRequiredDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                // 헤더
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const StandardText(
                      text: '경고',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 내용
                const StandardText(
                  text: '제목을 입력해 주세요!',
                  fontSize: 15,
                  color: Colors.black87,
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
                        borderRadius: BorderRadius.circular(8),
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                // 헤더
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const StandardText(
                      text: '경고',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 내용
                const StandardText(
                  text: '문제 이미지를 추가해 주세요!',
                  fontSize: 15,
                  color: Colors.black87,
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
                        borderRadius: BorderRadius.circular(8),
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
    log('register problem');

    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    final problemService = ProblemService();
    final registeredProblemId = await problemService.registerProblemV2(
      problemId: null,
      memo: _memoCtrl.text,
      reference: _titleCtrl.text,
      solvedAt: _selectedDate,
      folderId: _selectedFolderId,
      problemImageUrls: _existingProblemImageUrls,
      answerImageUrls: _existingAnswerImageUrls,
      tagIds: _selectedTagIds.toList(),
    );

    // 등록 후 분석/캐시 갱신은 후처리이므로 실패해도 등록 성공을 막지 않습니다.
    await _runPostSaveTask(
      () => problemService.requestProblemAnalysis(
        registeredProblemId,
        showErrorSnackBar: false,
      ),
      source: 'problem_register_analysis_request',
    );

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

    log('problem register complete - problemId: $registeredProblemId');

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
      memo: _memoCtrl.text,
      reference: _titleCtrl.text,
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
      log('이미지 삭제: $imageUrl');
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

  void showSuccessDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    SnackBarDialog.showSnackBar(
        context: context,
        message: "오답노트가 성공적으로 저장되었습니다.",
        backgroundColor: themeProvider.primaryColor);
  }
}
