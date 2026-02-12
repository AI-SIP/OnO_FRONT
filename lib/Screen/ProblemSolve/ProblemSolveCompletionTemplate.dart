import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Module/Image/ImagePickerHandler.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../ProblemRegister/Widget/ImageGridWidget.dart';
import '../ProblemRegister/Widget/LabeledTextField.dart';

class ProblemReviewCompletionTemplate extends StatefulWidget {
  final int problemId;

  const ProblemReviewCompletionTemplate({
    Key? key,
    required this.problemId,
  }) : super(key: key);

  @override
  ProblemReviewCompletionTemplateState createState() =>
      ProblemReviewCompletionTemplateState();
}

class ProblemReviewCompletionTemplateState
    extends State<ProblemReviewCompletionTemplate> {
  final _memoCtrl = TextEditingController();
  final List<XFile> _solutionImages = [];
  bool _isCorrect = true; // 정답 여부 (기본값: 맞음)

  // 개선 체크리스트
  final Map<String, bool> _improvements = {
    '이전 실수를 반복하지 않았어요': false,
    '새로운 풀이법을 찾았어요': false,
    '개념을 더 명확히 이해했어요': false,
    '풀이 시간이 단축됐어요': false,
  };

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final isWide = MediaQuery.of(context).size.width >= 600;
    final spacing = isWide ? 50.0 : 30.0;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 35.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            // 복습 완료 헤더
            _buildCompletionHeader(themeProvider),
            SizedBox(height: spacing),

            // 정답 여부 선택
            _buildAnswerStatusSection(themeProvider),
            SizedBox(height: spacing),

            // 개선된 점 체크리스트
            _buildImprovementSection(themeProvider),
            SizedBox(height: spacing),

            // 풀이 이미지 업로드
            ImageGridWidget(
              label: '풀이 이미지',
              files: _solutionImages,
              existingImageUrls: const [],
              onAdd: _pickSolutionImage,
              onRemove: (i) => setState(() => _solutionImages.removeAt(i)),
              onRemoveExisting: (i) {},
            ),
            SizedBox(height: spacing),

            // 복습 메모
            LabeledTextField(
              label: '복습 메모',
              controller: _memoCtrl,
              icon: Icons.edit,
              hintText: '이번 복습에서 느낀 점을 자유롭게 작성해주세요!',
              maxLines: 5,
            ),
            SizedBox(height: spacing),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionHeader(ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: themeProvider.primaryColor,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StandardText(
                  text: '문제 복습 완료!',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.primaryColor,
                ),
                const SizedBox(height: 4),
                const StandardText(
                  text: '복습 내용을 기록해보세요',
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerStatusSection(ThemeHandler themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_outline, color: themeProvider.primaryColor),
            const SizedBox(width: 8),
            const StandardText(
              text: '이번 복습 결과',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAnswerOption(
                label: '맞았어요',
                icon: Icons.check_circle,
                color: Colors.green,
                isSelected: _isCorrect,
                onTap: () => setState(() => _isCorrect = true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAnswerOption(
                label: '틀렸어요',
                icon: Icons.cancel,
                color: Colors.red,
                isSelected: !_isCorrect,
                onTap: () => setState(() => _isCorrect = false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnswerOption({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 8),
            StandardText(
              text: label,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.grey[600]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementSection(ThemeHandler themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: themeProvider.primaryColor),
            const SizedBox(width: 8),
            const StandardText(
              text: '개선된 점',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ],
        ),
        const SizedBox(height: 4),
        const StandardText(
          text: '해당되는 항목을 선택해주세요 (선택사항)',
          fontSize: 13,
          color: Colors.black54,
        ),
        const SizedBox(height: 12),
        ..._improvements.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildCheckboxItem(
              label: entry.key,
              value: entry.value,
              onChanged: (value) {
                setState(() {
                  _improvements[entry.key] = value ?? false;
                });
              },
              themeProvider: themeProvider,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCheckboxItem({
    required String label,
    required bool value,
    required Function(bool?) onChanged,
    required ThemeHandler themeProvider,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: value
              ? themeProvider.primaryColor.withOpacity(0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: value
                ? themeProvider.primaryColor.withOpacity(0.3)
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: themeProvider.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StandardText(
                text: label,
                fontSize: 15,
                color: value ? Colors.black87 : Colors.black54,
                fontWeight: value ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSolutionImage() async {
    final imagePicker = ImagePickerHandler();
    imagePicker.showImagePicker(
      context,
      (XFile? file) {
        if (file != null) {
          setState(() => _solutionImages.add(file));
        }
      },
      onMultipleImagesPicked: (List<XFile> files) {
        setState(() => _solutionImages.addAll(files));
      },
    );
  }

  // API 연동 시 사용할 데이터 수집 메서드
  Map<String, dynamic> getReviewData() {
    return {
      'problemId': widget.problemId,
      'isCorrect': _isCorrect,
      'memo': _memoCtrl.text,
      'solutionImages': _solutionImages.map((f) => File(f.path)).toList(),
      'improvements': _improvements.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList(),
    };
  }

  void resetAll() {
    setState(() {
      _memoCtrl.clear();
      _solutionImages.clear();
      _isCorrect = true;
      _improvements.updateAll((key, value) => false);
    });
  }
}