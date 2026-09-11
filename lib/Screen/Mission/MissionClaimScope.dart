import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Mission/MissionClaimResultModel.dart';
import '../../Model/Mission/MissionModel.dart';
import '../../Module/Design/AppToast.dart';
import '../../Provider/MissionProvider.dart';
import '../../Provider/UserProvider.dart';
import 'MissionLevelUp.dart';
import 'MissionRewardCelebration.dart';
import 'MissionRewardFlight.dart';

/// 보상을 받는 절차를 쓰는 쪽에 건네주는 손잡이다.
///
/// 미션 카드를 그리는 화면은 이것만 있으면 된다. 어디로 코인이 날아가고
/// 레벨업 화면이 언제 뜨는지는 [MissionClaimScope] 가 안에서 정한다.
class MissionClaimHandle {
  /// 지금 날아가는 중인 XP. 코인이 닿을 때까지 합계에서 빼 둔다.
  final int pendingXp;

  /// 코인이 카운터에 닿은 횟수. 카운터가 한 번 튀는 신호다.
  final int arrivalTick;

  /// 보상을 받는다. 미션 카드의 받기 버튼에 그대로 물린다.
  final Future<void> Function(MissionModel mission) claim;

  /// 코인이 출발할 자리. 미션마다 하나씩 준다.
  final GlobalKey Function(MissionModel mission) rewardKeyOf;

  /// 받기가 실패한 횟수. 이 값이 바뀌면 카드가 한 번 흔들린다.
  final int Function(MissionModel mission) shakeTickOf;

  const MissionClaimHandle({
    required this.pendingXp,
    required this.arrivalTick,
    required this.claim,
    required this.rewardKeyOf,
    required this.shakeTickOf,
  });
}

/// 미션 보상을 받는 절차 전체를 들고 있는 자리다.
///
/// 받기 한 번에 붙는 일이 많다. 상자가 열리고, 코인이 카운터로 날아가고,
/// 숫자가 롤업되고, 레벨업이면 그 화면이 뒤이어 뜨고, 실패하면 카드가
/// 흔들린다. 실패했는지조차 모르는 경우(연결 끊김, 5xx)에는 다시 조회해서
/// 진실을 확인한다.
///
/// 이 절차가 미션 화면 안에만 있으면 다른 화면에서 미션 카드를 쓸 수 없다.
/// 그래서 **화면이 아니라 이 위젯**이 들고 있다. 미션 화면과 캐릭터 탭이
/// 같은 코드를 쓴다.
///
/// ```dart
/// MissionClaimScope(
///   counterKey: _counterKey,
///   builder: (context, claim) => MissionCard(
///     mission: mission,
///     onClaim: () => claim.claim(mission),
///     rewardKey: claim.rewardKeyOf(mission),
///     shakeTick: claim.shakeTickOf(mission),
///     isClaiming: provider.isClaiming(mission.progressId),
///   ),
/// )
/// ```
class MissionClaimScope extends StatefulWidget {
  /// 코인이 날아가 닿을 자리. 쓰는 화면의 XP 카운터에 달린다.
  final GlobalKey counterKey;

  /// 받은 XP 를 오늘 합계에 넣을지 판단한다.
  ///
  /// 미션 화면의 카운터는 **오늘 받은 XP** 라서 주간이나 지난 미션을 받으면
  /// 코인만 날아오고 숫자는 그대로다. 누적 경험치를 세는 카운터라면 전부
  /// 더해야 하므로 쓰는 쪽이 정한다. null 이면 전부 더한다.
  final bool Function(MissionClaimResultModel result)? countsToward;

  final Widget Function(BuildContext context, MissionClaimHandle claim) builder;

  const MissionClaimScope({
    super.key,
    required this.counterKey,
    required this.builder,
    this.countsToward,
  });

  @override
  State<MissionClaimScope> createState() => _MissionClaimScopeState();
}

class _MissionClaimScopeState extends State<MissionClaimScope> {
  /// 지금 날아가는 중인 XP. 코인이 닿을 때까지 합계에서 빼 둔다.
  int _pendingXp = 0;

  /// 코인이 카운터에 닿은 횟수. 칩이 튀는 신호로 쓴다.
  int _arrivalTick = 0;

  /// 받기가 실패한 미션과 그 횟수. 카드를 흔드는 신호로 쓴다.
  final Map<int, int> _shakeTicks = {};

  /// 보상 연출을 하나씩 처리하는 줄. 연달아 받아도 겹쳐 뜨지 않는다.
  Future<void> _celebrationQueue = Future<void>.value();

  /// 코인이 출발하는 자리(각 카드의 보상 칩). 미션마다 하나씩 만든다.
  final Map<int, GlobalKey> _rewardKeys = {};

  GlobalKey _rewardKeyFor(MissionModel mission) {
    final progressId = mission.progressId;
    if (progressId == null) return GlobalKey();
    return _rewardKeys.putIfAbsent(progressId, GlobalKey.new);
  }

  int _shakeTickFor(MissionModel mission) =>
      _shakeTicks[mission.progressId] ?? 0;

  /// 보상을 받는다.
  ///
  /// 두 번 눌리는 것은 [MissionProvider.claim] 이 막는다. 여기서는 받은 뒤의
  /// 순서를 만든다. **성공은 알림으로 알리지 않는다.**
  ///
  /// 1. 누르는 즉시 버튼이 눌리고 진동이 온다 (카드 쪽에서 한다)
  /// 2. 보상 카드가 화면 가운데로 튀어오른다 — 레벨업이 있든 없든 항상
  /// 3. 카드가 닫히며 코인이 상단 카운터로 날아간다
  /// 4. 닿으면 칩이 튀고 숫자가 롤업된다
  /// 5. 미션 카드는 받음으로 가라앉고 목록 아래로 내려간다
  Future<void> claim(MissionModel mission) async {
    final progressId = mission.progressId;
    if (progressId == null) return;

    final missionProvider =
        Provider.of<MissionProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (missionProvider.isClaiming(progressId)) return;

    // 받기 전에 열려 있던 테마를 찍어 둔다. 서버가 해금 정보를 내려주지 않아서
    // 받은 뒤와 비교해 이번에 열린 것을 알아낸다.
    final unlockedBefore = unlockedThemeIndexes(userProvider.userInfoModel);
    // 레벨업 전의 종합 레벨. 이 사이에 열린 치장을 찾아 개구리에 입히는 데 쓴다.
    final levelBefore = userProvider.userInfoModel?.totalStudyLevel;

    final result = await missionProvider.claim(progressId);
    if (!mounted) return;

    if (result == null) {
      await _handleClaimFailure(progressId, missionProvider);
      return;
    }

    final counts = widget.countsToward?.call(result) ?? true;

    await _enqueueCelebration(() async {
      await _celebrateReward(
        mission: mission,
        result: result,
        countsToday: counts,
      );
      if (!mounted) return;

      // 레벨 카드가 방금 받은 경험치를 반영하도록 사용자 정보를 다시 읽는다.
      // 여기서 실패해도 보상은 이미 받았다. 갱신이 안 됐다고 오류를 띄우지 않는다.
      try {
        await userProvider.fetchUserInfo(showErrorSnackBar: false);
      } catch (error) {
        debugPrint('[MissionClaimScope] 보상 뒤 사용자 정보 갱신 실패: $error');
      }
      if (!mounted) return;

      if (result.leveledUp) {
        await showMissionLevelUp(
          context,
          level: result.totalStudyLevel,
          previousLevel: levelBefore,
          unlockedThemeIndexes: newlyUnlockedThemeIndexes(
            unlockedBefore,
            unlockedThemeIndexes(userProvider.userInfoModel),
          ),
        );
      }
    });
  }

  /// 보상 연출을 줄 세워 하나씩 돌린다.
  Future<void> _enqueueCelebration(Future<void> Function() body) {
    final next = _celebrationQueue.then((_) async {
      if (!mounted) return;
      await body();
    });
    // 하나가 실패해도 줄이 막히지 않게 한다.
    _celebrationQueue = next.catchError((Object error) {
      debugPrint('[MissionClaimScope] 보상 연출 실패: $error');
    });
    return next;
  }

  /// 보상 카드를 띄우고, 닫히면 코인을 카운터로 날린다.
  Future<void> _celebrateReward({
    required MissionModel mission,
    required MissionClaimResultModel result,
    required bool countsToday,
  }) async {
    final pending = countsToday ? result.rewardValue : 0;
    if (pending > 0) {
      setState(() => _pendingXp += pending);
    }

    final coinOrigin = await showMissionRewardCelebration(
      context,
      missionTitle: mission.title,
      rewardType: result.rewardType,
      amount: result.rewardValue,
      // 뒤에 레벨업 화면이 붙는 경우다. 상자가 열린 뒤 머무는 시간을 줄여
      // 두 연출이 이어 붙어 늘어지지 않게 한다.
      levelUpFollows: result.leveledUp,
    );
    if (!mounted) return;

    final flying = coinOrigin != null &&
        MissionRewardFlight.launchFrom(
          context: context,
          start: coinOrigin,
          to: widget.counterKey,
          onArrived: () => _onCoinArrived(pending),
        );

    // 날리지 못했으면(연출을 끈 기기, 카운터가 화면에 없음) 숫자는 바로 오른다.
    if (!flying) _onCoinArrived(pending);
  }

  void _onCoinArrived(int pending) {
    if (!mounted) return;
    setState(() {
      _pendingXp = (_pendingXp - pending).clamp(0, 1 << 30);
      _arrivalTick++;
    });
  }

  void _shakeCard(int progressId) {
    if (!mounted) return;
    setState(() {
      _shakeTicks[progressId] = (_shakeTicks[progressId] ?? 0) + 1;
    });
  }

  /// 받기가 뜻대로 되지 않았을 때 무엇을 알릴지 정한다.
  ///
  /// 실패라고 단정할 수 있을 때만 오류를 띄운다.
  ///
  /// - 이미 받음(7012): 서버 기준으로는 받은 상태다. 실패가 아니므로 조용히
  ///   화면만 맞춘다
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
      // 실패했으니 코인을 날리지 않는다. 카드가 짧게 흔들려 안 됐다고 알린다.
      _shakeCard(progressId);
      AppToast.error(failure.message);
      await missionProvider.fetchMissions();
      return;
    }

    final refreshed = await missionProvider.fetchMissions();
    if (!mounted) return;

    final mission = missionProvider.missionByProgressId(progressId);
    if (refreshed && mission != null && mission.claimed) {
      // 서버는 줬는데 답을 못 받았던 것이다. 카드가 이미 받음으로 바뀌었으니
      // 코인만 날려 준다.
      final rewardKey = _rewardKeys[progressId];
      if (rewardKey != null) {
        MissionRewardFlight.launch(
          context: context,
          from: rewardKey,
          to: widget.counterKey,
          onArrived: () => _onCoinArrived(0),
        );
      }
      return;
    }
    if (refreshed) {
      // 조회는 됐는데 여전히 안 받은 상태다. 이번엔 정말 실패다.
      _shakeCard(progressId);
      AppToast.error(failure.message);
      return;
    }
    _shakeCard(progressId);
    AppToast.info(_claimUnknownMessage);
  }

  static const String _claimUnknownMessage = '보상을 받았는지 확인하지 못했어요';

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      MissionClaimHandle(
        pendingXp: _pendingXp,
        arrivalTick: _arrivalTick,
        claim: claim,
        rewardKeyOf: _rewardKeyFor,
        shakeTickOf: _shakeTickFor,
      ),
    );
  }
}
