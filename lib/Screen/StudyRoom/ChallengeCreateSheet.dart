import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/StudyRoomProvider.dart';
import '../../Util/AppSnackBar.dart';
import '../../Exception/ApiException.dart';

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
  String _scope = 'individual';
  String _metric = 'problem_count';
  String _period = 'weekly';
  DateTime _endAt = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  static const _scopes = [
    ('individual', '개인'),
    ('group', '그룹'),
  ];

  static const _metrics = [
    ('problem_count', '오답노트 작성', '문제'),
    ('practice_count', '복습 완료', '회'),
    ('attendance', '출석', '일'),
  ];

  static const _periods = [
    ('daily', '일간'),
    ('weekly', '주간'),
    ('monthly', '월간'),
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
        type: _scope,
        metric: _metric,
        period: _period,
        targetValue: target,
        endAt: _endAt,
      );
      if (context.mounted) Navigator.pop(context);
    } catch (error) {
      if (error is ApiException) {
        AppSnackBar.showError(error.getUserMessage());
      } else if (error is BadRequestException) {
        AppSnackBar.showError(error.getUserMessage());
      } else {
        AppSnackBar.showError('챌린지 생성에 실패했습니다');
      }
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
            _Label(text: '참여 방식'),
            const SizedBox(height: 8),
            _buildOptionWrap(
              options: _scopes,
              selectedValue: _scope,
              primary: primary,
              onSelected: (value) => setState(() => _scope = value),
            ),
            const SizedBox(height: 16),
            _Label(text: '챌린지 내용'),
            const SizedBox(height: 8),
            _buildOptionWrap(
              options: _metrics.map((m) => (m.$1, m.$2)).toList(),
              selectedValue: _metric,
              primary: primary,
              onSelected: (value) {
                setState(() {
                  _metric = value;
                  _targetController.clear();
                });
              },
            ),
            const SizedBox(height: 16),
            _Label(text: '기간'),
            const SizedBox(height: 8),
            _buildOptionWrap(
              options: _periods,
              selectedValue: _period,
              primary: primary,
              onSelected: (value) {
                setState(() {
                  _period = value;
                  _endAt = _defaultEndAtFor(value);
                });
              },
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
              suffix: _metricSuffix,
            ),
            const SizedBox(height: 16),
            _Label(text: '마감일'),
            const SizedBox(height: 8),
            InkWell(
              onTap: null,
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

  DateTime _defaultEndAtFor(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case 'daily':
        return today.add(const Duration(days: 1));
      case 'monthly':
        return DateTime(today.year, today.month + 1, today.day);
      case 'weekly':
      default:
        return today.add(const Duration(days: 7));
    }
  }

  String get _metricSuffix {
    return _metrics
        .where((metric) => metric.$1 == _metric)
        .map((metric) => metric.$3)
        .first;
  }

  Widget _buildOptionWrap({
    required List<(String, String)> options,
    required String selectedValue,
    required Color primary,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final selected = selectedValue == option.$1;
        return GestureDetector(
          onTap: () => onSelected(option.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? primary.withOpacity(0.1) : Colors.grey[50],
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: selected ? primary : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: StandardText(
              text: option.$2,
              fontSize: 12,
              color: selected ? primary : Colors.grey[600]!,
            ),
          ),
        );
      }).toList(),
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
