import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Model/Tag/TagModel.dart';
import '../Image/DisplayImage.dart';
import '../Text/StandardText.dart';
import '../Theme/ThemeHandler.dart';

class ProblemThumbnailCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final List<TagModel> tags;
  final int solveCount;
  final DateTime? lastSolvedAt;
  final ThemeHandler themeProvider;
  final bool isSelected;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const ProblemThumbnailCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.tags,
    required this.solveCount,
    required this.lastSolvedAt,
    required this.themeProvider,
    this.isSelected = false,
    this.trailing,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildImage(),
          const SizedBox(width: 16),
          Expanded(child: _buildTextColumn()),
          const SizedBox(width: 12),
          trailing ??
              _buildSolveMeta(
                solveCount,
                lastSolvedAt,
                themeProvider,
              ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return SizedBox(
      width: 50,
      height: 70,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 0.8,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: isSelected
            ? Icon(Icons.check, color: themeProvider.primaryColor)
            : DisplayImage(
                imagePath: imageUrl,
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Widget _buildTextColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        StandardText(
          text: title,
          color: Colors.black,
          fontSize: 16,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tags.isNotEmpty
              ? tags.map((tag) => _buildTag('#${tag.name}')).toList()
              : [_buildEmptyTag()],
        ),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: themeProvider.primaryColor,
          width: 1,
        ),
      ),
      child: StandardText(
        text: text,
        fontSize: 10,
        color: themeProvider.primaryColor,
      ),
    );
  }

  Widget _buildEmptyTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: StandardText(
        text: '태그 없음',
        fontSize: 10,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildSolveMeta(
    int solveCount,
    DateTime? lastSolvedAt,
    ThemeHandler themeProvider,
  ) {
    final cappedSolveCount = solveCount.clamp(0, 3);
    final lastSolvedDateText =
        lastSolvedAt != null ? DateFormat('M/d').format(lastSolvedAt) : null;

    return Semantics(
      label: lastSolvedDateText == null
          ? '복습 기록 없음, 풀이 진행 $cappedSolveCount/3'
          : '최근 복습 $lastSolvedDateText, 풀이 진행 $cappedSolveCount/3',
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final filled = index < cappedSolveCount;
                  return Container(
                    width: 12,
                    height: 4,
                    margin: EdgeInsets.only(right: index == 2 ? 0 : 3),
                    decoration: BoxDecoration(
                      color: filled
                          ? themeProvider.primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: lastSolvedDateText != null
                    ? themeProvider.primaryColor.withValues(alpha: 0.07)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(7),
              ),
              child: lastSolvedDateText != null
                  ? Column(
                      children: [
                        StandardText(
                          text: '최근 복습',
                          fontSize: 10,
                          color: themeProvider.primaryColor,
                        ),
                        const SizedBox(height: 1),
                        StandardText(
                          text: lastSolvedDateText,
                          fontSize: 10,
                          color: themeProvider.primaryColor,
                        ),
                      ],
                    )
                  : StandardText(
                      text: '기록 없음',
                      fontSize: 10,
                      color: Colors.grey.shade400,
                      textAlign: TextAlign.center,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
