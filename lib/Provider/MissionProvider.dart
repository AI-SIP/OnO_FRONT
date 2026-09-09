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
  bool _isLoading = false;

  /// 지금 받기 요청이 나가 있는 미션들. 버튼을 잠그는 데 쓴다.
  final Set<int> _claimingProgressIds = <int>{};

  String? _lastClaimError;

  MissionBoardModel? get board => _board;
  bool get isLoading => _isLoading;

  /// 마지막 받기 실패 문구. 화면이 읽고 나면 [consumeClaimError] 로 비운다.
  String? get lastClaimError => _lastClaimError;

  /// 배너와 화면을 그릴지 정하는 조건. 조회 실패거나 미션이 없으면 숨긴다.
  bool get hasMissions => _board != null && !_board!.isEmpty;

  List<MissionModel> get dailyMissions => _board?.daily.missions ?? const [];

  List<MissionModel> get weeklyMissions => _board?.weekly.missions ?? const [];

  int get dailyCompletedCount => _board?.daily.completedCount ?? 0;

  int get dailyTotalCount => _board?.daily.missions.length ?? 0;

  /// 일일과 주간을 합쳐 지금 받을 수 있는 보상의 수.
  int get unclaimedCount => _board?.claimableCount ?? 0;

  bool isClaiming(int? progressId) =>
      progressId != null && _claimingProgressIds.contains(progressId);

  Future<void> fetchMissions() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final board = await _missionService.getMissions();
      // 조회에 실패하면(null) 들고 있던 것을 지우지 않는다. 잠깐 끊겼다고
      // 화면에 떠 있던 미션이 사라지는 편이 더 이상하다.
      if (board != null) {
        _board = board;
      }
    } catch (e, stackTrace) {
      debugPrint('MissionProvider fetchMissions error: $e');
      await AppErrorReporter.report(
        e,
        stackTrace,
        source: 'mission_fetch',
        severity: AppErrorSeverity.warning,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 보상을 받는다. 성공하면 그 미션만 받음으로 바꾸고 결과를 돌려준다.
  ///
  /// 같은 미션에 대해 요청이 나가 있는 동안에는 다시 부르지 않는다. 버튼을
  /// 두 번 눌러 보상이 두 번 나가는 것을 막는 자리다.
  Future<MissionClaimResultModel?> claim(int progressId) async {
    if (_claimingProgressIds.contains(progressId)) return null;

    _claimingProgressIds.add(progressId);
    _lastClaimError = null;
    notifyListeners();

    try {
      final result = await _missionService.claim(
        progressId,
        onFailure: (message) => _lastClaimError = message,
      );

      if (result != null) {
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

  /// 실패 문구를 한 번 꺼내 쓰고 비운다. 같은 문구가 두 번 뜨는 것을 막는다.
  String? consumeClaimError() {
    final message = _lastClaimError;
    _lastClaimError = null;
    return message;
  }

  void clear() {
    _board = null;
    _claimingProgressIds.clear();
    _lastClaimError = null;
    notifyListeners();
  }
}
