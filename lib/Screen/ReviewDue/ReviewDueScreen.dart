import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/Model/Problem/ReviewDueProblemModel.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Module/Problem/ProblemThumbnailCard.dart';
import 'package:ono/Module/Text/StandardText.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Provider/ReviewDueProvider.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreen.dart';
import 'package:ono/Service/Api/Problem/ProblemService.dart';
import 'package:ono/Util/AppAnalytics.dart';
import 'package:ono/Util/ReviewScheduleText.dart';
import 'package:provider/provider.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/Skeleton.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppColors.dart';

class ReviewDueScreen extends StatefulWidget {
  const ReviewDueScreen({super.key, this.problemService});

  /// 테스트에서 가짜 서비스를 넣을 때만 쓴다. 없으면 진짜 서비스를 만든다.
  final ProblemService? problemService;

  @override
  State<ReviewDueScreen> createState() => _ReviewDueScreenState();
}

class _ReviewDueScreenState extends State<ReviewDueScreen> {
  late final ProblemService _problemService =
      widget.problemService ?? ProblemService();
  Map<int, ProblemModel> _problemDetails = {};

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logEvent(name: 'review_due_screen_view');
    AppAnalytics.logScreenView('ReviewDueScreen');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 받아 둔 목록이 있으면 먼저 보이고 늘 다시 받는다. 전에는 목록이 없을
      // 때만 받아서, 다른 곳에서 복습하고 와도 이미 푼 문제가 그대로 남았다.
      final provider = Provider.of<ReviewDueProvider>(context, listen: false);
      await provider.fetchReviewDue();
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
          ? const SkeletonList(
              itemCount: 5,
              itemHeight: 88,
              spacing: 12,
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
            )
          : data == null && reviewDueProvider.hasError
              ? _buildErrorState(themeProvider)
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
                            (p) => _buildProblemTile(
                              context,
                              p,
                              data.requiredCorrectCount,
                              themeProvider,
                            ),
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
        borderRadius: BorderRadius.circular(AppRadius.large),
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
                      color: AppColors.textPrimary,
                    ),
                    StandardText(
                      text: '${data.dueCount}개',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: themeProvider.primaryColor,
                    ),
                  ],
                ),
                if (data.requiredCorrectCount != null) ...[
                  const SizedBox(height: 3),
                  StandardText(
                    text: '${data.requiredCorrectCount}번 맞히면 추천에서 빠져요',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ],
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
    int? requiredCorrectCount,
    ThemeHandler themeProvider,
  ) {
    final correctCount = problem.correctCount;
    final dueChip = ReviewScheduleText.dueChip(problem.nextReviewAt);
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
      child: PressableScale(
        haptic: HapticLevel.none,
        onTap: () async {
          // 추천 목록에서 실제로 문제를 여는지. 연속으로 맞힌 횟수가 적은
          // 문제부터 여는지도 본다.
          AppAnalytics.logEvent('review_due_problem_open', {
            'review_interval': problem.reviewInterval,
            'correct_streak': problem.consecutiveCorrectCount,
          });
          await Navigator.push(
            context,
            TossPageRoute(
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
          // 추천에서 빠지기까지 몇 번 남았는지 보이도록 막대를 맞힌 횟수로 채운다.
          // 예전 서버라 맞힌 횟수가 없으면 전처럼 푼 횟수로 채운다.
          solveCount: correctCount ??
              detail?.solveCount ??
              problem.consecutiveCorrectCount,
          lastSolvedAt: detail?.lastSolvedAt,
          themeProvider: themeProvider,
          progressLabel: correctCount != null && requiredCorrectCount != null
              ? '정답 $correctCount/$requiredCorrectCount'
              : null,
          statusLabel: dueChip,
          statusColor: dueChip == null || dueChip == '오늘'
              ? themeProvider.primaryColor
              : Colors.orange.shade700,
        ),
      ),
    );
  }

  /// 처음 불러오다 실패했을 때. 전에는 데이터가 비어 `추천 복습 문제가 없어요` 가
  /// 떴고 다시 시도할 방법도 없었다.
  Widget _buildErrorState(ThemeHandler themeProvider) {
    return _buildRefreshableCenter(
      themeProvider,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 56,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          const StandardText(
            text: '추천 복습을 불러오지 못했어요',
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 6),
          const StandardText(
            text: '인터넷 연결을 확인하고 다시 시도해 주세요',
            fontSize: 13,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: _refresh,
            style: OutlinedButton.styleFrom(
              foregroundColor: themeProvider.primaryColor,
              side: BorderSide(
                  color: themeProvider.primaryColor.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: StandardText(
              text: '다시 시도',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: themeProvider.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 빈 화면에서도 당겨서 새로고침이 되도록, 가운데 내용을 스크롤 가능한 칸에 둔다.
  Widget _buildRefreshableCenter(ThemeHandler themeProvider, Widget child) {
    return RefreshIndicator(
      color: themeProvider.primaryColor,
      onRefresh: _refresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeHandler themeProvider) {
    return _buildRefreshableCenter(
      themeProvider,
      Column(
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
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 6),
          const StandardText(
            text: '문제를 풀면 자동으로 복습 일정이 생겨요',
            fontSize: 13,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
