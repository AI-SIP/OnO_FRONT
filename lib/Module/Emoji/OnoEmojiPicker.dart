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
    final emojiSize = isTablet ? 58.0 : 52.0;
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.categories.map((category) {
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Tooltip(
                    message: category.label,
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategory = category),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: isTablet ? 54 : 48,
                        height: isTablet ? 54 : 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeProvider.primaryColor
                                  .withValues(alpha: 0.12)
                              : Colors.grey[100],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? themeProvider.primaryColor
                                : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: OnoEmojiImage(
                            emojiKey: category.iconKey,
                            size: isTablet ? 34 : 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
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
}
