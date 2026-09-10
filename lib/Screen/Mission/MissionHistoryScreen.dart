import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Mission/MissionHistoryModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/AnimatedCountText.dart';
import '../../Module/Motion/AppearTransition.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Service/Api/Mission/MissionService.dart';
import 'MissionIcon.dart';
import 'MissionPalette.dart';
import 'MissionPeriodLabel.dart';
import 'MissionRewardChip.dart';

/// 지금까지 받은 보상을 모아 보여 주는 화면이다.
///
/// 미션 화면의 `오늘 +N XP` 칩에서 들어온다. 오늘 얼마 받았는지가 궁금하면
/// 그다음은 "지금까지 얼마나 받았지"라서, 그 숫자를 누르면 여기로 온다.
///
/// 조회에 실패해도 오류를 띄우지 않는다. 백엔드에 아직 이 API 가 없을 수 있고,
/// 기록은 없어도 앱이 도는 데 지장이 없다.
class MissionHistoryScreen extends StatefulWidget {
  /// 테스트에서 가짜를 끼우기 위한 자리. 앱에서는 비워 둔다.
  final MissionService? missionService;

  const MissionHistoryScreen({super.key, this.missionService});

  @override
  State<MissionHistoryScreen> createState() => _MissionHistoryScreenState();
}

class _MissionHistoryScreenState extends State<MissionHistoryScreen> {
  late final MissionService _missionService =
      widget.missionService ?? MissionService();

  final ScrollController _scrollController = ScrollController();

  final List<MissionHistoryItemModel> _items = [];

  /// 첫 페이지에만 실려 오는 합계. 다음 페이지에서 덮어쓰지 않는다.
  int? _totalXp;
  int? _totalCount;

  int? _nextCursor;
  bool _hasNext = true;
  bool _isLoading = false;

  /// 첫 조회가 끝났는지. 끝나기 전에는 빈 상태 문구를 띄우지 않는다.
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  /// 다음 페이지를 읽는다.
  ///
  /// 더 없으면([_hasNext] 가 false) 부르지 않는다. 서버가 끝이라고 했는데 계속
  /// 물어보면 스크롤할 때마다 헛요청이 나간다.
  Future<void> _loadMore() async {
    if (_isLoading || !_hasNext) return;
    setState(() => _isLoading = true);

    final page = await _missionService.getHistory(cursor: _nextCursor);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _loadedOnce = true;

      if (page == null) {
        // 조회에 실패하면 더 조르지 않는다. 오류도 띄우지 않는다.
        _hasNext = false;
        return;
      }

      _items.addAll(page.content);
      _totalXp ??= page.totalClaimedXp;
      _totalCount ??= page.totalClaimedCount;
      _nextCursor = page.nextCursor;
      _hasNext = !page.isLastPage;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _totalXp = null;
      _totalCount = null;
      _nextCursor = null;
      _hasNext = true;
      _loadedOnce = false;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: StandardText(
          text: '받은 보상',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
      ),
      body: RefreshIndicator(
        color: themeProvider.primaryColor,
        onRefresh: _refresh,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            _buildSummary(themeProvider.primaryColor),
            const SizedBox(height: AppSpacing.lg),
            ..._buildBody(),
          ],
        ),
      ),
    );
  }

  /// 맨 위의 합계. 서버가 합계를 주지 않으면 지금 읽은 것으로 센다.
  Widget _buildSummary(Color primary) {
    final xp =
        _totalXp ?? _items.fold<int>(0, (sum, item) => sum + item.rewardValue);
    final count = _totalCount ?? _items.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          primary.withValues(alpha: 0.10),
          Colors.white,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
      ),
      child: Row(
        children: [
          MissionRewardToken(size: 40, color: primary),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StandardText(
                  text: '지금까지 받은 보상',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primary,
                  maxLines: 1,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: AppSpacing.sm,
                  children: [
                    AnimatedCountText(
                      value: xp,
                      formatter: (value) => '${value.round()} XP',
                      fontSize: 26,
                      color: primary,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: StandardText(
                        text: '미션 $count개',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody() {
    if (_items.isEmpty) {
      if (!_loadedOnce) {
        return const [
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.xxxl),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      }
      // 오류처럼 보이지 않게 둔다. 아직 받은 것이 없을 뿐이다.
      return const [
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.xxxl),
          child: StandardText(
            text: '아직 받은 보상이 없어요',
            fontSize: 14,
            color: AppColors.textTertiary,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      ];
    }

    final rows = <Widget>[];
    String? lastLabel;
    for (final item in _items) {
      final label = MissionPeriodLabel.ofDate(item.claimedAt);
      if (label != lastLabel) {
        lastLabel = label;
        rows.add(
          Padding(
            padding: EdgeInsets.only(
              top: rows.isEmpty ? 0 : AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
            child: StandardText(
              text: label,
              fontSize: 13,
              color: AppColors.textSecondary,
              maxLines: 1,
            ),
          ),
        );
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _MissionHistoryRow(item: item),
        ),
      );
    }

    if (_isLoading) {
      rows.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AppearTransition.stagger(rows);
  }
}

/// 받은 보상 한 줄. 미션 목록과 같은 갈래 색을 쓴다.
class _MissionHistoryRow extends StatelessWidget {
  final MissionHistoryItemModel item;

  const _MissionHistoryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = MissionPalette.colorsOf(
      code: item.code,
      iconKey: item.iconKey,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          MissionIconBox(
            iconKey: item.iconKey,
            code: item.code,
            colors: colors,
            padding: 6,
            iconSize: 26,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StandardText(
                  text: item.title,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                StandardText(
                  text: _timeLabel(item.claimedAt),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          MissionRewardChip(
            rewardType: item.rewardType,
            amount: item.rewardValue,
          ),
        ],
      ),
    );
  }

  /// `오후 2:33`. intl 로케일을 따로 쓰지 않고 직접 만든다.
  static String _timeLabel(DateTime time) {
    final isMorning = time.hour < 12;
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '${isMorning ? '오전' : '오후'} $hour12:$minute';
  }
}
