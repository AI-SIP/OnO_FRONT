import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Theme/ThemeHandler.dart';
import 'OnoEmoji.dart';
import 'OnoEmojiCatalog.dart';
import 'OnoEmojiCategory.dart';
import 'OnoEmojiImage.dart';

class OnoEmojiPicker extends StatefulWidget {
  final List<OnoEmojiCategory> categories;
  final String? selectedKey;
  final ValueChanged<OnoEmoji> onSelected;

  const OnoEmojiPicker({
    super.key,
    required this.categories,
    this.selectedKey,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    List<OnoEmojiCategory>? categories,
    String? selectedKey,
    required ValueChanged<OnoEmoji> onSelected,
  }) {
    final availableCategories = categories ?? OnoEmojiCategory.values;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.62,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: OnoEmojiPicker(
              categories: availableCategories,
              selectedKey: selectedKey,
              onSelected: (emoji) {
                Navigator.pop(context);
                onSelected(emoji);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  State<OnoEmojiPicker> createState() => _OnoEmojiPickerState();
}

class _OnoEmojiPickerState extends State<OnoEmojiPicker> {
  late OnoEmojiCategory _selectedCategory;

  static const Map<OnoEmojiCategory, String> _categoryDescriptions = {
    OnoEmojiCategory.emotion: '지금 기분을 골라요',
    OnoEmojiCategory.study: '공부할 때 쓰기 좋아요',
    OnoEmojiCategory.cheer: '응원이 필요할 때',
    OnoEmojiCategory.social: '친구와 말할 때',
    OnoEmojiCategory.leisure: '쉬는 시간 느낌이에요',
  };

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categories.first;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final emojis = OnoEmojiCatalog.byCategory(_selectedCategory);
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final crossAxisCount = isTablet ? 6 : 4;
    final emojiSize = isTablet ? 66.0 : 60.0;
    final selectedEmojiKey =
        OnoEmojiCatalog.byKey(widget.selectedKey ?? '')?.key;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: widget.categories
                    .map((category) =>
                        _buildCategoryChip(category, themeProvider, isTablet))
                    .toList(),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: _EmojiCategoryHeader(
                title: _selectedCategory.label,
                description:
                    _categoryDescriptions[_selectedCategory] ?? '이모지를 골라요',
                color: themeProvider.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: emojis.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final emoji = emojis[index];
                  final isSelected = selectedEmojiKey == emoji.key;

                  return InkWell(
                    onTap: () => widget.onSelected(emoji),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? themeProvider.primaryColor.withValues(alpha: 0.1)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? themeProvider.primaryColor
                              : Colors.grey[200]!,
                        ),
                      ),
                      child: Tooltip(
                        message: emoji.label,
                        child: Center(
                          child: OnoEmojiImage(emoji: emoji, size: emojiSize),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    OnoEmojiCategory category,
    ThemeHandler themeProvider,
    bool isTablet,
  ) {
    final isSelected = category == _selectedCategory;
    return Tooltip(
      message: category.label,
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = category),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: BoxConstraints(
            minWidth: isTablet ? 104 : 88,
            minHeight: isTablet ? 42 : 38,
          ),
          padding: EdgeInsets.fromLTRB(
            isTablet ? 10 : 8,
            5,
            isTablet ? 12 : 10,
            5,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? themeProvider.primaryColor.withValues(alpha: 0.12)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  isSelected ? themeProvider.primaryColor : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OnoEmojiImage(
                emojiKey: category.iconKey,
                size: isTablet ? 32 : 28,
              ),
              const SizedBox(width: 6),
              Text(
                category.label,
                style: TextStyle(
                  color:
                      isSelected ? themeProvider.primaryColor : Colors.black54,
                  fontSize: isTablet ? 13 : 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: isSelected ? 'PretendardBold' : 'Pretendard',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmojiCategoryHeader extends StatelessWidget {
  final String title;
  final String description;
  final Color color;

  const _EmojiCategoryHeader({
    super.key,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'PretendardBold',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'PretendardLight',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
