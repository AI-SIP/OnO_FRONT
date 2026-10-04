import 'package:flutter/material.dart';

import '../../Model/Tag/TagModel.dart';
import '../Image/DisplayImage.dart';
import '../Text/StandardText.dart';
import '../Theme/ThemeHandler.dart';
import '../Design/AppRadius.dart';
import '../../Util/ShortDate.dart';
import '../../Module/Design/AppColors.dart';

class ProblemThumbnailCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final List<TagModel> tags;
  final int solveCount;
  final DateTime? lastSolvedAt;
  final ThemeHandler themeProvider;
  final bool isSelected;
  final Widget? trailing;

  /// 진행 막대 아래에 적는 글. 주면 막대가 무엇을 세는지 함께 보인다. 예) '정답 1/3'
  final String? progressLabel;

  /// 태그 앞에 붙이는 칩. 추천 복습에서 `오늘`, `3일 밀림` 처럼 왜 지금
  /// 나왔는지 보여 줄 때 쓴다.
  final String? statusLabel;
  final Color? statusColor;

  /// 제목 아래 작게 덧붙이는 한 줄. 검색 결과에서 어느 공책에 있는지 보인다.
  final String? subtitle;
  final EdgeInsetsGeometry padding;
  final double imageWidth;
  final double imageHeight;
  final double contentGap;
  final double trailingGap;
  final double titleFontSize;
  final int titleMaxLines;
  final double tagFontSize;
  final EdgeInsetsGeometry tagPadding;
  final double tagSpacing;
  final double tagRunSpacing;

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
    this.progressLabel,
    this.statusLabel,
    this.statusColor,
    this.subtitle,
    this.padding = const EdgeInsets.all(12),
    this.imageWidth = 50,
    this.imageHeight = 70,
    this.contentGap = 16,
    this.trailingGap = 12,
    this.titleFontSize = 16,
    this.titleMaxLines = 1,
    this.tagFontSize = 10,
    this.tagPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    this.tagSpacing = 6,
    this.tagRunSpacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.medium),
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
          SizedBox(width: contentGap),
          Expanded(child: _buildTextColumn()),
          SizedBox(width: trailingGap),
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
      width: imageWidth,
      height: imageHeight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.small),
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
          fontSize: titleFontSize,
          maxLines: titleMaxLines,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.folder_outlined, size: 13, color: Colors.grey[600]),
              const SizedBox(width: 3),
              Flexible(
                child: StandardText(
                  text: subtitle!,
                  fontSize: 12,
                  color: Colors.grey[700]!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: tagSpacing,
          runSpacing: tagRunSpacing,
          children: [
            if (statusLabel != null) _buildStatusChip(statusLabel!),
            ...tags.isNotEmpty
                ? tags.map((tag) => _buildTag('#${tag.name}'))
                : [_buildEmptyTag()],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String text) {
    final color = statusColor ?? themeProvider.primaryColor;
    return Container(
      padding: tagPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: StandardText(
        text: text,
        fontSize: tagFontSize,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: tagPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: themeProvider.primaryColor,
          width: 1,
        ),
      ),
      child: StandardText(
        text: text,
        fontSize: tagFontSize,
        color: themeProvider.primaryColor,
      ),
    );
  }

  Widget _buildEmptyTag() {
    return Container(
      padding: tagPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: StandardText(
        text: '태그 없음',
        fontSize: tagFontSize,
        color: AppColors.textSecondary,
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
        lastSolvedAt != null ? shortDate(lastSolvedAt) : null;

    final progressText = progressLabel ?? '풀이 진행 $cappedSolveCount/3';
    // 막대만 있으면 세 번 다 틀려도 꽉 차서 맞힌 것처럼 보였다. 추천 카드의
    // '정답 n/3' 과 다른 뜻이라 푼 횟수를 글자로 붙인다.
    final shownLabel = progressLabel ?? '$solveCount회 풂';

    return Semantics(
      label: lastSolvedDateText == null
          ? '복습 기록 없음, $progressText'
          : '최근 복습 $lastSolvedDateText, $progressText',
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
                borderRadius: BorderRadius.circular(AppRadius.small),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
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
                  ...[
                    const SizedBox(height: 4),
                    StandardText(
                      text: shownLabel,
                      fontSize: 10,
                      color: themeProvider.primaryColor,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
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
                borderRadius: BorderRadius.circular(AppRadius.small),
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
                      color: AppColors.textSecondary,
                      textAlign: TextAlign.center,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
