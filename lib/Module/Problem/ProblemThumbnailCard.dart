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

  /// 푼 횟수 대신 적는 글. 무엇을 세는지 다르게 보일 때 쓴다. 예) '정답 1/3'
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
    this.padding = const EdgeInsets.all(14),
    this.imageWidth = 60,
    this.imageHeight = 76,
    this.contentGap = 14,
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
          if (trailing != null) ...[
            SizedBox(width: trailingGap),
            trailing!,
          ],
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
            // 전에는 이미지 둘레에 여백 10 이 들어가서 칸의 절반도 안 되는
            // 크기로 보였다. 칸을 다 쓰고, 문제가 시작하는 위쪽을 남긴다.
            : imageUrl == null || imageUrl!.isEmpty
                ? DisplayImage(imagePath: imageUrl)
                : DisplayImage(
                    imagePath: imageUrl,
                    fit: BoxFit.cover,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.topCenter,
                  ),
      ),
    );
  }

  Widget _buildTextColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        // 푼 횟수와 최근 복습일. 전에는 카드 오른쪽에 따로 세워서 제목 자리를
        // 줄이고 글자도 작았다. 제목 아래 한 줄로 둔다.
        if (trailing == null) ...[
          const SizedBox(height: 4),
          _buildSolveMeta(solveCount, lastSolvedAt, themeProvider),
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
    final dateText = lastSolvedAt != null ? shortDate(lastSolvedAt) : null;
    final neverSolved = dateText == null && solveCount <= 0;
    final countText = progressLabel ?? '$solveCount회 풂';

    Widget item(IconData icon, String text, Color color) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          StandardText(text: text, fontSize: 12, color: color),
        ],
      );
    }

    if (neverSolved && progressLabel == null) {
      return item(
        Icons.schedule_rounded,
        '아직 안 풀었어요',
        AppColors.textTertiary,
      );
    }
    return Semantics(
      label: dateText == null
          ? '$countText, 복습 기록 없음'
          : '$countText, 최근 복습 $dateText',
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 10,
          runSpacing: 2,
          children: [
            item(Icons.replay_rounded, countText, themeProvider.primaryColor),
            if (dateText != null)
              item(
                Icons.event_available_rounded,
                '$dateText 복습',
                AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}
