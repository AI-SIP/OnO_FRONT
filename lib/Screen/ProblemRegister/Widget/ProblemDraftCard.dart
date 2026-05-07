import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Model/Tag/TagModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Module/Util/FolderPickerWidget.dart';
import '../TagSelectionScreen.dart';
import 'DatePickerWidget.dart';
import 'ImageGridWidget.dart';
import 'LabeledTextField.dart';

class ProblemDraftCard extends StatelessWidget {
  final List<XFile> problemImages;
  final List<XFile> answerImages;
  final TextEditingController titleController;
  final TextEditingController memoController;
  final DateTime selectedDate;
  final int? selectedFolderId;
  final Set<int> selectedTagIds;
  final List<TagModel> availableTags;
  final bool isLoadingTags;
  final VoidCallback onAddProblemImage;
  final VoidCallback onAddAnswerImage;
  final ValueChanged<int> onRemoveProblemImage;
  final ValueChanged<int> onRemoveAnswerImage;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int?> onFolderPicked;
  final ValueChanged<TagSelectionResult> onTagsChanged;
  final ValueChanged<int> onTagRemoved;

  const ProblemDraftCard({
    super.key,
    required this.problemImages,
    required this.answerImages,
    required this.titleController,
    required this.memoController,
    required this.selectedDate,
    required this.selectedFolderId,
    required this.selectedTagIds,
    required this.availableTags,
    required this.isLoadingTags,
    required this.onAddProblemImage,
    required this.onAddAnswerImage,
    required this.onRemoveProblemImage,
    required this.onRemoveAnswerImage,
    required this.onTitleChanged,
    required this.onDateChanged,
    required this.onFolderPicked,
    required this.onTagsChanged,
    required this.onTagRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    final spacing = isWide ? 24.0 : 18.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildProblemImageSection()),
                const SizedBox(width: 18),
                Expanded(child: _buildAnswerImageSection()),
              ],
            )
          else ...[
            _buildProblemImageSection(),
            SizedBox(height: spacing),
            _buildAnswerImageSection(),
          ],
          SizedBox(height: spacing),
          LabeledTextField(
            label: '제목',
            hintText: '오답노트의 제목을 작성해주세요!',
            icon: Icons.info,
            controller: titleController,
            showClearButton: true,
            onChanged: onTitleChanged,
          ),
          SizedBox(height: spacing),
          _buildTagSection(context),
          SizedBox(height: spacing),
          LabeledTextField(
            label: '메모',
            controller: memoController,
            icon: Icons.edit,
            hintText: '기록하고 싶은 내용을 간단하게 작성해주세요!',
            maxLines: 3,
          ),
          SizedBox(height: spacing),
          DatePickerWidget(
            selectedDate: selectedDate,
            onDateChanged: onDateChanged,
          ),
          SizedBox(height: spacing),
          FolderPickerWidget(
            selectedId: selectedFolderId,
            onPicked: onFolderPicked,
          ),
        ],
      ),
    );
  }

  Widget _buildProblemImageSection() {
    return _FieldContainer(
      child: ImageGridWidget(
        label: '문제 이미지',
        files: problemImages,
        onAdd: onAddProblemImage,
        onRemove: onRemoveProblemImage,
        titleIconPadding: const EdgeInsets.all(8),
        titleIconSize: 20,
        titleIconBorderRadius: 8,
      ),
    );
  }

  Widget _buildAnswerImageSection() {
    return _FieldContainer(
      child: ImageGridWidget(
        label: '해설 이미지',
        files: answerImages,
        onAdd: onAddAnswerImage,
        onRemove: onRemoveAnswerImage,
        titleIconPadding: const EdgeInsets.all(8),
        titleIconSize: 20,
        titleIconBorderRadius: 8,
      ),
    );
  }

  Widget _buildTagSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final selectedTags = availableTags
        .where((tag) => selectedTagIds.contains(tag.tagId))
        .toList();

    return _FieldContainer(
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
                text: '${selectedTagIds.length}/5',
                fontSize: 13,
                color: Colors.grey[600]!,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed:
                    isLoadingTags ? null : () => _openTagSelection(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                child: isLoadingTags
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
                    text: '선택된 태그가 없습니다.',
                    fontSize: 13,
                    color: Colors.grey[400]!,
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedTags
                        .map(
                          (tag) => Stack(
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
                                  onTap: () => onTagRemoved(tag.tagId),
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
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTagSelection(BuildContext context) async {
    final result = await Navigator.of(context).push<TagSelectionResult>(
      MaterialPageRoute(
        builder: (_) => TagSelectionScreen(
          initialTags: List<TagModel>.from(availableTags),
          initialSelectedTagIds: Set<int>.from(selectedTagIds),
        ),
      ),
    );

    if (result != null) {
      onTagsChanged(result);
    }
  }
}

class _FieldContainer extends StatelessWidget {
  final Widget child;

  const _FieldContainer({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
}
