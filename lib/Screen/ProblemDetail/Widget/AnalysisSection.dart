import 'package:flutter/material.dart';
import 'package:ono/Module/Text/HandWriteText.dart';
import 'package:ono/Screen/ProblemDetail/Widget/LayoutHelpers.dart';

import '../../../Model/Problem/ProblemAnalysisModel.dart';
import '../../../Model/Problem/ProblemAnalysisStatus.dart';
import '../../../Module/Text/StandardText.dart';

Widget buildAnalysisSection(
    BuildContext context, ProblemAnalysisModel? analysis, Color primaryColor) {
  // analysis가 null이면 숨김 (문제 이미지가 없는 경우)
  if (analysis == null) {
    return const SizedBox.shrink();
  }

  // 분석 상태에 따라 다른 UI 표시
  switch (analysis.status) {
    case ProblemAnalysisStatus.NO_IMAGE:
      // 이미지가 없는 경우 AI 분석 섹션 숨김
      return const SizedBox.shrink();
    case ProblemAnalysisStatus.NOT_STARTED:
      // NOT_STARTED 상태도 PROCESSING으로 표시 (서버에서 분석 시작 전)
      return _buildProcessingState(context, primaryColor);
    case ProblemAnalysisStatus.PROCESSING:
      return _buildProcessingState(context, primaryColor);
    case ProblemAnalysisStatus.FAILED:
      return _buildFailedState(context, analysis.errorMessage, primaryColor);
    case ProblemAnalysisStatus.COMPLETED:
      return _buildCompletedState(context, analysis, primaryColor);
    default:
      return const SizedBox.shrink();
  }
}

Widget _buildProcessingState(BuildContext context, Color primaryColor) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(Icons.auto_awesome, color: primaryColor),
        const SizedBox(width: 8),
        HandWriteText(text: 'AI 분석 중', fontSize: 20, color: primaryColor),
      ]),
      verticalSpacer(context, .02),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const StandardText(
              text: 'AI가 문제를 분석하고 있어요',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            const SizedBox(height: 8),
            const StandardText(
              text: '잠시만 기다려주세요',
              fontSize: 13,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildFailedState(
    BuildContext context, String? errorMessage, Color primaryColor) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(Icons.error_outline, color: Colors.red),
        const SizedBox(width: 8),
        HandWriteText(text: 'AI 분석 실패', fontSize: 20, color: Colors.red),
      ]),
      verticalSpacer(context, .02),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            StandardText(
              text: '분석 중 오류가 발생했어요',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            if (errorMessage != null && errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              StandardText(
                text: errorMessage,
                fontSize: 12,
                color: Colors.black54,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            StandardText(
              text: '잠시 후 다시 시도해주세요',
              fontSize: 13,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildCompletedState(
    BuildContext context, ProblemAnalysisModel analysis, Color primaryColor) {
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
