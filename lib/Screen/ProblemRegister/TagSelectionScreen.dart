import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Tag/TagModel.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Service/Api/Tag/TagService.dart';

class TagSelectionResult {
  final List<int> selectedTagIds;
  final List<TagModel> availableTags;

  const TagSelectionResult({
    required this.selectedTagIds,
    required this.availableTags,
  });
}

class TagSelectionScreen extends StatefulWidget {
  final List<TagModel> initialTags;
  final Set<int> initialSelectedTagIds;

  const TagSelectionScreen({
    super.key,
    required this.initialTags,
    required this.initialSelectedTagIds,
  });

  @override
  State<TagSelectionScreen> createState() => _TagSelectionScreenState();
}

class _TagSelectionScreenState extends State<TagSelectionScreen> {
  final TagService _tagService = TagService();
  final TextEditingController _tagNameCtrl = TextEditingController();

  final List<TagModel> _tags = [];
  final Set<int> _selectedTagIds = {};

  bool _isLoading = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _selectedTagIds.addAll(widget.initialSelectedTagIds);
    _tags.addAll(widget.initialTags);
    _loadTags();
  }

  @override
  void dispose() {
    _tagNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    try {
      final fetched = await _tagService.getMyTags();
      fetched.sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;
      setState(() {
        _tags
          ..clear()
          ..addAll(fetched);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createTag() async {
    final name = _tagNameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);
    try {
      final created = await _tagService.createTag(name);
      final index = _tags.indexWhere((t) => t.tagId == created.tagId);
      if (index == -1) {
        _tags.add(created);
      } else {
        _tags[index] = created;
      }
      _tags.sort((a, b) => a.name.compareTo(b.name));
      _selectedTagIds.add(created.tagId);

      _tagNameCtrl.clear();
      if (mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _toggleTag(int tagId, bool isSelected) {
    if (isSelected) {
      _selectedTagIds.add(tagId);
    } else {
      _selectedTagIds.remove(tagId);
    }
    setState(() {});
  }

  void _confirm() {
    if (_selectedTagIds.length > 5) {
      _showLimitExceededDialog(context);
      return;
    }

    Navigator.of(context).pop(
      TagSelectionResult(
        selectedTagIds: _selectedTagIds.toList(),
        availableTags: List<TagModel>.from(_tags),
      ),
    );
  }

  void _showLimitExceededDialog(BuildContext context) {
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
                const StandardText(
                  text: '태그는 최대 5개까지만 선택할 수 있어요.',
                  fontSize: 15,
                  color: Colors.black87,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final baseTextStyle = const StandardText(text: '').getTextStyle();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: StandardText(
          text: '태그 선택',
          color: themeProvider.primaryColor,
          fontSize: 18,
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: TextField(
                        controller: _tagNameCtrl,
                        style: baseTextStyle.copyWith(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          constraints: const BoxConstraints(
                            minHeight: 50,
                            maxHeight: 50,
                          ),
                          hintText: '새 태그 이름을 입력하세요',
                          hintStyle: baseTextStyle.copyWith(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: StandardText(
                                  text: '#',
                                  fontSize: 13,
                                  color: Colors.grey[600]!,
                                ),
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 24,
                          ),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 72,
                            minHeight: 36,
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SizedBox(
                              height: 34,
                              child: ElevatedButton(
                                onPressed: _isCreating ? null : _createTag,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeProvider.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isCreating
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const StandardText(
                                        text: '생성',
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                              ),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color:
                                  themeProvider.primaryColor.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                          isDense: false,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                        ),
                        onSubmitted: (_) => _createTag(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _tags.isEmpty
                      ? const Center(
                          child: StandardText(text: '생성된 태그가 없습니다.'),
                        )
                      : ListView.separated(
                          itemCount: _tags.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 2),
                          itemBuilder: (context, index) {
                            final tag = _tags[index];
                            final isSelected =
                                _selectedTagIds.contains(tag.tagId);

                            return InkWell(
                              onTap: () => _toggleTag(tag.tagId, !isSelected),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? themeProvider.primaryColor
                                          .withOpacity(0.08)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? themeProvider.primaryColor
                                        : Colors.grey[300]!,
                                    width: isSelected ? 1.4 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? themeProvider.primaryColor
                                                .withOpacity(0.12)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(
                                        child: StandardText(
                                          text: '#',
                                          fontSize: 13,
                                          color: isSelected
                                              ? themeProvider.primaryColor
                                              : Colors.grey[600]!,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: StandardText(
                                        text: tag.name,
                                        fontSize: 14,
                                        color: isSelected
                                            ? themeProvider.primaryColor
                                            : Colors.black87,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: isSelected
                                          ? themeProvider.primaryColor
                                          : Colors.grey[400],
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _confirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const StandardText(
                          text: '확인',
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 44,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: themeProvider.primaryColor.withOpacity(0.45),
                        width: 1,
                      ),
                    ),
                    child: StandardText(
                      text: '${_selectedTagIds.length}/5',
                      fontSize: 13,
                      color: themeProvider.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
