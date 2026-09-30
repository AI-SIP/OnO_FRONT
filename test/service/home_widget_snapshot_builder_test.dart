// 홈 화면 위젯 스냅샷 빌더와 동기화 서비스 테스트.
//
// 스냅샷 모양은 iOS, Android 위젯이 따로 읽는 계약이라
// (`docs/홈 화면 위젯/위젯_데이터_계약.md`) 필드 이름과 날짜 범위를 잠가 둔다.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Cosmetic/CosmeticLoadoutModel.dart';
import 'package:ono/Model/Problem/ReviewDueProblemModel.dart';
import 'package:ono/Model/StudyCalendar/StudyCalendarModel.dart';
import 'package:ono/Service/HomeWidget/HomeWidgetProfileRenderer.dart';
import 'package:ono/Service/HomeWidget/HomeWidgetSnapshot.dart';
import 'package:ono/Service/HomeWidget/HomeWidgetSnapshotBuilder.dart';
import 'package:ono/Service/HomeWidget/HomeWidgetSyncService.dart';

DailyStudyRecord _record(
  String date, {
  bool studied = true,
  int reviews = 1,
  int notes = 0,
}) {
  return DailyStudyRecord(
    date: DateTime.parse(date),
    hasStudied: studied,
    reviewCount: reviews,
    noteWriteCount: notes,
    studyMinutes: 0,
    reviewedItems: const [],
  );
}

StudyCalendarModel _calendar(
  int year,
  int month, {
  int currentStreak = 0,
  int thisMonthStudyDays = 0,
  List<DailyStudyRecord> records = const [],
}) {
  return StudyCalendarModel(
    year: year,
    month: month,
    currentStreak: currentStreak,
    bestStreak: 99,
    thisMonthStudyDays: thisMonthStudyDays,
    records: records,
  );
}

ReviewDueProblemModel _problem(
  int id, {
  String? reference,
  String? memo,
  DateTime? nextReviewAt,
}) {
  return ReviewDueProblemModel(
    problemId: id,
    reference: reference,
    memo: memo,
    nextReviewAt: nextReviewAt,
    reviewInterval: 1,
    consecutiveCorrectCount: 0,
  );
}

ReviewDueResponse _reviewDue({
  int dueCount = 0,
  int overdueCount = 0,
  List<ReviewDueProblemModel> problems = const [],
}) {
  return ReviewDueResponse(
    dueCount: dueCount,
    overdueCount: overdueCount,
    problems: problems,
  );
}

const _pink = Color(0xFFF48FB1);

void main() {
  group('달력 범위', () {
    test('월 경계: 2026-10-01 이면 8월 30일(일)부터 세 달을 잇는다', () {
      final today = DateTime(2026, 10, 1);

      expect(
          HomeWidgetSnapshotBuilder.rangeStart(today), DateTime(2026, 8, 30));
      expect(HomeWidgetSnapshotBuilder.monthsInRange(today), [
        (year: 2026, month: 8),
        (year: 2026, month: 9),
        (year: 2026, month: 10),
      ]);

      final days = HomeWidgetSnapshotBuilder.daysInRange(today);
      expect(days.first, DateTime(2026, 8, 30));
      expect(days.last, DateTime(2026, 10, 1));
      // 8월 2일 + 9월 30일 + 10월 1일
      expect(days, hasLength(33));
    });

    test('계약서 예시: 2026-09-30(수) 이면 8월 30일부터 두 달이다', () {
      final today = DateTime(2026, 9, 30);

      expect(
          HomeWidgetSnapshotBuilder.rangeStart(today), DateTime(2026, 8, 30));
      expect(HomeWidgetSnapshotBuilder.monthsInRange(today), [
        (year: 2026, month: 8),
        (year: 2026, month: 9),
      ]);
      expect(HomeWidgetSnapshotBuilder.daysInRange(today), hasLength(32));
    });

    test('오늘이 일요일이면 그날이 맨 아래 줄 첫 칸이고 29일이다', () {
      final today = DateTime(2026, 9, 27); // 일요일

      final days = HomeWidgetSnapshotBuilder.daysInRange(today);
      expect(days.first, DateTime(2026, 8, 30));
      expect(days.first.weekday, DateTime.sunday);
      expect(days.last, today);
      expect(days, hasLength(29));
    });

    test('오늘이 토요일이면 꽉 찬 5주 35일이다', () {
      final today = DateTime(2026, 10, 3); // 토요일

      final days = HomeWidgetSnapshotBuilder.daysInRange(today);
      expect(days.first.weekday, DateTime.sunday);
      expect(days, hasLength(35));
    });

    test('시각이 붙어 있어도 날짜로만 본다', () {
      expect(
        HomeWidgetSnapshotBuilder.daysInRange(DateTime(2026, 10, 1, 23, 59)),
        hasLength(33),
      );
    });
  });

  group('build', () {
    test('세 달 응답을 날짜 오름차순으로 잇고 없는 날은 level 0 이다', () {
      final snapshot = HomeWidgetSnapshotBuilder.build(
        now: DateTime(2026, 10, 1, 9, 30),
        themeColor: _pink,
        calendars: [
          _calendar(2026, 8, records: [
            _record('2026-08-31', reviews: 5), // level 2
            _record('2026-08-10', reviews: 10), // 범위 밖
          ]),
          _calendar(2026, 9, records: [
            _record('2026-09-01', reviews: 1), // level 1
            _record('2026-09-30', reviews: 7, notes: 3), // level 3
            _record('2026-09-15', studied: false, reviews: 0),
          ]),
          _calendar(
            2026,
            10,
            currentStreak: 2,
            thisMonthStudyDays: 0,
          ),
        ],
        reviewDue: _reviewDue(),
        profileVersion: 7,
      );

      final days = {for (final d in snapshot.days) d.date: d.level};
      expect(snapshot.days.first.date, '2026-08-30');
      expect(snapshot.days.last.date, '2026-10-01');
      expect(snapshot.days, hasLength(33));
      expect(
        snapshot.days.map((d) => d.date).toList(),
        [...snapshot.days.map((d) => d.date)]..sort(),
      );
      expect(days['2026-08-30'], 0);
      expect(days['2026-08-31'], 2);
      expect(days['2026-09-01'], 1);
      expect(days['2026-09-15'], 0);
      expect(days['2026-09-30'], 3);
      expect(days['2026-10-01'], 0);
      expect(days.containsKey('2026-08-10'), isFalse);

      // 연속 일수와 이번 달 공부한 날은 오늘이 속한 달 응답을 쓴다.
      expect(snapshot.currentStreak, 2);
      expect(snapshot.thisMonthStudyDays, 0);
      expect(snapshot.lastStudiedDate, '2026-09-30');
      expect(snapshot.today, '2026-10-01');
      expect(snapshot.profileVersion, 7);
    });

    test('lastStudiedDate 는 오늘 이후 기록과 안 한 날을 빼고 가장 최근이다', () {
      final snapshot = HomeWidgetSnapshotBuilder.build(
        now: DateTime(2026, 9, 20),
        themeColor: _pink,
        calendars: [
          _calendar(2026, 8, records: [_record('2026-08-03')]),
          _calendar(2026, 9, records: [
            _record('2026-09-18'),
            _record('2026-09-19', studied: false, reviews: 0),
            _record('2026-09-25'), // 오늘보다 뒤
          ]),
        ],
        reviewDue: _reviewDue(),
        profileVersion: 0,
      );

      expect(snapshot.lastStudiedDate, '2026-09-18');
      expect(
        snapshot.days.where((d) => d.date.compareTo('2026-09-20') > 0),
        isEmpty,
      );
    });

    test('공부한 날이 없으면 lastStudiedDate 는 null 이다', () {
      final snapshot = HomeWidgetSnapshotBuilder.build(
        now: DateTime(2026, 9, 20),
        themeColor: _pink,
        calendars: [_calendar(2026, 8), _calendar(2026, 9)],
        reviewDue: _reviewDue(),
        profileVersion: 0,
      );

      expect(snapshot.lastStudiedDate, isNull);
      expect(snapshot.toJson()['lastStudiedDate'], isNull);
      expect(snapshot.toJson().containsKey('lastStudiedDate'), isTrue);
    });

    test('추천은 앞에서 3개, 제목은 reference → memo → 문제 {id} 순서다', () {
      final today = DateTime(2026, 9, 30);
      final snapshot = HomeWidgetSnapshotBuilder.build(
        now: today,
        themeColor: _pink,
        calendars: [_calendar(2026, 9)],
        reviewDue: _reviewDue(
          dueCount: 5,
          overdueCount: 2,
          problems: [
            _problem(
              381,
              reference: '  수학Ⅱ 미분 단원평가 18번  ',
              memo: '메모',
              nextReviewAt: DateTime(2026, 9, 27),
            ),
            _problem(
              12,
              reference: '   ',
              memo: ' 메모만 있음 ',
              nextReviewAt: DateTime(2026, 9, 30, 15),
            ),
            _problem(13, reference: '', memo: ' ', nextReviewAt: null),
            _problem(14, reference: '네 번째'),
          ],
        ),
        profileVersion: 0,
      );

      expect(snapshot.dueCount, 5);
      expect(snapshot.overdueCount, 2);
      expect(snapshot.recommendations, hasLength(3));
      expect(
        snapshot.recommendations.map((r) => r.toJson()).toList(),
        [
          {'problemId': 381, 'title': '수학Ⅱ 미분 단원평가 18번', 'overdueDays': 3},
          {'problemId': 12, 'title': '메모만 있음', 'overdueDays': 0},
          {'problemId': 13, 'title': '문제 13', 'overdueDays': 0},
        ],
      );
    });

    test('overdueDays 는 날짜 차이이고 0 아래로 내려가지 않는다', () {
      final today = DateTime(2026, 10, 1, 0, 10);

      expect(
        HomeWidgetSnapshotBuilder.overdueDaysOf(
            DateTime(2026, 9, 30, 23, 50), today),
        1,
      );
      expect(
        HomeWidgetSnapshotBuilder.overdueDaysOf(DateTime(2026, 8, 31), today),
        31,
      );
      expect(
        HomeWidgetSnapshotBuilder.overdueDaysOf(DateTime(2026, 10, 3), today),
        0,
      );
      expect(HomeWidgetSnapshotBuilder.overdueDaysOf(null, today), 0);
    });

    test('JSON 필드 이름이 계약서와 같다', () {
      final json = HomeWidgetSnapshotBuilder.build(
        now: DateTime(2026, 9, 30, 21, 4, 11),
        themeColor: _pink,
        calendars: [_calendar(2026, 8), _calendar(2026, 9)],
        reviewDue: _reviewDue(),
        profileVersion: 1,
      ).toJson();

      expect(json.keys.toSet(), {
        'v',
        'loggedIn',
        'generatedAt',
        'today',
        'themeColor',
        'currentStreak',
        'thisMonthStudyDays',
        'lastStudiedDate',
        'dueCount',
        'overdueCount',
        'recommendations',
        'days',
        'profileVersion',
      });
      expect(json['v'], 1);
      expect(json['loggedIn'], isTrue);
      expect(json['today'], '2026-09-30');
      expect(
        json['generatedAt'],
        matches(RegExp(r'^2026-09-30T21:04:11[+-]\d{2}:\d{2}$')),
      );
      expect((json['days'] as List).first, {'date': '2026-08-30', 'level': 0});
      // 위젯에 넘기는 값은 JSON 문자열로 한 번 더 바뀌어도 그대로다.
      expect(jsonDecode(jsonEncode(json)), json);
    });
  });

  group('로그아웃 스냅샷', () {
    test('v 와 loggedIn 만 남는다', () {
      const snapshot = HomeWidgetSnapshot.loggedOut();

      expect(snapshot.toJson(), {'v': 1, 'loggedIn': false});
      expect(jsonDecode(snapshot.encode()), {'v': 1, 'loggedIn': false});
    });
  });

  group('themeColor', () {
    test('#RRGGBB 대문자로 적고 투명도는 버린다', () {
      expect(HomeWidgetSnapshotBuilder.hexOf(_pink), '#F48FB1');
      expect(
          HomeWidgetSnapshotBuilder.hexOf(const Color(0x80012A0F)), '#012A0F');
      expect(HomeWidgetSnapshotBuilder.hexOf(Colors.black), '#000000');
    });
  });

  group('HomeWidgetSyncService', () {
    late _FakeDeps fake;
    late HomeWidgetSyncService service;

    setUp(() {
      fake = _FakeDeps(now: DateTime(2026, 9, 30, 9));
      service = HomeWidgetSyncService.forTest(fake.build());
    });

    /// force 호출은 모았다가 돌아서, 모으는 시간을 넘겨야 끝난다.
    Future<void> forceSync() async {
      final future = service.sync(force: true);
      fake.timers.elapse(HomeWidgetSyncService.forceDebounce);
      await future;
    }

    test('60초 안의 두 번째 호출은 건너뛰고, 지나면 다시 받는다', () async {
      await service.sync();
      expect(fake.reviewDueCalls, 1);
      expect(fake.writes, hasLength(1));

      fake.now = fake.now.add(const Duration(seconds: 30));
      await service.sync();
      expect(fake.reviewDueCalls, 1);

      fake.now = fake.now.add(const Duration(seconds: 31));
      await service.sync();
      expect(fake.reviewDueCalls, 2);
    });

    test('force 면 60초 안이어도 다시 받는다', () async {
      await service.sync();
      await forceSync();
      expect(fake.reviewDueCalls, 2);
    });

    test('돌고 있는 동안 부르면 같은 Future 를 돌려주고 한 번만 받는다', () async {
      final gate = Completer<void>();
      fake.reviewDueGate = gate;

      final first = service.sync();
      final second = service.sync();
      expect(identical(first, second), isTrue);

      gate.complete();
      await Future.wait([first, second]);
      expect(fake.reviewDueCalls, 1);
      expect(fake.writes, hasLength(1));
    });

    test('돌고 있는 동안 force 로 부르면 끝난 뒤 한 번 더 돈다', () async {
      final gate = Completer<void>();
      fake.reviewDueGate = gate;

      final first = service.sync();
      final forced = service.sync(force: true);
      fake.timers.elapse(HomeWidgetSyncService.forceDebounce);
      await pumpEventQueue();
      // 앞 동기화가 끝나기 전에는 새로 부르지 않는다.
      expect(fake.reviewDueCalls, 1);

      fake.reviewDueGate = null;
      gate.complete();
      await first;
      await forced;

      expect(fake.reviewDueCalls, 2);
    });

    group('위젯 설치 여부', () {
      test('홈 화면에 위젯이 없으면 서버를 한 번도 부르지 않는다', () async {
        fake.installed = false;
        fake.profileInput = HomeWidgetProfileInput(layers: const []);

        await service.sync();
        await forceSync();
        await service.refreshProfile();

        expect(fake.installedChecks, greaterThanOrEqualTo(3));
        expect(fake.reviewDueCalls, 0);
        expect(fake.calendarCalls, isEmpty);
        expect(fake.writes, isEmpty);
        expect(fake.renderCalls, 0);
      });

      test('설치 확인이 실패하면 동기화를 건너뛴다', () async {
        fake.installedError = Exception('channel');

        await service.sync();

        expect(fake.reviewDueCalls, 0);
        expect(fake.calendarCalls, isEmpty);
        expect(fake.writes, isEmpty);
      });

      test('위젯이 없어도 clear 는 로그아웃 스냅샷을 쓴다', () async {
        fake.installed = false;

        await service.clear();

        expect(fake.writes, hasLength(1));
        expect(jsonDecode(fake.writes.single), {'v': 1, 'loggedIn': false});
        expect(fake.profileDeleted, 1);
      });

      test('나중에 위젯을 두면 그때부터 받는다', () async {
        fake.installed = false;
        await service.sync();
        expect(fake.reviewDueCalls, 0);

        // 설치 안 됨은 시도로 치지 않아서 60초를 기다리지 않는다.
        fake.installed = true;
        await service.sync();
        expect(fake.reviewDueCalls, 1);
      });
    });

    group('실패 뒤 간격', () {
      test('복습 예정을 못 받아도 60초 안에는 다시 부르지 않는다', () async {
        fake.reviewDueResult = null;

        await service.sync();
        expect(fake.reviewDueCalls, 1);
        expect(fake.writes, isEmpty);

        fake.reviewDueResult = _reviewDue(dueCount: 1);
        fake.now = fake.now.add(const Duration(seconds: 59));
        await service.sync();
        expect(fake.reviewDueCalls, 1);

        fake.now = fake.now.add(const Duration(seconds: 2));
        await service.sync();
        expect(fake.reviewDueCalls, 2);
        expect(fake.writes, hasLength(1));
      });

      test('달력 요청이 실패해도 60초 안에는 다시 부르지 않는다', () async {
        fake.calendarError = Exception('network');

        await service.sync();
        final calls = fake.calendarCalls.length;
        expect(fake.writes, isEmpty);

        fake.calendarError = null;
        fake.now = fake.now.add(const Duration(seconds: 10));
        await service.sync();
        expect(fake.calendarCalls, hasLength(calls));
      });

      test('실패 뒤에도 force 는 부른다', () async {
        fake.reviewDueResult = null;
        await service.sync();

        fake.reviewDueResult = _reviewDue(dueCount: 1);
        await forceSync();

        expect(fake.reviewDueCalls, 2);
        expect(fake.writes, hasLength(1));
      });
    });

    group('force 모으기', () {
      test('짧게 여러 번 불러도 마지막 호출 뒤 한 번만 돈다', () async {
        final futures = <Future<void>>[];
        for (var i = 0; i < 10; i++) {
          futures.add(service.sync(force: true));
          fake.timers.elapse(const Duration(seconds: 1));
        }
        await pumpEventQueue();
        expect(fake.reviewDueCalls, 0);

        fake.timers.elapse(const Duration(seconds: 2));
        await Future.wait(futures);

        expect(fake.reviewDueCalls, 1);
        expect(fake.writes, hasLength(1));
      });

      test('모으는 시간이 지나기 전에는 부르지 않는다', () async {
        unawaited(service.sync(force: true));
        fake.timers.elapse(const Duration(milliseconds: 2999));
        await pumpEventQueue();
        expect(fake.reviewDueCalls, 0);

        fake.timers.elapse(const Duration(milliseconds: 1));
        await pumpEventQueue();
        expect(fake.reviewDueCalls, 1);
      });
    });

    group('지난달 달력 캐시', () {
      test('그날 안에서 다시 받지 않고, 날짜가 바뀌면 버린다', () async {
        fake.now = DateTime(2026, 10, 1, 9);

        await service.sync();
        expect(fake.calendarCalls, ['2026-8', '2026-9', '2026-10']);

        fake.calendarCalls.clear();
        await forceSync();
        expect(fake.calendarCalls, ['2026-10']);

        fake.calendarCalls.clear();
        fake.now = DateTime(2026, 10, 2, 9);
        await forceSync();
        expect(fake.calendarCalls, ['2026-8', '2026-9', '2026-10']);
      });

      test('기기에 저장해 두고 앱을 새로 띄우면 그것을 쓴다', () async {
        fake.now = DateTime(2026, 10, 1, 9);
        fake.calendarRecords['2026-9'] = [_record('2026-09-30', reviews: 7)];

        await service.sync();
        expect(fake.pastMonths, isNotNull);
        final first = jsonDecode(fake.writes.last) as Map<String, dynamic>;

        // 앱을 새로 띄운 것처럼 메모리가 빈 서비스를 만든다.
        final restarted = HomeWidgetSyncService.forTest(fake.build());
        fake.calendarCalls.clear();
        await restarted.sync();

        expect(fake.calendarCalls, ['2026-10']);
        final second = jsonDecode(fake.writes.last) as Map<String, dynamic>;
        expect(second['days'], first['days']);
        expect(second['lastStudiedDate'], '2026-09-30');
      });

      test('저장해 둔 날짜가 오늘이 아니면 버리고 새로 받는다', () async {
        fake.now = DateTime(2026, 10, 1, 9);
        await service.sync();
        expect(fake.pastMonths, contains('"day":"2026-10-01"'));

        fake.now = DateTime(2026, 10, 2, 9);
        final restarted = HomeWidgetSyncService.forTest(fake.build());
        fake.calendarCalls.clear();
        await restarted.sync();

        expect(fake.calendarCalls, ['2026-8', '2026-9', '2026-10']);
        expect(fake.pastMonths, contains('"day":"2026-10-02"'));
      });

      test('이번 달은 캐시하지 않는다', () async {
        fake.now = DateTime(2026, 9, 30, 9);
        await service.sync();

        final stored = jsonDecode(fake.pastMonths!) as Map<String, dynamic>;
        expect((stored['months'] as Map).keys, ['2026-8']);
      });

      test('clear 하면 기기 저장분도 지운다', () async {
        await service.sync();
        expect(fake.pastMonths, isNotNull);

        await service.clear();

        expect(fake.pastMonths, isNull);
      });
    });

    test('로그아웃 상태면 아무것도 부르지 않는다', () async {
      fake.loggedIn = false;

      await service.sync();

      expect(fake.reviewDueCalls, 0);
      expect(fake.writes, isEmpty);
    });

    test('동기화 도중 clear 하면 로그아웃 스냅샷을 덮어쓰지 않는다', () async {
      final gate = Completer<void>();
      fake.reviewDueGate = gate;

      final running = service.sync();
      await service.clear();
      gate.complete();
      await running;

      expect(fake.writes, hasLength(1));
      expect(jsonDecode(fake.writes.single), {'v': 1, 'loggedIn': false});
      expect(fake.profileDeleted, 1);
      expect(fake.profileHash, isNull);
      expect(fake.pastMonths, isNull);
    });

    test('계정을 바꾼 직후 sync 는 앞 계정 동기화에 합치지 않고 새로 돈다', () async {
      final gate = Completer<void>();
      fake.reviewDueGate = gate;

      final old = service.sync();
      await pumpEventQueue();
      expect(fake.reviewDueCalls, 1);

      // 로그아웃 뒤 다른 계정으로 로그인했다.
      await service.clear();
      fake.writes.clear();
      fake.reviewDueResult = _reviewDue(dueCount: 9);
      final fresh = service.sync();
      expect(identical(old, fresh), isFalse);

      fake.reviewDueGate = null;
      gate.complete();
      await Future.wait([old, fresh]);

      expect(fake.reviewDueCalls, 2);
      // 앞 계정 응답은 쓰지 않고 새 계정 값만 남는다.
      expect(fake.writes, hasLength(1));
      final last = jsonDecode(fake.writes.single) as Map<String, dynamic>;
      expect(last['dueCount'], 9);
    });

    test('updateTheme 은 서버를 부르지 않고 색만 고쳐 쓴다', () async {
      await service.sync();
      final callsBefore = fake.reviewDueCalls;

      await service.updateTheme(const Color(0xFF64B5F6));

      expect(fake.reviewDueCalls, callsBefore);
      expect(fake.writes, hasLength(2));
      final last = jsonDecode(fake.writes.last) as Map<String, dynamic>;
      expect(last['themeColor'], '#64B5F6');
      expect(last['dueCount'], 3);
    });

    test('로그아웃 스냅샷 위에는 updateTheme 이 아무것도 쓰지 않는다', () async {
      await service.clear();
      fake.writes.clear();

      await service.updateTheme(const Color(0xFF64B5F6));

      expect(fake.writes, isEmpty);
    });

    test('프로필 재료가 같으면 다시 찍지 않고, 바뀌면 찍고 버전을 올린다', () async {
      fake.profileInput = HomeWidgetProfileInput(
        layers: const [
          CosmeticLayerModel(imageUrl: 'assets/a.png', layerOrder: 0),
        ],
      );

      await service.sync();
      await pumpEventQueue();
      expect(fake.renderCalls, 1);
      expect(fake.profileVersion, 1);
      final afterFirst = jsonDecode(fake.writes.last) as Map<String, dynamic>;
      expect(afterFirst['profileVersion'], 1);

      await service.refreshProfile();
      await pumpEventQueue();
      expect(fake.renderCalls, 1);

      fake.profileInput = HomeWidgetProfileInput(
        photoUrl: 'https://example.com/me.png',
        layers: const [
          CosmeticLayerModel(imageUrl: 'assets/a.png', layerOrder: 0),
        ],
      );
      await service.refreshProfile();
      await pumpEventQueue();
      expect(fake.renderCalls, 2);
      expect(fake.profileVersion, 2);
      final last = jsonDecode(fake.writes.last) as Map<String, dynamic>;
      expect(last['profileVersion'], 2);
    });

    test('sync 는 프로필을 찍는 동안 기다리지 않는다', () async {
      fake.profileInput = HomeWidgetProfileInput(layers: const []);
      final renderGate = Completer<void>();
      fake.renderGate = renderGate;

      await service.sync();
      await pumpEventQueue();
      expect(fake.writes, hasLength(1));
      expect(fake.renderCalls, 1);
      expect(fake.profileHash, isNull);

      // 프로필을 찍는 중에도 다음 동기화가 막히지 않는다.
      fake.now = fake.now.add(const Duration(minutes: 2));
      await service.sync();
      expect(fake.reviewDueCalls, 2);

      renderGate.complete();
      await service.refreshProfile();
      await pumpEventQueue();
      expect(fake.profileHash, isNotNull);
    });

    test('프로필을 찍는 도중 clear 하면 해시와 버전을 남기지 않는다', () async {
      fake.profileInput = HomeWidgetProfileInput(layers: const []);
      final renderGate = Completer<void>();
      fake.renderGate = renderGate;

      final profile = service.refreshProfile();
      await pumpEventQueue();
      expect(fake.renderCalls, 1);

      await service.clear();
      renderGate.complete();
      await profile;

      expect(fake.profileHash, isNull);
      expect(fake.profileVersion, 0);
      // clear 한 번 + 찍은 그림 다시 지우기 한 번.
      expect(fake.profileDeleted, 2);
    });

    test('프로필 해시를 읽는 도중 clear 하면 아무것도 쓰지 않는다', () async {
      fake.profileInput = HomeWidgetProfileInput(layers: const []);
      final hashGate = Completer<void>();
      fake.readHashGate = hashGate;

      final profile = service.refreshProfile();
      await pumpEventQueue();

      await service.clear();
      hashGate.complete();
      await profile;

      expect(fake.renderCalls, 0);
      expect(fake.profileHash, isNull);
      expect(fake.profileVersion, 0);
    });

    test('프로필 버전을 쓰는 도중 clear 하면 해시를 쓰지 않는다', () async {
      fake.profileInput = HomeWidgetProfileInput(layers: const []);
      final versionGate = Completer<void>();
      fake.writeVersionGate = versionGate;

      final profile = service.refreshProfile();
      await pumpEventQueue();

      await service.clear();
      versionGate.complete();
      await profile;

      expect(fake.profileHash, isNull);
    });

    test('프로필을 못 찍으면 버전을 올리지 않는다', () async {
      fake.profileInput = HomeWidgetProfileInput(layers: const []);
      fake.renderResult = false;

      await service.sync();
      await pumpEventQueue();

      expect(fake.renderCalls, 1);
      expect(fake.profileVersion, 0);
      expect(fake.profileHash, isNull);
    });
  });
}

/// 직접 넘기는 시계. force 모으기 타이머만 쓴다.
class _FakeTimers {
  Duration _elapsed = Duration.zero;
  final List<_FakeTimer> _timers = [];

  Timer create(Duration duration, void Function() callback) {
    final timer = _FakeTimer(_elapsed + duration, callback);
    _timers.add(timer);
    return timer;
  }

  void elapse(Duration duration) {
    _elapsed += duration;
    final due = _timers.where((t) => t.isActive && t.dueAt <= _elapsed).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    for (final timer in due) {
      timer.fire();
    }
    _timers.removeWhere((t) => !t.isActive);
  }
}

class _FakeTimer implements Timer {
  final Duration dueAt;
  final void Function() _callback;
  bool _active = true;

  _FakeTimer(this.dueAt, this._callback);

  void fire() {
    if (!_active) return;
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

class _FakeDeps {
  DateTime now;
  bool loggedIn = true;
  Color theme = _pink;
  final _FakeTimers timers = _FakeTimers();

  bool installed = true;
  Object? installedError;
  int installedChecks = 0;

  final List<String> calendarCalls = [];
  final Map<String, List<DailyStudyRecord>> calendarRecords = {};
  Object? calendarError;

  int reviewDueCalls = 0;
  Completer<void>? reviewDueGate;
  ReviewDueResponse? reviewDueResult = _reviewDue(dueCount: 3, overdueCount: 1);

  final List<String> writes = [];
  int updateCalls = 0;

  /// 기기에 저장된 지난달 캐시. 서비스를 새로 만들어도 남는다.
  String? pastMonths;

  HomeWidgetProfileInput? profileInput;
  bool renderResult = true;
  int renderCalls = 0;
  Completer<void>? renderGate;
  Completer<void>? readHashGate;
  Completer<void>? writeVersionGate;
  int profileDeleted = 0;
  String? profileHash;
  int profileVersion = 0;

  _FakeDeps({required this.now});

  HomeWidgetSyncDeps build() {
    return HomeWidgetSyncDeps(
      now: () => now,
      isLoggedIn: () => loggedIn,
      themeColor: () => theme,
      hasInstalledWidgets: () async {
        installedChecks++;
        final error = installedError;
        if (error != null) throw error;
        return installed;
      },
      fetchCalendar: (year, month) async {
        calendarCalls.add('$year-$month');
        final error = calendarError;
        if (error != null) throw error;
        return _calendar(
          year,
          month,
          currentStreak: 4,
          records: calendarRecords['$year-$month'] ?? const [],
        );
      },
      fetchReviewDue: () async {
        reviewDueCalls++;
        final gate = reviewDueGate;
        final result = reviewDueResult;
        if (gate != null) await gate.future;
        return result;
      },
      readSnapshot: () async => writes.isEmpty ? null : writes.last,
      writeSnapshot: (json) async => writes.add(json),
      updateWidgets: () async => updateCalls++,
      readPastMonths: () async => pastMonths,
      writePastMonths: (json) async => pastMonths = json,
      readProfileInput: () async => profileInput,
      renderProfile: (_) async {
        renderCalls++;
        final gate = renderGate;
        if (gate != null) await gate.future;
        return renderResult;
      },
      deleteProfileImage: () async => profileDeleted++,
      readProfileHash: () async {
        final gate = readHashGate;
        if (gate != null) await gate.future;
        return profileHash;
      },
      writeProfileHash: (hash) async => profileHash = hash,
      readProfileVersion: () async => profileVersion,
      writeProfileVersion: (version) async {
        final gate = writeVersionGate;
        if (gate != null) await gate.future;
        profileVersion = version;
      },
      createTimer: timers.create,
    );
  }
}
