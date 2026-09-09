import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Mission/MissionClaimResultModel.dart';
import '../../Model/Mission/MissionModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Design/AppToast.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/MissionProvider.dart';
import '../../Provider/UserProvider.dart';
import 'MissionIcon.dart';
import 'MissionLevelUpDialog.dart';

/// 일일 미션과 주간 미션을 보여 주고 보상을 받는 화면이다.
///
/// 조회에 실패하면 오류를 띄우지 않는다. 미션이 없는 것처럼 조용한 안내만
/// 남긴다. 백엔드에 아직 이 API 가 없어 404 가 떨어지는 동안에도 앱이 평소대로
/// 돌아야 하기 때문이다.
class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<MissionProvider>(context, listen: false).fetchMissions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return Provider.of<MissionProvider>(context, listen: false).fetchMissions();
  }

  /// 보상을 받는다.
  ///
  /// 두 번 눌리는 것은 [MissionProvider.claim] 이 막는다. 여기서는 버튼을
  /// 잠그고, 결과에 따라 문구와 레벨업 알림을 띄우는 것까지 한다.
  Future<void> _claim(MissionModel mission) async {
    final progressId = mission.progressId;
    if (progressId == null) return;

    final missionProvider =
        Provider.of<MissionProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (missionProvider.isClaiming(progressId)) return;

    final result = await missionProvider.claim(progressId);
    if (!mounted) return;

    if (result == null) {
      await _handleClaimFailure(progressId, missionProvider);
      return;
    }

    AppToast.success(_rewardMessage(result));

    // 레벨 카드가 방금 받은 경험치를 반영하도록 사용자 정보를 다시 읽는다.
    // 여기서 실패해도 보상은 이미 받았다. 갱신이 안 됐다고 오류를 띄우지 않는다.
    try {
      await userProvider.fetchUserInfo(showErrorSnackBar: false);
    } catch (error) {
      debugPrint('[MissionScreen] 보상 뒤 사용자 정보 갱신 실패: $error');
    }
    if (!mounted) return;

    if (result.leveledUp) {
      await showMissionLevelUpDialog(context, level: result.totalStudyLevel);
    }
  }

  /// 받기가 뜻대로 되지 않았을 때 무엇을 알릴지 정한다.
  ///
  /// 실패라고 단정할 수 있을 때만 오류를 띄운다.
  ///
  /// - 이미 받음(7010 이 아닌 7012): 서버 기준으로는 받은 상태다. 실패가
  ///   아니므로 조용히 화면만 맞춘다
  /// - 서버가 거절: 이유를 그대로 알린다 (아직 완료하지 않음 등)
  /// - 결과를 모름(연결 끊김, 시간 초과, 5xx, 응답을 읽지 못함): 서버가 이미
  ///   XP 를 줬을 수 있다. 다시 조회해서 진실을 확인하고, 확인도 못 하면
  ///   중립적인 안내만 남긴다
  Future<void> _handleClaimFailure(
    int progressId,
    MissionProvider missionProvider,
  ) async {
    final failure = missionProvider.consumeClaimFailure();

    if (failure == null || failure.isAlreadyClaimed) {
      await missionProvider.fetchMissions();
      return;
    }

    if (!failure.isUnknown) {
      AppToast.error(failure.message);
      await missionProvider.fetchMissions();
      return;
    }

    final refreshed = await missionProvider.fetchMissions();
    if (!mounted) return;

    final mission = missionProvider.missionByProgressId(progressId);
    if (refreshed && mission != null && mission.claimed) {
      // 서버는 줬는데 답을 못 받았던 것이다. 받은 것으로 알린다.
      AppToast.success(_rewardText(mission.rewardType, mission.rewardValue));
      return;
    }
    if (refreshed) {
      // 조회는 됐는데 여전히 안 받은 상태다. 이번엔 정말 실패다.
      AppToast.error(failure.message);
      return;
    }
    AppToast.info(_claimUnknownMessage);
  }

  static const String _claimUnknownMessage =
      '보상을 받았는지 확인하지 못했어요. 잠시 후 다시 확인해 주세요.';

  String _rewardMessage(MissionClaimResultModel result) {
    return _rewardText(result.rewardType, result.rewardValue);
  }

  String _rewardText(MissionRewardType? rewardType, int rewardValue) {
    if (rewardType == MissionRewardType.xp) {
      return '+$rewardValue XP';
    }
    // 모르는 보상 종류가 와도 받은 것은 받은 것이다. 일반 문구로 알린다.
    return '보상을 받았어요';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final missionProvider = Provider.of<MissionProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: StandardText(
          text: '미션',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: themeProvider.primaryColor,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: themeProvider.primaryColor,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(child: StandardText(text: '일일', fontSize: 14)),
            Tab(child: StandardText(text: '주간', fontSize: 14)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMissionList(missionProvider.dailyMissions, themeProvider),
          _buildMissionList(missionProvider.weeklyMissions, themeProvider),
        ],
      ),
    );
  }

  Widget _buildMissionList(
    List<MissionModel> missions,
    ThemeHandler themeProvider,
  ) {
    return RefreshIndicator(
      color: themeProvider.primaryColor,
      onRefresh: _refresh,
      child: missions.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxxl,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              children: const [
                StandardText(
                  text: '아직 볼 수 있는 미션이 없어요.',
                  fontSize: 14,
                  color: AppColors.textTertiary,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              itemCount: missions.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => MissionTile(
                mission: missions[index],
                onClaim: () => _claim(missions[index]),
              ),
            ),
    );
  }
}

/// 미션 한 줄이다. 아이콘, 제목과 설명, 진행바, 보상, 오른쪽에 버튼이다.
class MissionTile extends StatelessWidget {
  final MissionModel mission;
  final VoidCallback onClaim;

  const MissionTile({
    super.key,
    required this.mission,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final missionProvider = Provider.of<MissionProvider>(context);
    final isClaiming = missionProvider.isClaiming(mission.progressId);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MissionIconBox(
            iconKey: mission.iconKey,
            color: themeProvider.primaryColor,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StandardText(
                  text: mission.title,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                StandardText(
                  text: mission.description,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: mission.progressRatio,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceMuted,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      themeProvider.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // 글자를 키운 기기에서 한 줄에 다 못 들어가면 아래로 흐른다.
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StandardText(
                      text: '${mission.current}/${mission.target}',
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                    StandardText(
                      text: _rewardLabel(mission),
                      fontSize: 11,
                      color: themeProvider.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          MissionClaimButton(
            mission: mission,
            isClaiming: isClaiming,
            onClaim: onClaim,
          ),
        ],
      ),
    );
  }

  static String _rewardLabel(MissionModel mission) {
    if (mission.rewardType == MissionRewardType.xp) {
      return '+${mission.rewardValue} XP';
    }
    return '보상 ${mission.rewardValue}';
  }
}

/// 상태 세 가지를 그리는 버튼이다.
///
/// - 진행 중: 비활성, `진행 중`
/// - 완료했고 안 받음: 활성, `받기`
/// - 받음: 비활성, `받음`
///
/// 누른 뒤 응답이 올 때까지는 [isClaiming] 이 true 라 눌리지 않는다. 보상이
/// 두 번 나가면 되돌릴 방법이 없어서 여기서 반드시 막아야 한다.
class MissionClaimButton extends StatelessWidget {
  final MissionModel mission;
  final bool isClaiming;
  final VoidCallback onClaim;

  const MissionClaimButton({
    super.key,
    required this.mission,
    required this.isClaiming,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final canClaim = mission.isClaimable && !isClaiming;

    return ElevatedButton(
      onPressed: canClaim ? onClaim : null,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: themeProvider.primaryColor,
        disabledBackgroundColor: AppColors.surfaceMuted,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
      child: isClaiming
          ? SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: themeProvider.primaryColor,
              ),
            )
          : StandardText(
              text: _label,
              fontSize: 12,
              color: canClaim ? Colors.white : AppColors.textDisabled,
            ),
    );
  }

  String get _label {
    if (mission.claimed) return '받음';
    if (mission.completed) return '받기';
    return '진행 중';
  }
}
