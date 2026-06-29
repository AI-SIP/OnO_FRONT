import 'package:flutter/material.dart';

import '../../../Model/StudyRoom/FeedReactionModel.dart';
import '../../../Module/Emoji/OnoEmojiImage.dart';
import '../../../Module/Emoji/OnoEmojiPicker.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class FeedReactionBar extends StatelessWidget {
  final List<FeedReactionModel> reactions;
  final ThemeHandler themeProvider;
  final ValueChanged<String>? onToggle;

  const FeedReactionBar({
    super.key,
    required this.reactions,
    required this.themeProvider,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: reactions
                .map((r) => _ReactionChip(
                      reaction: r,
                      themeProvider: themeProvider,
                      onTap: () => onToggle?.call(r.emoji),
                    ))
                .toList(),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.add_reaction_outlined,
            size: 21,
            color: Colors.grey[500],
          ),
          tooltip: '반응 추가',
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          padding: EdgeInsets.zero,
          onPressed: onToggle == null
              ? null
              : () {
                  OnoEmojiPicker.show(
                    context,
                    onSelected: (emoji) => onToggle?.call(emoji.key),
                  );
                },
        ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final FeedReactionModel reaction;
  final ThemeHandler themeProvider;
  final VoidCallback onTap;

  const _ReactionChip({
    required this.reaction,
    required this.themeProvider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isReacted = reaction.reactedByMe;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 4, 11, 4),
        decoration: BoxDecoration(
          color: isReacted
              ? themeProvider.primaryColor.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isReacted
                ? themeProvider.primaryColor.withValues(alpha: 0.4)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OnoEmojiImage(emojiKey: reaction.emoji, size: 24),
            const SizedBox(width: 6),
            Text(
              '${reaction.count}',
              style: TextStyle(
                fontSize: 13,
                color:
                    isReacted ? themeProvider.primaryColor : Colors.grey[600],
                fontWeight: FontWeight.w700,
                fontFamily: 'PretendardBold',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
