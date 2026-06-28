import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class GoalSetDialog extends StatefulWidget {
  final ThemeHandler themeProvider;
  final int? currentGoal;

  const GoalSetDialog({
    super.key,
    required this.themeProvider,
    this.currentGoal,
  });

  static Future<int?> show(
    BuildContext context,
    ThemeHandler themeProvider, {
    int? currentGoal,
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) => GoalSetDialog(
        themeProvider: themeProvider,
        currentGoal: currentGoal,
      ),
    );
  }

  @override
  State<GoalSetDialog> createState() => _GoalSetDialogState();
}

class _GoalSetDialogState extends State<GoalSetDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentGoal != null ? '${widget.currentGoal}' : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.themeProvider.primaryColor;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.flag_outlined, color: primary, size: 20),
                ),
                const SizedBox(width: 12),
                const StandardText(
                  text: '주간 목표 설정',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ],
            ),
            const SizedBox(height: 8),
            StandardText(
              text: '이번 주 등록할 문제 수 목표를 설정하세요',
              fontSize: 13,
              color: Colors.grey[600]!,
              fontWeight: FontWeight.normal,
              fontFamily: 'PretendardLight',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              textAlign: TextAlign.center,
              style: StandardText(
                text: '',
                fontSize: 24,
                color: primary,
              ).getTextStyle(),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  fontSize: 24,
                  color: Colors.grey[300],
                ),
                suffixText: '문제',
                suffixStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primary, width: 1.5),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[50],
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: const StandardText(
                      text: '취소',
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      final val = int.tryParse(_controller.text);
                      if (val != null && val > 0) {
                        Navigator.pop(context, val);
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const StandardText(
                      text: '저장',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}
