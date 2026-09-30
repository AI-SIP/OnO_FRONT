import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Model/Common/LoginStatus.dart';
import '../../Model/Problem/ReviewDueProblemModel.dart';
import '../../Model/StudyCalendar/StudyCalendarModel.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/CosmeticProvider.dart';
import '../../Provider/UserProvider.dart';
import '../../Util/AppClock.dart';
import '../../Util/AppNavigator.dart';
import '../Api/Problem/ProblemService.dart';
import '../Api/StudyCalendar/StudyCalendarService.dart';
import 'HomeWidgetProfileRenderer.dart';
import 'HomeWidgetSnapshot.dart';
import 'HomeWidgetSnapshotBuilder.dart';

/// 홈 화면 위젯에 넘길 값을 서버에서 받아 공유 저장소에 쓰고 위젯을 다시
/// 그리게 한다.
///
/// 위젯은 서버도 토큰도 모르고 앱이 써 둔 스냅샷 하나만 읽는다. 화면이 구독할
/// 상태가 아니라 한 번 쓰고 끝나는 값이라 Provider 가 아니라 싱글턴으로 둔다.
///
/// **여기서 난 실패는 사용자 흐름으로 새어 나가면 안 된다.** 모든 요청은
/// 스낵바 없이 보내고, 모든 공개 메서드는 예외를 던지지 않는다. 실패하면 이전
/// 스냅샷을 그대로 둔다.
///
/// 홈 화면에 위젯을 둔 사람만 서버를 부른다. 위젯이 없는 사용자가 앱을 열 때마다
/// 달력과 복습 예정을 한 번씩 더 부르지 않게 한다.
class HomeWidgetSyncService {
  HomeWidgetSyncService._(this._deps);

  static final HomeWidgetSyncService instance =
      HomeWidgetSyncService._(HomeWidgetSyncDeps.app());

  /// 가짜 의존성으로 만든다. 테스트 전용이다.
  @visibleForTesting
  factory HomeWidgetSyncService.forTest(HomeWidgetSyncDeps deps) =>
      HomeWidgetSyncService._(deps);

  /// iOS App Group. 앱과 위젯 확장이 같은 저장소를 보게 한다.
  static const String appGroupId = 'group.com.aisip.OnO';

  /// iOS 위젯 kind.
  static const String iOSWidgetKind = 'OnOStudyWidget';

  /// Android 위젯 Provider. 크기마다 하나씩이라 셋 다 갱신한다.
  static const List<String> androidProviders = [
    'com.ono.app.widget.OnOSmallWidgetProvider',
    'com.ono.app.widget.OnOMediumWidgetProvider',
    'com.ono.app.widget.OnOLargeWidgetProvider',
  ];

  /// 이 간격 안의 `force` 아닌 동기화는 건너뛴다. 포그라운드 복귀가 짧게 여러
  /// 번 일어나도 API 가 몰리지 않게 한다. 실패한 시도도 여기에 든다.
  static const Duration minInterval = Duration(seconds: 60);

  /// `force` 호출을 모으는 시간. 복습 세트는 문제마다 `force` 로 부르기 때문에
  /// 마지막 호출 뒤 이만큼 조용하면 그때 한 번만 돈다.
  static const Duration forceDebounce = Duration(seconds: 3);

  final HomeWidgetSyncDeps _deps;

  Future<void>? _running;

  /// [_running] 을 시작한 세대. 앞 계정의 동기화에 새 계정의 요청을 합치지
  /// 않으려고 본다.
  int _runningGeneration = 0;

  /// 마지막으로 서버를 부르려 한 시각. 성공과 실패를 가리지 않는다.
  DateTime? _lastAttemptAt;

  Timer? _forceTimer;
  Completer<void>? _forceCompleter;

  /// 지난 달 달력. 날짜가 바뀌기 전까지는 변하지 않아서 그날 안에서는 다시
  /// 받지 않는다. `yyyy-M` → 응답. 기기에도 저장해 앱을 새로 띄워도 쓴다.
  final Map<String, StudyCalendarModel> _pastMonths = {};
  DateTime? _pastMonthsDay;
  bool _pastMonthsLoaded = false;

  /// 이번 동기화에서 지난 달을 새로 받아 기기에 다시 써야 하는지.
  bool _pastMonthsDirty = false;

  /// 로그아웃할 때마다 올린다. 로그아웃 전에 시작한 동기화가 늦게 끝나서
  /// 로그아웃 스냅샷을 덮어쓰지 않게 한다.
  int _generation = 0;

  /// 마지막으로 쓴 로그인 스냅샷. 테마 색이나 프로필 버전만 고칠 때 쓴다.
  Map<String, dynamic>? _lastSnapshot;

  /// 스냅샷 쓰기를 한 줄로 세운다. 동기화와 테마 변경이 겹쳐도 한쪽이 다른
  /// 쪽 값을 덮지 않게 한다.
  Future<void> _writeQueue = Future<void>.value();

  Future<void>? _profileRunning;
  bool _profileRerun = false;
  int? _profileVersion;

  /// 달력과 복습 예정을 받아 스냅샷을 쓰고 위젯을 다시 그린다.
  ///
  /// - [force] 가 아니면 마지막 시도(성공, 실패 모두) 뒤 [minInterval] 안의
  ///   호출은 건너뛴다. 지금 세대에서 돌고 있는 것이 있으면 그 Future 를 준다.
  /// - [force] 면 [forceDebounce] 동안 모았다가 마지막 호출 뒤 한 번만 돈다.
  ///   이미 돌고 있으면 그것이 끝난 뒤 돈다. 등록 직후 값이 빠지지 않게 한다.
  /// - 로그인 상태가 아니거나 홈 화면에 위젯이 없으면 서버를 부르지 않는다.
  Future<void> sync({bool force = false}) {
    if (force) return _scheduleForced();

    final running = _running;
    if (running != null && _runningGeneration == _generation) return running;

    final last = _lastAttemptAt;
    if (last != null && _deps.now().difference(last).abs() < minInterval) {
      return Future<void>.value();
    }
    return _run();
  }

  Future<void> _scheduleForced() {
    // 로그인 상태가 아니면 돌아도 할 일이 없으니 타이머도 걸지 않는다.
    if (!_deps.isLoggedIn()) return Future<void>.value();
    _forceTimer?.cancel();
    final completer = _forceCompleter ??= Completer<void>();
    _forceTimer = _deps.createTimer(forceDebounce, _fireForced);
    return completer.future;
  }

  void _fireForced() {
    _forceTimer = null;
    final completer = _forceCompleter;
    _forceCompleter = null;
    // 돌고 있는 것은 force 이전 값을 받았을 수 있어서 끝난 뒤 새로 돈다.
    final running = _running ?? Future<void>.value();
    final task = running.then((_) => _run());
    completer?.complete(task);
  }

  /// 한 번 돈다. 지금 세대에서 돌고 있는 것이 있으면 합치고, 앞 세대 것이면
  /// 끝나기를 기다린 뒤 새로 돈다. 앞 세대 것은 쓰기 직전에 세대 확인으로
  /// 막히므로 새 계정 값은 이쪽이 쓴다.
  Future<void> _run() {
    final running = _running;
    if (running != null) {
      if (_runningGeneration == _generation) return running;
      return running.then((_) => _run());
    }

    _runningGeneration = _generation;
    late final Future<void> task;
    task = _syncOnce().whenComplete(() {
      if (identical(_running, task)) _running = null;
    });
    _running = task;
    return task;
  }

  Future<void> _syncOnce() async {
    final generation = _generation;
    try {
      if (!_deps.isLoggedIn()) return;
      if (!await _hasInstalledWidgets()) return;
      if (generation != _generation) return;

      final now = _deps.now();
      _lastAttemptAt = now;
      final today = HomeWidgetSnapshotBuilder.dateOnly(now);
      await _preparePastMonths(today);
      if (generation != _generation) return;

      final months = HomeWidgetSnapshotBuilder.monthsInRange(today);
      final calendarsFuture = Future.wait([
        for (final month in months) _calendarOf(month, today, generation),
      ]);
      final reviewDueFuture = _deps.fetchReviewDue().then<ReviewDueResponse?>(
            (value) => value,
            onError: (Object error) => null,
          );
      final calendars = await calendarsFuture;
      final reviewDue = await reviewDueFuture;
      await _savePastMonths(generation);
      // 복습 예정을 못 받았으면 이전 스냅샷을 그대로 둔다.
      if (reviewDue == null) return;

      if (generation != _generation || !_deps.isLoggedIn()) return;

      final written = await _serialized(() async {
        if (generation != _generation) return false;
        final snapshot = HomeWidgetSnapshotBuilder.build(
          now: now,
          themeColor: _deps.themeColor(),
          calendars: calendars,
          reviewDue: reviewDue,
          profileVersion: await _currentProfileVersion(),
        );
        if (generation != _generation) return false;
        await _write(snapshot.toJson());
        return true;
      });
      if (!written) return;
    } catch (error) {
      debugPrint('HomeWidgetSyncService sync failed: $error');
      return;
    }

    // 치장이나 사진이 바뀌었으면 프로필 그림도 새로 찍는다. 그림을 찍는 데 시간이
    // 걸려서 기다리지 않는다. 겹쳐 불러도 refreshProfile 이 알아서 한 번씩 돈다.
    unawaited(refreshProfile());
  }

  /// 홈 화면에 위젯이 하나라도 있는지. 확인하다 실패하면 없는 것으로 본다.
  /// 위젯을 못 갱신하는 편이 서버를 괜히 부르는 편보다 낫다.
  Future<bool> _hasInstalledWidgets() async {
    try {
      return await _deps.hasInstalledWidgets();
    } catch (error) {
      debugPrint('HomeWidgetSyncService installed check failed: $error');
      return false;
    }
  }

  /// 이 달 달력. 오늘이 속한 달은 매번 받고 지난 달은 캐시를 쓴다.
  Future<StudyCalendarModel> _calendarOf(
    ({int year, int month}) month,
    DateTime today,
    int generation,
  ) async {
    final isThisMonth = month.year == today.year && month.month == today.month;
    final key = '${month.year}-${month.month}';
    if (!isThisMonth) {
      final cached = _pastMonths[key];
      if (cached != null) return cached;
    }
    final calendar = await _deps.fetchCalendar(month.year, month.month);
    // 받는 사이에 로그아웃했으면 앞 사람 달력을 캐시에 넣지 않는다.
    if (!isThisMonth && generation == _generation && _pastMonthsDay == today) {
      _pastMonths[key] = calendar;
      _pastMonthsDirty = true;
    }
    return calendar;
  }

  /// 지난 달 캐시를 오늘 것으로 맞춘다. 처음이면 기기에 저장해 둔 것을 읽고,
  /// 채운 날짜가 오늘이 아니면 버린다.
  Future<void> _preparePastMonths(DateTime today) async {
    if (!_pastMonthsLoaded) {
      _pastMonthsLoaded = true;
      try {
        final restored = _PastMonthsCache.decode(
          await _deps.readPastMonths(),
        );
        if (restored != null && restored.day == today) {
          _pastMonths
            ..clear()
            ..addAll(restored.months);
          _pastMonthsDay = today;
        }
      } catch (error) {
        debugPrint('HomeWidgetSyncService past months restore failed: $error');
      }
    }
    if (_pastMonthsDay != today) {
      _pastMonths.clear();
      _pastMonthsDay = today;
      _pastMonthsDirty = false;
    }
  }

  Future<void> _savePastMonths(int generation) async {
    if (!_pastMonthsDirty) return;
    final day = _pastMonthsDay;
    if (day == null || generation != _generation) return;
    _pastMonthsDirty = false;
    try {
      await _deps.writePastMonths(_PastMonthsCache.encode(day, _pastMonths));
    } catch (error) {
      debugPrint('HomeWidgetSyncService past months save failed: $error');
    }
    // 쓰는 사이에 로그아웃했으면 방금 쓴 것을 지운다. clear 의 지우기보다
    // 늦게 끝났을 수 있다.
    if (generation != _generation) {
      try {
        await _deps.writePastMonths(null);
      } catch (_) {}
    }
  }

  /// 로그아웃 스냅샷을 쓰고 프로필 그림과 캐시를 버린다.
  ///
  /// 로그아웃, 탈퇴, 인증 실패가 모두 `UserProvider.resetUserInfo` 로 모여서
  /// 거기서 부른다. 앞 사람의 기록이 홈 화면에 남으면 안 된다.
  Future<void> clear() async {
    _generation++;
    _pastMonths.clear();
    _pastMonthsDay = null;
    _pastMonthsDirty = false;
    // 메모리가 비었으니 기기 저장분을 다시 읽을 일도 없다.
    _pastMonthsLoaded = true;
    _lastAttemptAt = null;
    _lastSnapshot = null;

    try {
      await _serialized(() async {
        await _write(const HomeWidgetSnapshot.loggedOut().toJson());
      });
    } catch (error) {
      debugPrint('HomeWidgetSyncService clear snapshot failed: $error');
    }
    try {
      await _deps.deleteProfileImage();
    } catch (error) {
      debugPrint('HomeWidgetSyncService clear profile failed: $error');
    }
    try {
      // 다음 사람의 프로필이 우연히 같은 재료여도 다시 찍게 한다.
      await _deps.writeProfileHash(null);
    } catch (error) {
      debugPrint('HomeWidgetSyncService clear hash failed: $error');
    }
    try {
      // 지난달 캐시에는 누구 것인지 적혀 있지 않다. 여기서 지우는 것이 다음
      // 사람에게 앞 사람 달력이 섞이지 않게 하는 유일한 장치다.
      await _deps.writePastMonths(null);
    } catch (error) {
      debugPrint('HomeWidgetSyncService clear past months failed: $error');
    }
  }

  /// 테마 색만 고쳐 다시 쓴다. 서버는 부르지 않는다.
  ///
  /// 테마 색은 `flutter_secure_storage` 에 있어서 위젯이 직접 읽을 수 없다.
  Future<void> updateTheme(Color color) => _patchSnapshot((snapshot) {
        snapshot['themeColor'] = HomeWidgetSnapshotBuilder.hexOf(color);
      });

  /// 프로필 그림을 바뀌었을 때만 다시 찍는다.
  ///
  /// 사진 주소, 개구리 층 그림, 테두리가 이전에 찍은 것과 같으면 건너뛴다.
  /// 찍었으면 `profileVersion` 을 올려 위젯이 그림을 다시 읽게 한다.
  /// 홈 화면에 위젯이 없으면 찍지 않는다.
  Future<void> refreshProfile() {
    final running = _profileRunning;
    if (running != null) {
      // 찍는 중에 또 바뀌었을 수 있다. 끝나고 한 번 더 본다.
      _profileRerun = true;
      return running;
    }
    final task = _refreshProfileOnce().whenComplete(() {
      _profileRunning = null;
      if (_profileRerun) {
        _profileRerun = false;
        unawaited(refreshProfile());
      }
    });
    _profileRunning = task;
    return task;
  }

  Future<void> _refreshProfileOnce() async {
    final generation = _generation;
    // 기다리는 사이에 로그아웃했으면 아무것도 쓰지 않는다. 앞 사람 해시만
    // 남으면 다음에 같은 재료일 때 그림 없이 건너뛴다.
    bool changed() => generation != _generation;
    try {
      if (!_deps.isLoggedIn()) return;
      if (!await _hasInstalledWidgets()) return;
      if (changed()) return;

      final input = await _deps.readProfileInput();
      if (input == null || changed()) return;

      final hash = input.hash;
      final storedHash = await _deps.readProfileHash();
      if (changed() || storedHash == hash) return;

      final rendered = await _deps.renderProfile(input);
      if (changed()) {
        // 찍는 사이에 로그아웃했다. 방금 쓴 그림을 다시 지운다.
        if (rendered) await _deps.deleteProfileImage();
        return;
      }
      if (!rendered) return;

      final version = await _currentProfileVersion() + 1;
      if (changed()) return;
      _profileVersion = version;
      await _deps.writeProfileVersion(version);
      if (changed()) return;
      await _deps.writeProfileHash(hash);
      if (changed()) {
        // 해시를 쓰는 사이에 clear 가 지웠을 수도, 아닐 수도 있다. 다시 지운다.
        await _deps.writeProfileHash(null);
        return;
      }
      await _patchSnapshot((snapshot) {
        snapshot['profileVersion'] = version;
      });
    } catch (error) {
      debugPrint('HomeWidgetSyncService profile failed: $error');
    }
  }

  Future<int> _currentProfileVersion() async {
    final cached = _profileVersion;
    if (cached != null) return cached;
    final stored = await _deps.readProfileVersion();
    _profileVersion = stored;
    return stored;
  }

  /// 마지막 로그인 스냅샷의 필드 몇 개만 고쳐 다시 쓴다.
  ///
  /// 로그아웃 스냅샷이거나 아직 쓴 적이 없으면 아무것도 하지 않는다.
  Future<void> _patchSnapshot(
    void Function(Map<String, dynamic> snapshot) patch,
  ) async {
    final generation = _generation;
    try {
      await _serialized(() async {
        if (generation != _generation) return;
        var current = _lastSnapshot;
        if (current == null) {
          final raw = await _deps.readSnapshot();
          if (raw == null || raw.isEmpty) return;
          final decoded = jsonDecode(raw);
          if (decoded is! Map) return;
          current = Map<String, dynamic>.from(decoded);
        }
        if (current['loggedIn'] != true) return;
        final next = Map<String, dynamic>.from(current);
        patch(next);
        await _write(next);
      });
    } catch (error) {
      debugPrint('HomeWidgetSyncService patch failed: $error');
    }
  }

  Future<void> _write(Map<String, dynamic> snapshot) async {
    await _deps.writeSnapshot(jsonEncode(snapshot));
    _lastSnapshot = snapshot['loggedIn'] == true ? snapshot : null;
    await _deps.updateWidgets();
  }

  Future<T> _serialized<T>(Future<T> Function() task) {
    final result = _writeQueue.then((_) => task());
    _writeQueue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }
}

/// 기기에 저장하는 지난달 달력 캐시. 채운 날짜와 달별 응답을 같이 적는다.
///
/// 사용자를 적지 않는다. 계정이 섞이지 않게 하는 것은 로그아웃 때
/// [HomeWidgetSyncService.clear] 가 지우는 것뿐이다.
class _PastMonthsCache {
  final DateTime day;
  final Map<String, StudyCalendarModel> months;

  const _PastMonthsCache(this.day, this.months);

  static String encode(DateTime day, Map<String, StudyCalendarModel> months) {
    return jsonEncode({
      'day': HomeWidgetSnapshotBuilder.formatDate(day),
      'months': {
        for (final entry in months.entries) entry.key: _toJson(entry.value),
      },
    });
  }

  static _PastMonthsCache? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final day = DateTime.tryParse('${decoded['day']}');
    final months = decoded['months'];
    if (day == null || months is! Map) return null;
    return _PastMonthsCache(
      HomeWidgetSnapshotBuilder.dateOnly(day),
      {
        for (final entry in months.entries)
          '${entry.key}': StudyCalendarModel.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          ),
      },
    );
  }

  static Map<String, dynamic> _toJson(StudyCalendarModel calendar) {
    return {
      'year': calendar.year,
      'month': calendar.month,
      'currentStreak': calendar.currentStreak,
      'bestStreak': calendar.bestStreak,
      'thisMonthStudyDays': calendar.thisMonthStudyDays,
      'records': [
        for (final record in calendar.records)
          {
            'date': HomeWidgetSnapshotBuilder.formatDate(record.date),
            'hasStudied': record.hasStudied,
            'reviewCount': record.reviewCount,
            'noteWriteCount': record.noteWriteCount,
            'studyMinutes': record.studyMinutes,
            'reviewedItems': record.reviewedItems,
            'moodEmojiKey': record.moodEmojiKey,
          },
      ],
    };
  }
}

Timer _defaultCreateTimer(Duration duration, void Function() callback) =>
    Timer(duration, callback);

/// [HomeWidgetSyncService] 가 바깥에 기대는 것들. 테스트에서 가짜로 바꿔 끼운다.
class HomeWidgetSyncDeps {
  final DateTime Function() now;
  final bool Function() isLoggedIn;
  final Color Function() themeColor;

  /// 홈 화면에 이 앱 위젯이 하나라도 있는지.
  final Future<bool> Function() hasInstalledWidgets;

  final Future<StudyCalendarModel> Function(int year, int month) fetchCalendar;

  /// 못 받았으면 null.
  final Future<ReviewDueResponse?> Function() fetchReviewDue;

  final Future<String?> Function() readSnapshot;
  final Future<void> Function(String json) writeSnapshot;
  final Future<void> Function() updateWidgets;

  /// 지난달 달력 캐시(JSON). null 을 쓰면 지운다.
  final Future<String?> Function() readPastMonths;
  final Future<void> Function(String? json) writePastMonths;

  /// 그릴 재료가 아직 준비되지 않았으면 null.
  final Future<HomeWidgetProfileInput?> Function() readProfileInput;
  final Future<bool> Function(HomeWidgetProfileInput input) renderProfile;
  final Future<void> Function() deleteProfileImage;
  final Future<String?> Function() readProfileHash;
  final Future<void> Function(String? hash) writeProfileHash;
  final Future<int> Function() readProfileVersion;
  final Future<void> Function(int version) writeProfileVersion;

  /// `force` 호출을 모으는 타이머. 테스트에서 시간을 직접 넘기려고 바꿔 끼운다.
  final Timer Function(Duration duration, void Function() callback) createTimer;

  const HomeWidgetSyncDeps({
    required this.now,
    required this.isLoggedIn,
    required this.themeColor,
    required this.hasInstalledWidgets,
    required this.fetchCalendar,
    required this.fetchReviewDue,
    required this.readSnapshot,
    required this.writeSnapshot,
    required this.updateWidgets,
    required this.readPastMonths,
    required this.writePastMonths,
    required this.readProfileInput,
    required this.renderProfile,
    required this.deleteProfileImage,
    required this.readProfileHash,
    required this.writeProfileHash,
    required this.readProfileVersion,
    required this.writeProfileVersion,
    this.createTimer = _defaultCreateTimer,
  });

  /// SharedPreferences 에 두는 프로필 그림 입력 해시와 버전.
  static const String _profileHashKey = 'home_widget_profile_hash';
  static const String _profileVersionKey = 'home_widget_profile_version';

  /// SharedPreferences 에 두는 지난달 달력 캐시.
  static const String _pastMonthsKey = 'home_widget_past_months';

  /// 앱에서 쓰는 실제 의존성.
  factory HomeWidgetSyncDeps.app() {
    final calendarService = StudyCalendarService();
    final problemService = ProblemService();

    return HomeWidgetSyncDeps(
      now: AppClock.now,
      isLoggedIn: () => _read<UserProvider>()?.isLoggedIn == LoginStatus.login,
      themeColor: () =>
          _read<ThemeHandler>()?.primaryColor ?? Colors.pink[200]!,
      hasInstalledWidgets: () async {
        if (!_supported) return false;
        final widgets = await HomeWidget.getInstalledWidgets();
        return widgets.isNotEmpty;
      },
      fetchCalendar: (year, month) => calendarService.getStudyCalendar(
        year: year,
        month: month,
        showErrorSnackBar: false,
      ),
      // 홈 배지용 ReviewDueProvider 는 건드리지 않는다. 같이 쓰면 복습 예정
      // 화면의 조회가 위젯 조회에 막히고, 실패가 화면 상태로 새어 나간다.
      fetchReviewDue: () =>
          problemService.getReviewDueProblems(showErrorSnackBar: false),
      readSnapshot: () async {
        if (!_supported) return null;
        return HomeWidget.getWidgetData<String>(HomeWidgetSnapshot.storageKey);
      },
      writeSnapshot: (json) async {
        if (!_supported) return;
        await HomeWidget.saveWidgetData<String>(
          HomeWidgetSnapshot.storageKey,
          json,
        );
      },
      updateWidgets: _updateWidgets,
      readPastMonths: () async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_pastMonthsKey);
      },
      writePastMonths: (json) async {
        final prefs = await SharedPreferences.getInstance();
        if (json == null) {
          await prefs.remove(_pastMonthsKey);
        } else {
          await prefs.setString(_pastMonthsKey, json);
        }
      },
      readProfileInput: _readProfileInput,
      renderProfile: (input) async {
        if (!_supported) return false;
        return HomeWidgetProfileRenderer.render(input);
      },
      deleteProfileImage: () async {
        if (!_supported) return;
        // null 을 쓰면 home_widget 이 그 키에 적힌 PNG 파일까지 지운다.
        await HomeWidget.saveWidgetData<String>(
          HomeWidgetProfileRenderer.storageKey,
          null,
        );
      },
      readProfileHash: () async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_profileHashKey);
      },
      writeProfileHash: (hash) async {
        final prefs = await SharedPreferences.getInstance();
        if (hash == null) {
          await prefs.remove(_profileHashKey);
        } else {
          await prefs.setString(_profileHashKey, hash);
        }
      },
      readProfileVersion: () async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getInt(_profileVersionKey) ?? 0;
      },
      writeProfileVersion: (version) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_profileVersionKey, version);
      },
    );
  }

  /// 홈 화면 위젯이 있는 플랫폼인지. 테스트(호스트 OS)에서는 저장소를 건드리지
  /// 않는다.
  static bool get _supported =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// 화면 밖에서 Provider 를 읽는다. 알림 라우터와 같은 방식이다.
  static T? _read<T>() {
    final context = AppNavigator.navigatorKey.currentContext;
    if (context == null) return null;
    try {
      return Provider.of<T>(context, listen: false);
    } catch (error) {
      debugPrint('Provider<$T> not available for home widget: $error');
      return null;
    }
  }

  static Future<void> _updateWidgets() async {
    if (!_supported) return;
    if (Platform.isIOS) {
      await HomeWidget.updateWidget(
          iOSName: HomeWidgetSyncService.iOSWidgetKind);
      return;
    }
    // 하나가 실패해도 나머지 크기는 갱신한다.
    for (final provider in HomeWidgetSyncService.androidProviders) {
      try {
        await HomeWidget.updateWidget(qualifiedAndroidName: provider);
      } catch (error) {
        debugPrint('HomeWidget update failed ($provider): $error');
      }
    }
  }

  static Future<HomeWidgetProfileInput?> _readProfileInput() async {
    final user = _read<UserProvider>();
    final cosmetic = _read<CosmeticProvider>();
    if (user == null || cosmetic == null) return null;

    final info = user.userInfoModel;
    if (info == null) return null;

    // 로그인 직후에는 옷장을 받는 중일 수 있다. 받기 전 층은 맨 개구리라서 그대로
    // 찍으면 꾸민 모습이 아니다. 받는 중이면 같은 요청을 기다린다.
    if (cosmetic.isLoading) await cosmetic.load();
    if (!cosmetic.hasCatalog) return null;

    return HomeWidgetProfileInput(
      photoUrl: info.profileImageUrl,
      layers: cosmetic.layers,
      frameUrl: cosmetic.profileFrame?.imageUrl,
    );
  }
}
