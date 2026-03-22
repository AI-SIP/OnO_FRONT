import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Model/Tag/TagModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class TagSelectorWidget extends StatefulWidget {
  final List<TagModel> availableTags;
  final Set<int> selectedTagIds;
  final bool isLoading;
  final int maxSelectable;
  final void Function(int tagId) onToggleTag;
  final Future<void> Function(String name) onCreateTag;

  const TagSelectorWidget({
    super.key,
    required this.availableTags,
    required this.selectedTagIds,
    required this.isLoading,
    required this.onToggleTag,
    required this.onCreateTag,
    this.maxSelectable = 5,
  });

  @override
  State<TagSelectorWidget> createState() => _TagSelectorWidgetState();
}

class _TagSelectorWidgetState extends State<TagSelectorWidget> {
  final TextEditingController _tagController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _createTag() async {
    final rawName = _tagController.text.trim();
    if (rawName.isEmpty) return;

    setState(() => _isCreating = true);
    try {
      await widget.onCreateTag(rawName);
      if (!mounted) return;
      _tagController.clear();
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final standardTextStyle = const StandardText(text: '').getTextStyle();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.sell_outlined,
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
              const Spacer(),
              StandardText(
                text: '${widget.selectedTagIds.length}/${widget.maxSelectable}',
                fontSize: 13,
                color: Colors.grey[700]!,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  style: standardTextStyle.copyWith(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.primaryColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    hintText: '#태그를 입력하고 추가하세요',
                    hintStyle: standardTextStyle.copyWith(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _createTag(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed:
                      (_isCreating || widget.isLoading) ? null : _createTag,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const StandardText(
                          text: '추가',
                          color: Colors.white,
                          fontSize: 13,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (widget.availableTags.isEmpty)
            StandardText(
              text: '아직 만든 태그가 없습니다.',
              fontSize: 13,
              color: Colors.grey[600]!,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.availableTags.map((tag) {
                final isSelected = widget.selectedTagIds.contains(tag.tagId);
                return FilterChip(
                  selected: isSelected,
                  label: StandardText(
                    text: '#${tag.name}',
                    fontSize: 13,
                    color: isSelected
                        ? themeProvider.primaryColor
                        : Colors.black87,
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: themeProvider.primaryColor.withOpacity(0.14),
                  side: BorderSide(
                    color: isSelected
                        ? themeProvider.primaryColor.withOpacity(0.4)
                        : Colors.grey[300]!,
                  ),
                  onSelected: (_) => widget.onToggleTag(tag.tagId),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
