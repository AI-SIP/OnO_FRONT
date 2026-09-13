import 'dart:async';

import 'package:flutter/foundation.dart';

import '../Model/Achievement/AchievementBoardModel.dart';
import '../Model/Achievement/AchievementModel.dart';
import '../Model/User/UserInfoModel.dart';
import '../Service/Api/Achievement/AchievementService.dart';
import 'AchievementCelebrationStore.dart';

/// 훈장판을 아직 받았는지.
enum AchievementLoadState {
  /// 로그인 전이거나 아직 한 번도 안 물어봤다.
  idle,

  /// 물어보는 중이다.
  loading,

  /// 받았다.
  ready,

  /// 물어봤는데 못 받았다. 들고 있는 훈장판이 없다.
  failed,
}

/// 훈장을 들고 있는 프로바이더다.
///
/// 훈장 목록도 조건도 진행도도 **전부 서버가 정한다**([AchievementService]).
/// 앱에는 열두 개의 이름도 설명도 박혀 있지 않다. 문서
/// `docs/훈장/훈장표.md` 가 계약이고 서버 시드가 거기서 나온다.
///
/// **못 받아도 앱은 평소대로 떠야 한다.** 훈장은 가끔 보고 흐뭇한 것이지 앱
/// 진입을 막을 것이 아니다. 조회가 실패하면 훈장 화면이 그 사실을 말하고
/// 다시 시도를 주는 데서 끝난다.
///
/// ## 새로 받은 훈장을 놓치지 않는 법
///
/// 서버는 `newlyEarned` 를 **그 응답 한 번에만** 실어 준다. 다음 조회에서는
/// 그냥 `earned: true` 일 뿐이다. 그래서 이 프로바이더는 세 가지를 한다.
///
/// 1. **쌓는다.** 받은 key 를 [_pending] 에 합친다. 덮어쓰지 않는다. 로그인
///    직후 조회에서 둘을 받고 훈장 화면을 여는 조회에서 빈 배열을 받아도,
///    앞의 둘이 지워지면 안 된다.
/// 2. **적어 둔다.** 받은 그 자리에서 기기에 쓴다
///    ([AchievementCelebrationStore]). 알리기 전에 앱이 내려가도 살아남는다.
/// 3. **본 뒤에 지운다.** 화면이 실제로 알린 순간
///    ([consumeCelebration])에만 비운다.
///
/// 셋 중 하나라도 빠지면 "서른 날을 안 빼먹고 받은 훈장"이 조용히 사라진다.
class AchievementProvider with ChangeNotifier {
  final AchievementService _service;
  final AchievementCelebrationStore _store;

  AchievementProvider({
    AchievementService? service,
    AchievementCelebrationStore? store,
  })  : _service = service ?? AchievementService(),
        _store = store ?? const AchievementCelebrationStore();

  AchievementBoardModel? _board;
  AchievementLoadState _state = AchievementLoadState.idle;

  /// 아직 사용자에게 못 알린 훈장 key 들.
  Set<String> _pending = <String>{};

  /// 기기에 적어 둔 것을 이미 읽어 왔는지. 앱을 켜고 한 번만 읽는다.
  bool _restored = false;

  /// 나가 있는 조회. 로그인 직후와 훈장 화면 진입이 겹칠 수 있다.
  Future<bool>? _inFlightLoad;

  AchievementLoadState get state => _state;

  /// 서버가 준 순서 그대로다. **정렬하지 않는다.**
  List<AchievementModel> get achievements => _board?.achievements ?? const [];

  int get total => _board?.total ?? 0;

  int get earnedCount => _board?.earnedCount ?? 0;

  /// 한 번도 못 받아서 보여 줄 것이 없는지.
  bool get isEmpty => achievements.isEmpty;

  /// 아직 못 알린 새 훈장이 있는지. 옷장 탭의 훈장 버튼이 이걸 보고 표시를 단다.
  bool get hasNews => _pending.isNotEmpty;

  /// 아직 못 알린 key 들. 읽기 전용이다.
  Set<String> get pendingCelebration => Set<String>.unmodifiable(_pending);

  /// 기기에 적어 둔 축하거리를 불러온다. 앱을 켜고 한 번만 읽는다.
  ///
  /// 조회보다 먼저 끝나야 훈장 버튼에 표시가 붙는다. 실패해도 조용히 넘어간다.
  Future<void> restore() async {
    if (_restored) return;
    _restored = true;

    final stored = await _store.read();
    if (stored.isEmpty) return;

    _pending = {..._pending, ...stored};
    notifyListeners();
  }

  /// 유저 정보를 받았을 때 훈장판을 한 번 채운다.
  ///
  /// **처음 한 번만 부른다.** 유저 정보는 문제를 하나 풀 때마다도 다시 읽히는데,
  /// 훈장 조회는 서버가 열두 가지 조건을 다시 세는 무거운 일이라 그때마다
  /// 부르면 요청만 는다. 그 대신 훈장 화면에 들어올 때마다 다시 읽는다. 방금
  /// 채운 조건은 그 자리에서 드러난다.
  ///
  /// 그럼에도 로그인 직후에 한 번 부르는 이유는 **버튼에 표시를 붙이기
  /// 위해서**다. 이것이 없으면 새 훈장이 생겨도 사용자가 스스로 훈장 화면을
  /// 열기 전까지 아무 기척이 없다.
  ///
  /// 정보가 null 이면 아무것도 하지 않는다. 유저 정보 조회가 잠깐 실패해도
  /// null 이 오는데, 그걸 로그아웃으로 보면 안 된다. 비우는 것은 로그아웃이
  /// [clear] 로 직접 시킨다.
  Future<void> syncWithUser(UserInfoModel? info) async {
    if (info == null) return;

    await restore();
    if (_board == null) await load();
  }

  /// 훈장판을 서버에서 받는다. 받았으면 true 다.
  ///
  /// 이미 나가 있는 조회가 있으면 그것을 함께 기다린다.
  Future<bool> load() {
    final inFlight = _inFlightLoad;
    if (inFlight != null) return inFlight;

    final fetch = _runLoad();
    _inFlightLoad = fetch;
    _state = AchievementLoadState.loading;
    notifyListeners();

    return fetch.whenComplete(() {
      _inFlightLoad = null;
      notifyListeners();
    });
  }

  Future<bool> _runLoad() async {
    final received = await _service.getAchievements();

    if (received == null) {
      // 조회에 실패하면 들고 있던 것을 지우지 않는다. 잠깐 끊겼다고 받은
      // 훈장이 사라지는 편이 더 이상하다. 한 번도 못 받았을 때만 실패로 남는다.
      _state = _board == null
          ? AchievementLoadState.failed
          : AchievementLoadState.ready;
      return false;
    }

    _board = received;
    _state = AchievementLoadState.ready;

    await _rememberNewlyEarned(received.newlyEarned);
    return true;
  }

  /// 새로 받은 것을 쌓고 기기에 적는다.
  ///
  /// 이 응답에 없다고 앞서 쌓아 둔 것을 지우지 않는다. 지우는 것은 사용자가
  /// 실제로 본 [consumeCelebration] 뿐이다.
  Future<void> _rememberNewlyEarned(List<String> keys) async {
    if (keys.isEmpty) return;

    final next = {..._pending, ...keys};
    if (next.length == _pending.length) return;

    _pending = next;
    // 알리기 전에 앱이 내려가도 남아 있어야 한다.
    await _store.write(_pending);
  }

  /// 축하거리를 한 번 꺼내 쓰고 비운다. **화면이 실제로 알린 뒤에 부른다.**
  ///
  /// 꺼내기 전에 비우면, 알림을 띄우다 실패했을 때 다시 알릴 방법이 없다.
  /// 그래서 화면이 띄우기로 결정한 그 순간에 부른다.
  List<String> consumeCelebration() {
    if (_pending.isEmpty) return const [];

    final taken = _pending.toList();
    _pending = <String>{};
    // 기다리지 않는다. 지우기가 늦어져 다음 실행에서 한 번 더 축하하는 것은
    // 아쉬운 정도지만, 알림을 지우기 전까지 붙잡아 두면 화면이 멈춘다.
    unawaited(_store.write(const <String>{}));
    notifyListeners();
    return taken;
  }

  /// 들고 있는 것을 전부 비운다. 로그아웃 때 부른다.
  ///
  /// 기기에 적어 둔 축하거리까지 지운다. 같은 기기에서 다른 계정으로 로그인한
  /// 첫 화면에 앞 사람이 받은 훈장의 축하가 뜨면 안 된다.
  void clear() {
    _board = null;
    _state = AchievementLoadState.idle;
    _pending = <String>{};
    _restored = false;
    unawaited(_store.write(const <String>{}));
    notifyListeners();
  }
}
