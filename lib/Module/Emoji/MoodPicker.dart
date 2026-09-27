import 'package:flutter/material.dart';

import '../Design/AppColors.dart';
import '../Design/AppRadius.dart';
import '../Motion/AppHaptic.dart';
import '../Motion/AppMotion.dart';
import '../Motion/PressableScale.dart';
import 'OnoEmoji.dart';
import 'OnoEmojiCatalog.dart';
import 'OnoEmojiImage.dart';
import 'OnoEmojiPicker.dart';

/// 복습을 마치고 기분을 고르는 가로 줄.
///
/// 복습 세트 완료 화면과 문제 하나의 복습 인증 화면이 같이 쓴다. 두 곳에
/// 같은 코드가 따로 있어서 한쪽만 고치면 다른 쪽에 같은 결함이 남았다.
///
/// 추천 칸 뒤에 `...` 칸이 있고, 누르면 전체 이모지에서 고른다. 거기서
/// 추천에 없는 것을 고르면 어느 칸도 골라진 모양이 되지 않아서 다이얼로그를
/// 닫은 뒤 무엇을 골랐는지 알 수 없었다. 그런 것은 줄 맨 앞에 칸을 하나 더
/// 세워 골라 둔 모양으로 보여 주고, 줄도 처음으로 되돌린다. `...` 칸은
/// 줄 맨 끝이라 폰에서는 화면 밖이기 때문이다.
class MoodPickerRow extends StatefulWidget {
  /// 줄에 먼저 세울 이모지. 여기 없는 것은 `...` 에서 고른다.
  static const List<String> recommendedKeys = [
    'success_checkmark',
    'got_100_score',
    'fired_up_sparkle_eyes',
    'happy_tears',
    'frustrated_studying',
    'dizzy_spiral_eyes2',
    'sleeping_blanket',
  ];

  final String? selectedKey;

  /// 고른 것이 바뀌면 불린다. 고른 칸을 다시 누르면 해제되어 null 이 온다.
  final ValueChanged<String?> onChanged;

  final Color color;

  const MoodPickerRow({
    super.key,
    required this.selectedKey,
    required this.onChanged,
    required this.color,
  });

  @override
  State<MoodPickerRow> createState() => _MoodPickerRowState();
}

class _MoodPickerRowState extends State<MoodPickerRow> {
  final ScrollController _scrollController = ScrollController();

  /// `...` 에서 고른, 추천에 없는 이모지. 해제해도 칸은 남겨 둔다. 칸이
  /// 사라지면 누른 자리 아래로 옆 칸이 밀려 들어와 헷갈린다.
  String? _extraKey;

  @override
  void initState() {
    super.initState();
    final selected = widget.selectedKey;
    if (selected != null && !MoodPickerRow.recommendedKeys.contains(selected)) {
      _extraKey = selected;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> get _keys => [
        if (_extraKey != null) _extraKey!,
        ...MoodPickerRow.recommendedKeys,
      ];

  void _openPicker() {
    OnoEmojiPicker.show(
      context,
      selectedKey: widget.selectedKey,
      onSelected: _onPicked,
    );
  }

  void _onPicked(OnoEmoji emoji) {
    if (!mounted) return;
    if (!MoodPickerRow.recommendedKeys.contains(emoji.key)) {
      setState(() => _extraKey = emoji.key);
    }
    widget.onChanged(emoji.key);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: AppMotion.normal,
        curve: AppMotion.standard,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = _keys;

    return SizedBox(
      height: 82,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: keys.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == keys.length) return _buildMoreButton();

          final emoji = OnoEmojiCatalog.byKey(keys[index]);
          if (emoji == null) return const SizedBox.shrink();
          return _buildMoodTile(emoji);
        },
      ),
    );
  }

  Widget _buildMoodTile(OnoEmoji emoji) {
    final isSelected = widget.selectedKey == emoji.key;

    return PressableScale(
      haptic: HapticLevel.selection,
      // 고른 것을 다시 누르면 해제된다. 안 고르고 넘어가는 것도 그대로
      // 되어야 해서 되돌릴 길을 열어 둔다.
      onTap: () => widget.onChanged(isSelected ? null : emoji.key),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.color.withValues(alpha: 0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: isSelected ? widget.color : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            OnoEmojiImage(emoji: emoji, size: 54),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected ? widget.color : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreButton() {
    return PressableScale(
      onTap: _openPicker,
      child: Container(
        width: 70,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(Icons.more_horiz, color: widget.color),
      ),
    );
  }
}

/// 지금 고른 기분을 제목 줄 오른쪽에 보여 주는 그림.
///
/// 칸 줄은 가로로 넘어가서 고른 칸이 화면 밖에 있을 수 있다. 어디서
/// 골랐든 제목 옆 한 곳에서 보인다. 이름은 적지 않고 그림만 둔다.
/// 스크린 리더는 이름을 읽는다. 고른 것이 없으면 자리를 차지하지 않는다.
class SelectedMoodChip extends StatelessWidget {
  final String? selectedKey;
  final Color color;

  const SelectedMoodChip({
    super.key,
    required this.selectedKey,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final key = selectedKey;
    final emoji = key == null ? null : OnoEmojiCatalog.byKey(key);

    return AnimatedSwitcher(
      duration: AppMotion.fast,
      child: emoji == null
          ? const SizedBox.shrink()
          : Semantics(
              key: ValueKey(emoji.key),
              label: '고른 기분: ${emoji.label}',
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: OnoEmojiImage(emoji: emoji, size: 30),
              ),
            ),
    );
  }
}
