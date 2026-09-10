import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Mission/MissionHistoryModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/AnimatedCountText.dart';
import '../../Module/Motion/PressableScale.dart';
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

  /// 지금 시각을 읽는 방법.
  ///
  /// 날짜 머리글이 `오늘`/`어제`로 갈리는데, 그 판단이 `DateTime.now()` 에
  /// 직접 붙어 있으면 테스트가 실제 시계에 매인다. 자정을 넘기는 순간이나
  /// 서머타임이 있는 지역에서만 어긋나는 종류의 실패가 난다. 시계를 밖에서
  /// 넣을 수 있게 열어 둔다. 앱에서는 비워 두면 된다.
  final DateTime Function()? clock;

  const MissionHistoryScreen({
    super.key,
    this.missionService,
    this.clock,
  });

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

  /// 마지막 조회가 실패했는지.
  ///
  /// 실패와 "받은 게 없음"은 다르다. 실패한 것을 빈 상태로 보여 주면 보상이
  /// 있는데도 없다고 말하는 셈이라, 사용자가 그대로 믿고 나가 버린다.
  bool _lastLoadFailed = false;

  /// 요청 세대. 새로고침할 때마다 오른다.
  ///
  /// 2페이지 요청이 날아가 있는 동안 새로고침하면, 뒤늦게 도착한 그 응답이
  /// 비워진 목록에 붙고 커서까지 2페이지 것으로 덮어써서 1페이지가 통째로
  /// 사라진다. 떠날 때의 세대와 돌아왔을 때의 세대가 다르면 버린다.
  int _generation = 0;

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

  DateTime _now() => widget.clock?.call() ?? DateTime.now();

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

    final generation = _generation;
    final cursor = _nextCursor;
    final page = await _missionService.getHistory(cursor: cursor);
    if (!mounted) return;

    // 떠나 있는 사이에 새로고침이 있었다면 이 응답은 지난 세대의 것이다.
    // 붙이면 비워진 목록에 옛 페이지가 얹히고 커서도 어긋난다.
    if (generation != _generation) return;

    setState(() {
      _isLoading = false;
      _loadedOnce = true;

      if (page == null) {
        // 조회에 실패하면 스크롤할 때마다 다시 조르지 않는다. 대신 실패했다는
        // 것을 기억해서 사용자가 다시 시도할 수 있게 한다.
        _hasNext = false;
        _lastLoadFailed = true;
        return;
      }

      _lastLoadFailed = false;
      _items.addAll(page.content);
      _totalXp ??= page.totalClaimedXp;
      _totalCount ??= page.totalClaimedCount;
      _nextCursor = page.nextCursor;
      _hasNext = !page.isLastPage;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      // 세대를 올려 나가 있는 요청의 응답을 무효로 만든다.
      _generation++;
      _items.clear();
      _totalXp = null;
      _totalCount = null;
      _nextCursor = null;
      _hasNext = true;
      _loadedOnce = false;
      _lastLoadFailed = false;
      // 나가 있는 요청은 버릴 것이므로 잠금도 함께 푼다. 안 그러면 새 조회가
      // 로딩 가드에 걸려 아무것도 하지 않는다.
      _isLoading = false;
    });
    await _loadMore();
  }

  /// 실패한 뒤 다시 시도한다.
  Future<void> _retry() async {
    setState(() {
      _hasNext = true;
      _lastLoadFailed = false;
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
        child: Builder(
          builder: (context) {
            final entries = _buildEntries();
            // 0 번은 합계, 마지막 한 칸은 더 읽는 중 표시나 빈 상태다.
            final itemCount = entries.length + 2;

            return ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              // 읽은 줄이 전부 트리에 남지 않게 한다. 무한 스크롤이라 줄마다
              // 그림이 하나씩 붙는데, 통째로 들고 있으면 계속 무거워진다.
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _buildSummary(themeProvider.primaryColor),
                  );
                }

                if (index == itemCount - 1) {
                  if (entries.isEmpty) {
                    return _buildEmpty(themeProvider.primaryColor);
                  }
                  if (_isLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return const SizedBox.shrink();
                }

                return _buildEntry(entries[index - 1]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEntry(_HistoryEntry entry) {
    final item = entry.item;
    if (item == null) {
      return Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        child: StandardText(
          text: entry.label,
          fontSize: 13,
          color: AppColors.textSecondary,
          maxLines: 1,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: _MissionHistoryRow(item: item),
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

  /// 화면에 놓을 줄들을 미리 계산한다.
  ///
  /// 날짜 머리글과 보상 줄이 섞여 있어서 인덱스만으로는 무엇을 그릴지 알 수
  /// 없다. 목록이 바뀔 때만 다시 만든다.
  List<_HistoryEntry> _buildEntries() {
    final entries = <_HistoryEntry>[];
    String? lastLabel;
    for (final item in _items) {
      final label = MissionPeriodLabel.ofDate(item.claimedAt, now: _now());
      if (label != lastLabel) {
        lastLabel = label;
        entries.add(_HistoryEntry.header(label));
      }
      entries.add(_HistoryEntry.item(item));
    }
    return entries;
  }

  /// 목록이 비었을 때 무엇을 보여 줄지.
  ///
  /// 실패와 "받은 게 없음"을 가른다. 실패한 것을 빈 상태로 보여 주면 보상이
  /// 있는데도 없다고 말하는 셈이다.
  Widget _buildEmpty(Color primary) {
    if (!_loadedOnce) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xxxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_lastLoadFailed) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxxl),
        child: Column(
          children: [
            const StandardText(
              text: '보상 기록을 불러오지 못했어요',
              fontSize: 14,
              color: AppColors.textTertiary,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            PressableScale(
              onTap: _retry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: const StandardText(
                  text: '다시 시도',
                  fontSize: 13,
                  color: Colors.white,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.only(top: AppSpacing.xxxl),
      child: StandardText(
        text: '아직 받은 보상이 없어요',
        fontSize: 14,
        color: AppColors.textTertiary,
        textAlign: TextAlign.center,
        maxLines: 2,
      ),
    );
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

/// 목록의 한 줄. 날짜 머리글이거나 보상 한 건이다.
class _HistoryEntry {
  final String label;
  final MissionHistoryItemModel? item;

  const _HistoryEntry.header(this.label) : item = null;

  _HistoryEntry.item(MissionHistoryItemModel this.item) : label = '';
}
