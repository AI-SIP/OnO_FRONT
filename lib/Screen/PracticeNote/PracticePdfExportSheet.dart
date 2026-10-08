import 'package:flutter/material.dart';

import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Text/mobile_font_size.dart';
import '../../Service/Pdf/PracticeWorksheetPdf.dart';

/// 복습 세트를 학습지 PDF 로 뽑기 전에 배치와 정답지를 고른다.
///
/// 고르지 않고 닫으면 null 이다.
Future<WorksheetOptions?> showPracticePdfExportSheet(
  BuildContext context, {
  required int problemCount,
  required Color accentColor,
}) {
  return showModalBottomSheet<WorksheetOptions>(
    context: context,
    sheetAnimationStyle: AppMotion.sheetStyle,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _PracticePdfExportSheet(
      problemCount: problemCount,
      accentColor: accentColor,
    ),
  );
}

class _PracticePdfExportSheet extends StatefulWidget {
  final int problemCount;
  final Color accentColor;

  const _PracticePdfExportSheet({
    required this.problemCount,
    required this.accentColor,
  });

  @override
  State<_PracticePdfExportSheet> createState() =>
      _PracticePdfExportSheetState();
}

class _PracticePdfExportSheetState extends State<_PracticePdfExportSheet> {
  WorksheetLayout _layout = WorksheetLayout.two;
  bool _withAnswers = true;
  bool _withMemo = true;

  WorksheetOptions get _options => WorksheetOptions(
        layout: _layout,
        withAnswers: _withAnswers,
        withMemo: _withAnswers && _withMemo,
      );

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final pages = worksheetPageCount(widget.problemCount, _options);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            StandardText(
              text: 'PDF로 뽑기',
              fontSize: MobileFontSize.reduced(context, 20),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            const SizedBox(height: 4),
            StandardText(
              text: '${widget.problemCount}문제를 다시 풀 학습지로 만들어요',
              fontSize: MobileFontSize.reduced(context, 14),
              color: Colors.grey[600]!,
            ),
            const SizedBox(height: 22),
            StandardText(
              text: '한 쪽에',
              fontSize: MobileFontSize.reduced(context, 13),
              color: Colors.grey[700]!,
            ),
            const SizedBox(height: 10),
            _buildLayoutPicker(context, accent),
            const SizedBox(height: 10),
            _buildSwitchRow(
              context,
              title: '정답지 맨 뒤에 붙이기',
              subtitle: '정답 사진이랑 짚고 갈 것을 모아 둬요',
              value: _withAnswers,
              onChanged: (value) => setState(() => _withAnswers = value),
            ),
            Divider(height: 1, color: Colors.grey[200]),
            _buildSwitchRow(
              context,
              title: '내 메모 같이 넣기',
              subtitle: '정답지에 같이 들어가요',
              value: _withAnswers && _withMemo,
              onChanged: _withAnswers
                  ? (value) => setState(() => _withMemo = value)
                  : null,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context, _options),
                child: const StandardText(
                  text: 'PDF 만들기',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            StandardText(
              text: 'A4 $pages쪽 · 다 만들면 공유 창이 열려요',
              fontSize: MobileFontSize.reduced(context, 12),
              color: Colors.grey[600]!,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutPicker(BuildContext context, Color accent) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        children: [
          for (final (layout, title, subtitle) in const [
            (WorksheetLayout.two, '두 문제', '풀이 칸 넓게'),
            (WorksheetLayout.four, '네 문제', '종이 아끼기'),
          ])
            Expanded(
              child: _LayoutOption(
                title: title,
                subtitle: subtitle,
                selected: _layout == layout,
                accentColor: accent,
                onTap: () => setState(() => _layout = layout),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final enabled = onChanged != null;
    return MergeSemantics(
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StandardText(
                        text: title,
                        fontSize: MobileFontSize.reduced(context, 15),
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(height: 2),
                      StandardText(
                        text: subtitle,
                        fontSize: MobileFontSize.reduced(context, 12),
                        color: Colors.grey[600]!,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: value,
                  activeTrackColor: widget.accentColor,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LayoutOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _LayoutOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(
              color: selected ? accentColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StandardText(
                text: title,
                fontSize: MobileFontSize.reduced(context, 15),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              const SizedBox(height: 2),
              StandardText(
                text: subtitle,
                fontSize: MobileFontSize.reduced(context, 12),
                color: Colors.grey[600]!,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
