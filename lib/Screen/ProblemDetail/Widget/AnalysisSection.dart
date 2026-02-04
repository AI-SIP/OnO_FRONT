import 'package:flutter/material.dart';
import 'package:ono/Module/Text/HandWriteText.dart';
import 'package:ono/Screen/ProblemDetail/Widget/LayoutHelpers.dart';

import '../../../Model/Problem/ProblemAnalysisModel.dart';
import '../../../Model/Problem/ProblemAnalysisStatus.dart';
import '../../../Module/Text/StandardText.dart';

Widget buildAnalysisSection(
    BuildContext context, ProblemAnalysisModel? analysis, Color primaryColor) {
  if (analysis == null) {
    return const SizedBox.shrink();
  }

  // 분석 상태가 COMPLETED가 아니면 표시하지 않음
  if (analysis.status != ProblemAnalysisStatus.COMPLETED) {
    return const SizedBox.shrink();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(Icons.tips_and_updates, color: primaryColor),
        const SizedBox(width: 8),
        HandWriteText(text: 'AI 분석 결과', fontSize: 20, color: primaryColor),
      ]),
      verticalSpacer(context, .02),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (analysis.subject != null) ...[
              _buildAnalysisItem('과목', analysis.subject!, primaryColor),
              const SizedBox(height: 15),
            ],
            if (analysis.problemType != null) ...[
              _buildAnalysisItem('문제 유형', analysis.problemType!, primaryColor),
              const SizedBox(height: 15),
            ],
            if (analysis.keyPoints != null &&
                analysis.keyPoints!.isNotEmpty) ...[
              _buildAnalysisListItem(
                  '핵심 포인트', analysis.keyPoints!, primaryColor),
              const SizedBox(height: 15),
            ],
            if (analysis.solution != null) ...[
              _buildAnalysisItem('풀이', analysis.solution!, primaryColor),
              const SizedBox(height: 15),
            ],
            if (analysis.commonMistakes != null) ...[
              _buildAnalysisItem(
                  '자주 하는 실수', analysis.commonMistakes!, primaryColor),
              const SizedBox(height: 15),
            ],
            if (analysis.studyTips != null) ...[
              _buildAnalysisItem('학습 팁', analysis.studyTips!, primaryColor),
            ],
          ],
        ),
      )
    ],
  );
}

Widget _buildAnalysisItem(String label, String content, Color primaryColor) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      StandardText(
        text: label,
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
      const SizedBox(height: 6),
      StandardText(
        text: content,
        fontSize: 12,
        fontWeight: FontWeight.w100, // 더 얇은 글씨
        color: Colors.black87,
      ),
    ],
  );
}

Widget _buildAnalysisListItem(
    String label, List<String> items, Color primaryColor) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      StandardText(
        text: label,
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
      const SizedBox(height: 4),
      ...items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StandardText(
                  text: '• ',
                  fontSize: 13,
                  color: primaryColor,
                ),
                Expanded(
                  child: StandardText(
                    text: item,
                    fontSize: 12,
                    fontWeight: FontWeight.w300, // 더 얇은 글씨
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          )),
    ],
  );
}
