import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/StudyRoomProvider.dart';
import '../../Util/AppSnackBar.dart';

class ChallengeCreateSheet extends StatefulWidget {
  const ChallengeCreateSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChallengeCreateSheet(),
    );
  }

  @override
  State<ChallengeCreateSheet> createState() => _ChallengeCreateSheetState();
}

class _ChallengeCreateSheetState extends State<ChallengeCreateSheet> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  String _type = 'individual';
  DateTime _endAt = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  static const _types = [
    ('individual', '개인 챌린지'),
    ('group', '그룹 챌린지'),
    ('streak', '연속 출석'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    final title = _titleController.text.trim();
    final target = int.tryParse(_targetController.text);
    if (title.isEmpty) {
      AppSnackBar.showError('챌린지 제목을 입력해주세요');
      return;
    }
    if (target == null || target <= 0) {
      AppSnackBar.showError('목표 값을 올바르게 입력해주세요');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Provider.of<StudyRoomProvider>(context, listen: false)
          .createChallenge(
        title: title,
        type: _type,
        targetValue: target,
        endAt: _endAt,
      );
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      AppSnackBar.showError('챌린지 생성에 실패했습니다');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    final primary = themeProvider.primaryColor;
    final insets = MediaQuery.of(context).viewInsets;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + insets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.flag_outlined, color: primary, size: 20),
                ),
                const SizedBox(width: 12),
                const StandardText(
                  text: '새 챌린지 만들기',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Label(text: '챌린지 유형'),
            const SizedBox(height: 8),
            Row(
              children: _types.map((t) {
                final selected = _type == t.$1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? primary.withOpacity(0.1)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected ? primary : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: StandardText(
                            text: t.$2,
                            fontSize: 12,
                            color: selected ? primary : Colors.grey[600]!,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _Label(text: '챌린지 제목'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _titleController,
              hint: '예: 이번 주 문제 10개 등록하기',
              primary: primary,
            ),
            const SizedBox(height: 16),
            _Label(text: '목표 값'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _targetController,
              hint: '예: 10',
              primary: primary,
              inputType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              suffix: '문제',
            ),
            const SizedBox(height: 16),
            _Label(text: '마감일'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endAt,
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(primary: primary),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _endAt = picked);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: primary),
                    const SizedBox(width: 10),
                    StandardText(
                      text:
                          '${_endAt.year}.${_endAt.month.toString().padLeft(2, '0')}.${_endAt.day.toString().padLeft(2, '0')}',
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isLoading ? null : () => _submit(context),
                style: TextButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.grey[300] : primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: primary,
                          strokeWidth: 2,
                        ),
                      )
                    : const StandardText(
                        text: '챌린지 시작',
                        fontSize: 16,
                        color: Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required Color primary,
    TextInputType? inputType,
    List<TextInputFormatter>? inputFormatters,
    String? suffix,
  }) {
    final style = StandardText(
      text: '',
      fontSize: 14,
      color: Colors.black87,
    ).getTextStyle();

    return TextField(
      controller: controller,
      keyboardType: inputType,
      inputFormatters: inputFormatters,
      style: style,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
        suffixText: suffix,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return StandardText(
      text: text,
      fontSize: 13,
      color: Colors.grey[700]!,
    );
  }
}
