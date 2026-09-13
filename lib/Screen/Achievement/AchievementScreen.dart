import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Design/AppToast.dart';
import '../../Module/Motion/AnimatedCountText.dart';
import '../../Module/Motion/AnimatedGauge.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/AppearTransition.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/AchievementProvider.dart';
import 'Widget/AchievementCard.dart';

/// 받은 훈장과 아직 못 받은 훈장을 한 목록으로 보여 주는 화면이다.
///
/// 레벨과 치장은 "얼마나 많이 했나" 하나만 말한다. 오답노트를 백 개 모은 것도,
/// 틀렸던 문제를 기어이 맞힌 것도, 서른 날을 하루도 안 빼먹은 것도 전부 같은
/// 포인트로 뭉개진다. 이 화면이 그런 순간을 따로 남긴다.
///
/// **못 받은 것을 감추지 않는다.** 흑백으로 함께 세우고 무엇을 얼마나 더 하면
/// 되는지를 적는다. 이미 87개를 적은 사람이 자기가 코앞이라는 것을 알아야
/// 한다. 이 화면은 따로 여는 화면이라 스크롤이 있어도 된다. 옷장 탭은 스크롤
/// 없이 한 화면이라는 제약이 있어서 열두 줄이 거기 들어갈 자리가 없었다.
///
/// **들어올 때마다 다시 읽는다.** 조회 자체가 서버에서 조건을 다시 세는
/// 순간이라, 방금 채운 조건은 이 화면을 여는 것으로 드러난다.
///
/// 새로 받은 것이 있으면 알림 한 줄을 띄우고 그 줄에 `NEW` 를 단다. 어디서
/// 받아 온 것이든([AchievementProvider.consumeCelebration]) 여기서 한 번은
/// 반드시 알린다. 조용히 늘어 있기만 하면 받은 줄도 모른다.
class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  /// 이번에 알린 훈장 key 들. 목록에서 `NEW` 가 붙는 줄이다.
  ///
  /// 프로바이더에서 **한 번 꺼내면 그쪽은 비워진다.** 그래서 화면이 들고 있는다.
  /// 이 화면을 나갔다 다시 들어오면 `NEW` 는 없다. 이미 알렸기 때문이다.
  Set<String> _celebrated = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndCelebrate());
  }

  Future<void> _loadAndCelebrate() async {
    if (!mounted) return;
    final provider = context.read<AchievementProvider>();

    // 기기에 적어 둔 축하거리가 있으면 먼저 되살린다. 로그인 직후 조회에서
    // 받았지만 아직 못 알린 것이 여기 남아 있다.
    await provider.restore();
    await provider.load();
    if (!mounted) return;

    // 조회가 실패해서 목록이 없으면 축하를 꺼내지 않는다. 꺼내면 프로바이더가
    // 비워져서, 이름도 그림도 못 보여 준 채 축하 기회만 날아간다.
    if (provider.isEmpty) return;

    final taken = provider.consumeCelebration();
    if (taken.isEmpty) return;

    setState(() => _celebrated = taken.toSet());
    AppToast.success(_celebrationMessage(provider, taken));
  }

  /// 알림 문구. 하나면 이름을 부르고, 여럿이면 개수를 센다.
  String _celebrationMessage(AchievementProvider provider, List<String> keys) {
    if (keys.length == 1) {
      for (final item in provider.achievements) {
        if (item.key != keys.first || item.nameKo.isEmpty) continue;
        return '${item.nameKo} 훈장을 받았어요!';
      }
    }
    return '새 훈장 ${keys.length}개를 받았어요!';
  }

  @override
  Widget build(BuildContext context) {
    final color = context.watch<ThemeHandler>().primaryColor;
    final provider = context.watch<AchievementProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: StandardText(text: '훈장', fontSize: 18, color: color),
      ),
      body: SafeArea(
        child: provider.isEmpty
            ? _buildEmpty(provider, color)
            : _buildList(provider, color),
      ),
    );
  }

  Widget _buildList(AchievementProvider provider, Color color) {
    final items = provider.achievements;

    return RefreshIndicator(
      color: color,
      onRefresh: () => provider.load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        // 목록이 짧아도 당겨서 새로 고칠 수 있어야 한다.
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return AppearTransition(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _AchievementSummary(
                  earned: provider.earnedCount,
                  total: provider.total,
                  color: color,
                ),
              ),
            );
          }

          final item = items[index - 1];
          return AppearTransition(
            // 열두 줄이 한꺼번에 뜨면 화면이 한 번 번쩍인다. 앞의 몇 줄만
            // 차례로 올라오고 나머지는 같이 온다. 스크롤을 내렸을 때
            // 아직 안 나타난 줄이 남아 있으면 그게 더 이상하다.
            delay: AppMotion.stagger * (index < 5 ? index : 5),
            child: AchievementCard(
              achievement: item,
              isNew: _celebrated.contains(item.key),
              color: color,
            ),
          );
        },
      ),
    );
  }

  /// 아직 한 줄도 못 받았을 때. 조회 중인지 실패한 것인지로 말이 갈린다.
  ///
  /// 실패해도 오류로 몰아붙이지 않는다. 이 API 가 아직 배포되기 전에도 이
  /// 화면은 열리고, 그때 사용자가 볼 것은 "앱이 고장 났다"가 아니라 "지금은
  /// 못 가져왔다"여야 한다.
  Widget _buildEmpty(AchievementProvider provider, Color color) {
    final loading = provider.state == AchievementLoadState.loading;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              CircularProgressIndicator(color: color)
            else
              const Icon(
                Icons.workspace_premium_rounded,
                size: 44,
                color: AppColors.textDisabled,
              ),
            const SizedBox(height: AppSpacing.lg),
            StandardText(
              text: loading ? '훈장을 불러오는 중이에요' : '훈장을 불러오지 못했어요.',
              fontSize: 14,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
            if (!loading) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _loadAndCelebrate,
                child: StandardText(
                  text: '다시 시도',
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 목록 맨 위, 몇 개 중 몇 개를 모았는지.
///
/// 옷장의 수집률 줄과 같은 역할이다. 잠긴 줄만 흑백으로 늘어놓으면 "못 받은
/// 것들"로 읽히는데, **열둘 중 셋**이라는 숫자가 앞에 있으면 같은 목록이
/// 모으는 중인 수집품이 된다.
class _AchievementSummary extends StatelessWidget {
  final int earned;
  final int total;
  final Color color;

  const _AchievementSummary({
    required this.earned,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? earned / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.07), Colors.white),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 글자를 키운 기기에서 숫자가 남은 폭을 넘는다. 넘치게 두는 대신
          // 줄여서 앉힌다. 옷장의 수집률 줄과 같은 처리다.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const StandardText(
                  text: '모은 훈장',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  maxLines: 1,
                ),
                const SizedBox(width: 6),
                AnimatedCountText(value: earned, fontSize: 18, color: color),
                StandardText(
                  text: ' / $total',
                  fontSize: 13,
                  color: AppColors.textTertiary,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          AnimatedLinearGauge(
            value: ratio,
            color: color,
            backgroundColor: color.withValues(alpha: 0.16),
            height: 5,
            borderRadius: 3,
          ),
        ],
      ),
    );
  }
}

/// 훈장 화면으로 가는 버튼이 쓰는 그림.
///
/// 훈장 열두 장이 같은 금색 월계관 방패 틀을 쓰고 있어서, 어느 한 장을 작게
/// 놓아도 "훈장"으로 읽힌다. 그중 **첫 걸음**을 고른 것은 오답노트를 하나라도
/// 적으면 누구나 받는 첫 훈장이라, 아직 아무것도 못 받은 사람의 버튼에 놓여도
/// 자기 것이 아닌 그림으로 보이지 않기 때문이다.
///
/// 버튼용 그림을 따로 그리지 않은 이유는 목록의 훈장 그림과 같은
/// 손으로 빚은 점토 렌더여서다. 미션·꾸미기 버튼도 같은 재질의 그림 한 장씩을
/// 쓰고 있어서, 여기만 머티리얼 아이콘을 놓으면 셋이 서로 다른 세계에서 온
/// 물건으로 보인다.
const String kAchievementEntryIcon = 'assets/Medal/first_step.png';
