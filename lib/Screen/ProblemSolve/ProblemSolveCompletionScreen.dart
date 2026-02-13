import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/Model/Problem/ImprovementType.dart';
import 'package:ono/Module/Dialog/LoadingDialog.dart';
import 'package:ono/Module/Dialog/SnackBarDialog.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/AnswerStatus.dart';
import '../../Model/Problem/ProblemSolveRegisterDto.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/PracticeNoteProvider.dart';
import '../../Provider/ProblemsProvider.dart';
import '../../Provider/UserProvider.dart';
import '../../Service/Api/Problem/ProblemSolveService.dart';
import 'ProblemSolveCompletionTemplate.dart';

class ProblemReviewCompletionScreen extends StatefulWidget {
  final int problemId;
  final VoidCallback onRefresh;

  const ProblemReviewCompletionScreen({
    super.key,
    required this.problemId,
    required this.onRefresh,
  });

  @override
  State<ProblemReviewCompletionScreen> createState() =>
      _ProblemReviewCompletionScreenState();
}

class _ProblemReviewCompletionScreenState
    extends State<ProblemReviewCompletionScreen> {
  final GlobalKey<ProblemReviewCompletionTemplateState> _templateKey =
      GlobalKey<ProblemReviewCompletionTemplateState>();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(themeProvider),
      body: Column(
        children: [
          Expanded(
            child: ProblemReviewCompletionTemplate(
              key: _templateKey,
              problemId: widget.problemId,
            ),
          ),
          _buildSubmitButton(context, themeProvider),
        ],
      ),
    );
  }

  AppBar _buildAppBar(ThemeHandler themeProvider) {
    return AppBar(
      title: StandardText(
        text: '복습 완료',
        fontSize: 20,
        color: themeProvider.primaryColor,
      ),
      backgroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    );
  }

  Widget _buildSubmitButton(BuildContext context, ThemeHandler themeProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? screenWidth * 0.2 : 35.0,
        vertical: 20.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => _handleSubmit(context, themeProvider),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const StandardText(
            text: "문제 복습 완료",
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit(
      BuildContext context, ThemeHandler themeProvider) async {
    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);
    final practiceProvider =
        Provider.of<ProblemPracticeProvider>(context, listen: false);
    final problemSolveService = ProblemSolveService();

    // 템플릿에서 데이터 가져오기
    final reviewData = _templateKey.currentState?.getReviewData();

    if (reviewData == null) {
      return;
    }

    // 최소 1개 이상의 풀이 이미지가 필요
    final List<File> solutionImages =
        reviewData['solutionImages'] as List<File>;
    if (solutionImages.isEmpty) {
      SnackBarDialog.showSnackBar(
        context: context,
        message: '최소 1개의 풀이 이미지를 등록해주세요.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    LoadingDialog.show(context, '복습 기록 저장 중...');

    try {
      // 1. 복습 기록 생성 (ProblemSolve API)
      final registerDto = ProblemSolveRegisterDto(
        problemId: reviewData['problemId'] as int,
        practicedAt: DateTime.now(),
        answerStatus: reviewData['answerStatus'] as AnswerStatus,
        reflection: reviewData['reflection'] as String?,
        improvements: reviewData['improvements'] as List<ImprovementType>,
        timeSpentSeconds: (reviewData['timeSpentMinutes'] as int?) != null
            ? (reviewData['timeSpentMinutes'] as int) * 60
            : null,
      );

      final practiceRecordId =
          await problemSolveService.createProblemSolve(registerDto);

      // 2. 복습 기록 이미지 업로드
      await problemSolveService.uploadProblemSolveImages(
        problemSolveId: practiceRecordId,
        images: solutionImages,
      );

      // 3. 문제 정보 갱신
      await problemsProvider.fetchProblem(widget.problemId);

      // 4. 복습 노트 갱신
      if (practiceProvider.currentPracticeNote != null) {
        await practiceProvider.moveToPractice(
          practiceProvider.currentPracticeNote!.practiceId,
        );
      }

      FirebaseAnalytics.instance.logEvent(name: 'problem_repeat');

      // 5. 유저 정보 갱신 (경험치 업데이트)
      await Provider.of<UserProvider>(context, listen: false).fetchUserInfo();

      LoadingDialog.hide(context);

      if (mounted) {
        Navigator.of(context)
            .pop(true); // ProblemReviewCompletionScreen 닫으면서 true 반환

        SnackBarDialog.showSnackBar(
          context: context,
          message: '복습이 완료되었습니다!',
          backgroundColor: themeProvider.primaryColor,
        );

        // 화면 갱신
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
        SnackBarDialog.showSnackBar(
          context: context,
          message: '복습 기록 저장에 실패했습니다: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }
}
