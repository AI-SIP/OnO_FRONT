import 'package:flutter/material.dart';

import '../../../Model/StudyRoom/FeedReactionModel.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class FeedReactionBar extends StatelessWidget {
  final List<FeedReactionModel> reactions;
  final ThemeHandler themeProvider;
  final ValueChanged<String>? onToggle;

  static const _pickableEmojis = ['🔥', '👍', '🎉', '💪'];

  const FeedReactionBar({
    super.key,
    required this.reactions,
    required this.themeProvider,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: reactions
                .map((r) => _ReactionChip(
                      reaction: r,
                      themeProvider: themeProvider,
                      onTap: () => onToggle?.call(r.emoji),
                    ))
                .toList(),
          ),
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.add_reaction_outlined,
            size: 16,
            color: Colors.grey[500],
          ),
          tooltip: '반응 추가',
          onSelected: onToggle,
          itemBuilder: (_) => _pickableEmojis
              .map(
                (e) => PopupMenuItem<String>(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 20)),
                ),
              )
              .toList(),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isReacted
              ? themeProvider.primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isReacted
                ? themeProvider.primaryColor.withOpacity(0.4)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(reaction.emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              '${reaction.count}',
              style: TextStyle(
                fontSize: 12,
                color:
                    isReacted ? themeProvider.primaryColor : Colors.grey[600],
                fontFamily: 'PretendardLight',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
