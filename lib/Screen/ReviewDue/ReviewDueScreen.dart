import 'package:flutter/material.dart';
import 'package:ono/Model/Problem/ReviewDueProblemModel.dart';
import 'package:ono/Module/Image/DisplayImage.dart';
import 'package:ono/Module/Text/StandardText.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Provider/ReviewDueProvider.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreen.dart';
import 'package:ono/Service/Api/Problem/ProblemService.dart';
import 'package:provider/provider.dart';

class ReviewDueScreen extends StatefulWidget {
  const ReviewDueScreen({super.key});

  @override
  State<ReviewDueScreen> createState() => _ReviewDueScreenState();
}

class _ReviewDueScreenState extends State<ReviewDueScreen> {
  final ProblemService _problemService = ProblemService();
  Map<int, String?> _thumbnailUrls = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<ReviewDueProvider>(context, listen: false);
      if (provider.data == null) {
        await provider.fetchReviewDue();
      }
      if (provider.data != null) {
        await _loadThumbnails(provider.data!.problems);
      }
    });
  }

  Future<void> _loadThumbnails(List<ReviewDueProblemModel> problems) async {
    if (problems.isEmpty) return;
    final entries = await Future.wait(
      problems.map((p) async {
        try {
          final model = await _problemService.getProblem(
            p.problemId,
            showErrorSnackBar: false,
          );
          final url = model.problemImageDataList?.isNotEmpty == true
              ? model.problemImageDataList!.first.imageUrl
              : null;
          return MapEntry(p.problemId, url);
        } catch (_) {
          return MapEntry(p.problemId, null);
        }
      }),
    );
    if (!mounted) return;
    setState(() {
      _thumbnailUrls = Map.fromEntries(entries);
    });
  }

  Future<void> _refresh() async {
    final provider = Provider.of<ReviewDueProvider>(context, listen: false);
    await provider.fetchReviewDue();
    if (provider.data != null) {
      await _loadThumbnails(provider.data!.problems);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final reviewDueProvider = Provider.of<ReviewDueProvider>(context);
    final data = reviewDueProvider.data;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: StandardText(
          text: '추천 복습 문제',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
      ),
      body: reviewDueProvider.isLoading && data == null
          ? Center(
              child: CircularProgressIndicator(
                color: themeProvider.primaryColor,
              ),
            )
          : data == null || data.problems.isEmpty
              ? _buildEmptyState(themeProvider)
              : RefreshIndicator(
                  color: themeProvider.primaryColor,
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _buildHeader(data, themeProvider),
                      const SizedBox(height: 16),
                      ...data.problems.map(
                        (p) => _buildProblemTile(context, p, themeProvider),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(ReviewDueResponse data, ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StandardText(
                      text: '추천 복습 문제 ',
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    StandardText(
                      text: '${data.dueCount}개',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: themeProvider.primaryColor,
                    ),
                  ],
                ),
                if (data.overdueCount > 0) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 13, color: Colors.orange.shade600),
                      const SizedBox(width: 4),
                      StandardText(
                        text: '이 중 ${data.overdueCount}개는 밀린 문제예요',
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.auto_stories_outlined,
              color: themeProvider.primaryColor.withValues(alpha: 0.5),
              size: 28),
        ],
      ),
    );
  }

  Widget _buildProblemTile(
    BuildContext context,
    ReviewDueProblemModel problem,
    ThemeHandler themeProvider,
  ) {
    final isMastered = problem.consecutiveCorrectCount >= 3;
    final isOverdue = problem.nextReviewAt != null &&
        problem.nextReviewAt!.isBefore(
          DateTime.now().subtract(const Duration(days: 1)),
        );
    final imageUrl = _thumbnailUrls[problem.problemId];
    final title = problem.reference?.isNotEmpty == true
        ? problem.reference!
        : problem.memo?.isNotEmpty == true
            ? problem.memo!
            : '제목 없음';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProblemDetailScreen(problemId: problem.problemId),
            ),
          );
          if (!mounted) return;
          _refresh();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
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
              // 썸네일
              Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!, width: 0.8),
                ),
                clipBehavior: Clip.antiAlias,
                child: DisplayImage(
                  imagePath: imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              // 텍스트 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StandardText(
                      text: title,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    if (problem.memo?.isNotEmpty == true &&
                        problem.reference?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      StandardText(
                        text: problem.memo!,
                        fontSize: 12,
                        color: Colors.grey[500]!,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildProgressDots(
                            problem.consecutiveCorrectCount, themeProvider),
                        const SizedBox(width: 8),
                        if (isMastered)
                          _buildChip('마스터드', Colors.amber.shade700),
                        if (isOverdue && !isMastered)
                          _buildChip('밀린 문제', Colors.orange.shade600),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDots(int count, ThemeHandler themeProvider) {
    return Row(
      children: List.generate(3, (i) {
        final filled = i < count;
        return Container(
          width: 18,
          height: 4,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            color: filled
                ? themeProvider.primaryColor
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: StandardText(
        text: text,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }

  Widget _buildEmptyState(ThemeHandler themeProvider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: themeProvider.primaryColor.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          const StandardText(
            text: '추천 복습 문제가 없어요',
            fontSize: 16,
            color: Colors.black54,
          ),
          const SizedBox(height: 6),
          const StandardText(
            text: '문제를 풀면 자동으로 복습 일정이 생겨요',
            fontSize: 13,
            color: Colors.black38,
          ),
        ],
      ),
    );
  }
}