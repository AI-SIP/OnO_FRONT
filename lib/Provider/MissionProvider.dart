import 'package:flutter/material.dart';
import 'package:ono/Model/Mission/MissionClaimResultModel.dart';
import 'package:ono/Model/Mission/MissionGroupModel.dart';
import 'package:ono/Model/Mission/MissionModel.dart';
import 'package:ono/Service/Api/Mission/MissionService.dart';
import 'package:ono/Util/AppErrorReporter.dart';

/// 미션 조회와 보상 받기를 들고 있는 프로바이더다.
///
/// 조회가 실패하면 [board] 가 null 로 남는다. 배너와 미션 화면은 그때 통째로
/// 숨는다. 백엔드에 아직 미션 API 가 없어도 앱이 평소대로 떠야 하기 때문에,
/// 실패를 오류로 알리지 않고 없는 것처럼 다룬다.
class MissionProvider with ChangeNotifier {
  final MissionService _missionService;

  MissionProvider({MissionService? missionService})
      : _missionService = missionService ?? MissionService();

  MissionBoardModel? _board;

  /// 지금 나가 있는 조회. 요청이 겹치지 않게 하는 데 쓴다.
  Future<bool>? _inFlightFetch;

  /// 진행 중인 조회가 끝난 뒤 한 번 더 돌 조회.
  Future<bool>? _queuedFetch;

  /// 지금 받기 요청이 나가 있는 미션들. 버튼을 잠그는 데 쓴다.
  final Set<int> _claimingProgressIds = <int>{};

  /// 이 기기에서 받기에 성공한 것으로 아는 미션들.
  ///
  /// 받기 응답과 조회 응답이 경합하면 조회가 커밋 전 상태를 읽어 올 수 있다.
  /// 그대로 덮어쓰면 방금 받은 미션의 버튼이 `받기` 로 되돌아가고, 다시 누르면
  /// 이미 받았다는 오류가 난다. 그래서 서버가 따라올 때까지 이쪽을 우선한다.
  final Set<int> _locallyClaimedIds = <int>{};

  MissionClaimFailure? _lastClaimFailure;

  MissionBoardModel? get board => _board;

  bool get isLoading => _inFlightFetch != null;

  /// 마지막 받기 실패. 화면이 읽고 나면 [consumeClaimFailure] 로 비운다.
  MissionClaimFailure? get lastClaimFailure => _lastClaimFailure;

  /// 배너와 화면을 그릴지 정하는 조건. 조회 실패거나 미션이 없으면 숨긴다.
  bool get hasMissions => _board != null && !_board!.isEmpty;

  List<MissionModel> get dailyMissions => _board?.daily.missions ?? const [];

  List<MissionModel> get weeklyMissions => _board?.weekly.missions ?? const [];

  /// 지난 기간에 완료했지만 아직 안 받은 미션들.
  List<MissionModel> get expiredMissions =>
      _board?.expired.missions ?? const [];

  int get dailyCompletedCount => _board?.daily.completedCount ?? 0;

  int get dailyTotalCount => _board?.daily.missions.length ?? 0;

  /// 일일과 주간을 합쳐 지금 받을 수 있는 보상의 수.
  int get unclaimedCount => _board?.claimableCount ?? 0;

  /// 일일 미션 중에서 지금 받을 수 있는 보상의 수.
  int get dailyUnclaimedCount => _board?.daily.claimableCount ?? 0;

  /// 지난 미션 중에서 지금 받을 수 있는 보상의 수.
  int get expiredUnclaimedCount => _board?.expired.claimableCount ?? 0;

  /// 홈 배너의 `받기 N` 배지가 세는 수.
  ///
  /// 진행도(`n/m`)는 오늘 것만 세지만 배지는 지난 미션까지 센다. 기간을 넘긴
  /// 보상은 배지에 안 잡히면 사용자가 있는 줄도 모르고 지나간다. 주간은
  /// 오늘의 진행도와 무관하므로 여기서 세지 않는다.
  int get bannerUnclaimedCount => dailyUnclaimedCount + expiredUnclaimedCount;

  bool isClaiming(int? progressId) =>
      progressId != null && _claimingProgressIds.contains(progressId);

  /// 일일과 주간을 통틀어 이 진행도의 미션을 찾는다. 없으면 null 이다.
  MissionModel? missionByProgressId(int progressId) {
    for (final mission in [
      ...dailyMissions,
      ...weeklyMissions,
      ...expiredMissions,
    ]) {
      if (mission.progressId == progressId) return mission;
    }
    return null;
  }

  /// 미션을 다시 읽는다. 서버가 답했으면 true 다.
  ///
  /// 이미 조회가 나가 있으면 요청을 겹치지 않게 하되, **호출을 버리지는
  /// 않는다.** 진행 중인 것이 끝난 뒤 한 번 더 돈다. 받기 뒤의 복구 조회처럼
  /// "지금 이 순간의 서버 상태"가 필요한 호출이 조용히 사라지면, 이미 받은
  /// 미션에 `받기` 버튼이 남는다.
  Future<bool> fetchMissions() {
    final inFlight = _inFlightFetch;
    if (inFlight == null) return _startFetch();

    // 뒤이어 도는 조회는 한 번이면 된다. 기다리는 호출자들이 나눠 쓴다.
    return _queuedFetch ??= inFlight.then((_) {
      _queuedFetch = null;
      return _startFetch();
    });
  }

  Future<bool> _startFetch() {
    final fetch = _runFetch();
    _inFlightFetch = fetch;
    notifyListeners();
    return fetch.whenComplete(() {
      _inFlightFetch = null;
      notifyListeners();
    });
  }

  Future<bool> _runFetch() async {
    try {
      final board = await _missionService.getMissions();
      // 조회에 실패하면(null) 들고 있던 것을 지우지 않는다. 잠깐 끊겼다고
      // 화면에 떠 있던 미션이 사라지는 편이 더 이상하다.
      if (board == null) return false;

      _board = _mergeLocalClaims(board);
      return true;
    } catch (e, stackTrace) {
      debugPrint('MissionProvider fetchMissions error: $e');
      await AppErrorReporter.report(
        e,
        stackTrace,
        source: 'mission_fetch',
        severity: AppErrorSeverity.warning,
      );
      return false;
    }
  }

  /// 서버가 아직 모르는 "이미 받음"을 새로 읽은 보드에 얹는다.
  ///
  /// 서버가 따라잡았으면(그 미션을 받음으로 내려주면) 기억할 이유가 없으니
  /// 지운다. 기간이 넘어가 그 미션이 사라져도 마찬가지다.
  MissionBoardModel _mergeLocalClaims(MissionBoardModel board) {
    if (_locallyClaimedIds.isEmpty) return board;

    var merged = board;
    for (final progressId in _locallyClaimedIds.toList()) {
      final mission = _findIn(board, progressId);
      if (mission == null || mission.claimed) {
        _locallyClaimedIds.remove(progressId);
        continue;
      }
      merged = merged.markClaimed(progressId);
    }
    return merged;
  }

  static MissionModel? _findIn(MissionBoardModel board, int progressId) {
    for (final mission in [
      ...board.daily.missions,
      ...board.weekly.missions,
      ...board.expired.missions,
    ]) {
      if (mission.progressId == progressId) return mission;
    }
    return null;
  }

  /// 보상을 받는다. 성공하면 그 미션만 받음으로 바꾸고 결과를 돌려준다.
  ///
  /// 같은 미션에 대해 요청이 나가 있는 동안에는 다시 부르지 않는다. 버튼을
  /// 두 번 눌러 보상이 두 번 나가는 것을 막는 자리다.
  Future<MissionClaimResultModel?> claim(int progressId) async {
    if (_claimingProgressIds.contains(progressId)) return null;

    _claimingProgressIds.add(progressId);
    _lastClaimFailure = null;
    notifyListeners();

    try {
      final result = await _missionService.claim(
        progressId,
        onFailure: (failure) => _lastClaimFailure = failure,
      );

      if (result != null) {
        _locallyClaimedIds.add(result.progressId);
        _board = _board?.markClaimed(result.progressId);
      }
      return result;
    } catch (e, stackTrace) {
      debugPrint('MissionProvider claim error: $e');
      await AppErrorReporter.report(
        e,
        stackTrace,
        source: 'mission_claim',
        severity: AppErrorSeverity.warning,
      );
      return null;
    } finally {
      _claimingProgressIds.remove(progressId);
      notifyListeners();
    }
  }

  /// 실패를 한 번 꺼내 쓰고 비운다. 같은 문구가 두 번 뜨는 것을 막는다.
  MissionClaimFailure? consumeClaimFailure() {
    final failure = _lastClaimFailure;
    _lastClaimFailure = null;
    return failure;
  }

  /// 들고 있는 것을 전부 버린다.
  ///
  /// 로그아웃 때 부른다. 비우지 않으면 같은 기기에서 다른 계정으로 로그인한
  /// 첫 화면에 앞 사람의 진행도와 `받기` 배지가 그대로 뜬다.
  void clear() {
    _board = null;
    _claimingProgressIds.clear();
    _locallyClaimedIds.clear();
    _lastClaimFailure = null;
    notifyListeners();
  }
}
