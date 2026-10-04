import 'package:flutter/material.dart';

import '../../../Model/Problem/ProblemAnalysisModel.dart';
import '../../../Model/Problem/ProblemAnalysisStatus.dart';
import '../../../Module/Text/mobile_font_size.dart';
import '../../../Module/Text/StandardLightText.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Design/AppColors.dart';

/// AI 분석 결과 칸.
///
/// [onRequestAnalysis] 를 넘기면 분석하지 않은 문제, 한도 초과, 실패일 때
/// 분석을 다시 요청하는 버튼을 단다. [timedOut] 은 분석을 기다리다 화면이
/// 확인을 멈췄다는 뜻이고, 그때는 [onRefreshAnalysis] 로 다시 확인하게 한다.
Widget buildAnalysisSection(
  BuildContext context,
  ProblemAnalysisModel? analysis,
  Color primaryColor, {
  VoidCallback? onRequestAnalysis,
  bool timedOut = false,
  VoidCallback? onRefreshAnalysis,
}) {
  // analysis가 null이면 숨김 (문제 이미지가 없는 경우)
  if (analysis == null) {
    return _buildNoImageState(context, primaryColor);
  }

  // 분석 상태에 따라 다른 UI 표시
  switch (analysis.status) {
    case ProblemAnalysisStatus.NO_IMAGE:
      // 이미지가 없는 경우 안내 메시지 표시
      return _buildNoImageState(context, primaryColor);
    case ProblemAnalysisStatus.NOT_STARTED:
      // 분석을 요청하지 않은 문제다. 등록할 때 AI 분석을 끄면 이 상태로 남는다.
      // 전에는 분석 중으로 보여서 끝나지 않는 로딩처럼 보였다.
      return _buildNoticeState(
        context,
        primaryColor,
        icon: Icons.auto_awesome_outlined,
        iconColor: primaryColor,
        title: 'AI 분석을 하지 않은 문제예요',
        body: '분석하면 풀이 방향과 주의할 점을 정리해 드려요',
        buttonLabel: 'AI 분석하기',
        onPressed: onRequestAnalysis,
      );
    case ProblemAnalysisStatus.RATE_LIMIT_EXCEEDED:
      return _buildNoticeState(
        context,
        primaryColor,
        icon: Icons.hourglass_empty_rounded,
        iconColor: Colors.orange,
        title: '오늘 AI 분석 횟수를 모두 썼어요',
        body: '하루에 20번까지 분석할 수 있어요. 내일 다시 분석해 주세요',
        buttonLabel: '다시 분석하기',
        onPressed: onRequestAnalysis,
      );
    case ProblemAnalysisStatus.PROCESSING:
      if (timedOut) {
        return _buildNoticeState(
          context,
          primaryColor,
          icon: Icons.schedule_rounded,
          iconColor: primaryColor,
          title: '분석이 생각보다 오래 걸리고 있어요',
          body: '잠시 뒤에 다시 확인해 주세요',
          buttonLabel: '다시 확인하기',
          onPressed: onRefreshAnalysis,
        );
      }
      return _buildProcessingState(context, primaryColor);
    case ProblemAnalysisStatus.FAILED:
      return _buildFailedState(
          context, analysis.errorMessage, primaryColor, onRequestAnalysis);
    case ProblemAnalysisStatus.COMPLETED:
      return _buildCompletedState(context, analysis, primaryColor);
    default:
      return const SizedBox.shrink();
  }
}

Widget _buildNoticeState(
  BuildContext context,
  Color primaryColor, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required String body,
  required String buttonLabel,
  VoidCallback? onPressed,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Icon(icon, color: iconColor, size: 44),
        const SizedBox(height: 14),
        StandardText(
          text: title,
          fontSize: MobileFontSize.reduced(context, 15),
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        StandardText(
          text: body,
          fontSize: 13,
          color: AppColors.textSecondary,
          textAlign: TextAlign.center,
        ),
        if (onPressed != null) ...[
          const SizedBox(height: 16),
          _buildActionButton(buttonLabel, primaryColor, onPressed),
        ],
      ],
    ),
  );
}

Widget _buildActionButton(
    String label, Color primaryColor, VoidCallback onPressed) {
  return OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: primaryColor,
      side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
    ),
    child: StandardText(
      text: label,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: primaryColor,
    ),
  );
}

Widget _buildNoImageState(BuildContext context, Color primaryColor) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_not_supported,
          color: Colors.grey[400],
          size: 48,
        ),
        const SizedBox(height: 16),
        StandardText(
          text: '이미지가 없어 분석하지 못했어요',
          fontSize: MobileFontSize.reduced(context, 15),
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        const SizedBox(height: 8),
        StandardText(
          text: '문제 이미지를 추가하면 AI가 자동으로 분석해드려요',
          fontSize: 13,
          color: AppColors.textSecondary,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget _buildProcessingState(BuildContext context, Color primaryColor) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Row(children: [
      //   Icon(Icons.auto_awesome, color: primaryColor),
      //   const SizedBox(width: 8),
      //   HandWriteText(text: 'AI 분석 중', fontSize: 20, color: primaryColor),
      // ]),
      // verticalSpacer(context, .02),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.medium),
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
            StandardText(
              text: 'AI가 문제를 분석하고 있어요',
              fontSize: MobileFontSize.reduced(context, 16),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            const SizedBox(height: 8),
            const StandardText(
              text: '잠시만 기다려주세요',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildFailedState(BuildContext context, String? errorMessage,
    Color primaryColor, VoidCallback? onRetry) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.medium),
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
              fontSize: MobileFontSize.reduced(context, 15),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            if (errorMessage != null && errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              StandardText(
                text: errorMessage,
                fontSize: 12,
                color: AppColors.textSecondary,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              _buildActionButton('다시 분석하기', primaryColor, onRetry),
            ],
          ],
        ),
      ),
    ],
  );
}

Widget _buildCompletedState(
    BuildContext context, ProblemAnalysisModel analysis, Color primaryColor) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.large),
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
        if (analysis.subject != null)
          _buildAnalysisSection(
              context, '과목', analysis.subject!, Icons.book, primaryColor),
        if (analysis.subject != null && _hasMoreSections(analysis, 'subject'))
          _buildDivider(),
        if (analysis.problemType != null)
          _buildAnalysisSection(context, '문제 유형', analysis.problemType!,
              Icons.category, primaryColor),
        if (analysis.problemType != null &&
            _hasMoreSections(analysis, 'problemType'))
          _buildDivider(),
        if (analysis.keyPoints != null && analysis.keyPoints!.isNotEmpty)
          _buildAnalysisListSection(context, '핵심 포인트', analysis.keyPoints!,
              Icons.lightbulb, primaryColor),
        if (analysis.keyPoints != null &&
            analysis.keyPoints!.isNotEmpty &&
            _hasMoreSections(analysis, 'keyPoints'))
          _buildDivider(),
        if (analysis.solution != null)
          _buildAnalysisSection(context, '풀이', analysis.solution!,
              Icons.psychology, primaryColor),
        if (analysis.solution != null && _hasMoreSections(analysis, 'solution'))
          _buildDivider(),
        if (analysis.commonMistakes != null)
          _buildAnalysisSection(context, '자주 하는 실수', analysis.commonMistakes!,
              Icons.warning_amber_rounded, primaryColor),
        if (analysis.commonMistakes != null &&
            _hasMoreSections(analysis, 'commonMistakes'))
          _buildDivider(),
        if (analysis.studyTips != null)
          _buildAnalysisSection(context, '학습 팁', analysis.studyTips!,
              Icons.tips_and_updates, primaryColor),
      ],
    ),
  );
}

bool _hasMoreSections(ProblemAnalysisModel analysis, String currentSection) {
  switch (currentSection) {
    case 'subject':
      return analysis.problemType != null ||
          (analysis.keyPoints != null && analysis.keyPoints!.isNotEmpty) ||
          analysis.solution != null ||
          analysis.commonMistakes != null ||
          analysis.studyTips != null;
    case 'problemType':
      return (analysis.keyPoints != null && analysis.keyPoints!.isNotEmpty) ||
          analysis.solution != null ||
          analysis.commonMistakes != null ||
          analysis.studyTips != null;
    case 'keyPoints':
      return analysis.solution != null ||
          analysis.commonMistakes != null ||
          analysis.studyTips != null;
    case 'solution':
      return analysis.commonMistakes != null || analysis.studyTips != null;
    case 'commonMistakes':
      return analysis.studyTips != null;
    default:
      return false;
  }
}

Widget _buildDivider() {
  return const Column(
    children: [
      SizedBox(height: 20),
      Divider(color: Colors.grey, thickness: 0.5),
      SizedBox(height: 20),
    ],
  );
}

Widget _buildAnalysisSection(BuildContext context, String label, String content,
    IconData icon, Color primaryColor) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Icon(icon, color: primaryColor, size: 18),
          ),
          const SizedBox(width: 8),
          StandardText(
            text: label,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ],
      ),
      const SizedBox(height: 12),
      StandardLightText(
        text: content,
        fontSize: MobileFontSize.reduced(context, 13),
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    ],
  );
}

Widget _buildAnalysisListSection(BuildContext context, String label,
    List<String> items, IconData icon, Color primaryColor) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Icon(icon, color: primaryColor, size: 18),
          ),
          const SizedBox(width: 8),
          StandardText(
            text: label,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ],
      ),
      const SizedBox(height: 12),
      ...items.asMap().entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(top: entry.key == 0 ? 0 : 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StandardLightText(
                  text: entry.value,
                  fontSize: MobileFontSize.reduced(context, 13),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }),
    ],
  );
}
