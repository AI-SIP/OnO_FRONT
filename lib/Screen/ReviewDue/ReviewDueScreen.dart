import 'package:flutter/material.dart';
import 'package:ono/Model/Problem/ReviewDueProblemModel.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Module/Problem/ProblemThumbnailCard.dart';
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
  Map<int, ProblemModel> _problemDetails = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<ReviewDueProvider>(context, listen: false);
      if (provider.data == null) {
        await provider.fetchReviewDue();
      }
      if (provider.data != null) {
        await _loadProblemDetails(provider.data!.problems);
      }
    });
  }

  Future<void> _loadProblemDetails(List<ReviewDueProblemModel> problems) async {
    if (problems.isEmpty) return;
    final entries = await Future.wait(
      problems.map((p) async {
        try {
          final model = await _problemService.getProblem(
            p.problemId,
            showErrorSnackBar: false,
          );
          return MapEntry(p.problemId, model);
        } catch (_) {
          return null;
        }
      }),
    );
    if (!mounted) return;
    setState(() {
      _problemDetails =
          Map.fromEntries(entries.whereType<MapEntry<int, ProblemModel>>());
    });
  }

  Future<void> _refresh() async {
    final provider = Provider.of<ReviewDueProvider>(context, listen: false);
    await provider.fetchReviewDue();
    if (provider.data != null) {
      await _loadProblemDetails(provider.data!.problems);
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
                    const StandardText(
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
    final detail = _problemDetails[problem.problemId];
    final imageUrl = detail?.problemImageDataList?.isNotEmpty == true
        ? detail!.problemImageDataList!.first.imageUrl
        : null;
    final title = detail?.reference?.isNotEmpty == true
        ? detail!.reference!
        : problem.reference?.isNotEmpty == true
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
              builder: (_) => ProblemDetailScreen(problemId: problem.problemId),
            ),
          );
          if (!mounted) return;
          _refresh();
        },
        child: ProblemThumbnailCard(
          title: title,
          imageUrl: imageUrl,
          tags: detail?.tags ?? const [],
          solveCount: detail?.solveCount ?? problem.consecutiveCorrectCount,
          lastSolvedAt: detail?.lastSolvedAt,
          themeProvider: themeProvider,
        ),
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
