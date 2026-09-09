// MissionProvider 상태 전이 테스트.
//
// 조회 → 받기 → 그 미션만 claimed 로 바뀌는지, 그리고 받기 요청이 나가 있는
// 동안 다시 받기가 들어오지 않는지가 관찰 대상이다.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Mission/MissionClaimResultModel.dart';
import 'package:ono/Model/Mission/MissionGroupModel.dart';
import 'package:ono/Model/Mission/MissionModel.dart';
import 'package:ono/Provider/MissionProvider.dart';

import '../helpers/helpers.dart';
import 'support/provider_test_env.dart';

MissionModel buildMission({
  int? progressId = 1024,
  String code = 'DAILY_NOTE_WRITE',
  MissionCategory category = MissionCategory.daily,
  int current = 1,
  int target = 1,
  bool completed = true,
  bool claimed = false,
}) {
  return MissionModel(
    progressId: progressId,
    code: code,
    title: '오늘의 오답',
    description: '오답노트 1개 등록',
    iconKey: 'note_write',
    category: category,
    current: current,
    target: target,
    completed: completed,
    claimed: claimed,
    rewardType: MissionRewardType.xp,
    rewardValue: 10,
  );
}

MissionBoardModel buildBoard({
  List<MissionModel>? daily,
  List<MissionModel> expired = const [],
}) {
  return MissionBoardModel(
    daily: MissionGroupModel(
      periodKey: '2026-09-09',
      missions: daily ??
          [
            buildMission(),
            buildMission(
              progressId: 2048,
              code: 'DAILY_REVIEW_3',
              current: 1,
              target: 3,
              completed: false,
            ),
          ],
    ),
    weekly: const MissionGroupModel(periodKey: '2026-W37', missions: []),
    expired: MissionGroupModel(periodKey: '', missions: expired),
  );
}

void main() {
  setUpOnoTest();

  setUpAll(() {
    setUpProviderTestEnv();
    registerFallbackValue((MissionClaimFailure _) {});
  });

  late MockMissionService missionService;
  late MissionProvider provider;
  late NotifyRecorder notified;

  setUp(() {
    missionService = MockMissionService();
    provider = MissionProvider(missionService: missionService);
    notified = NotifyRecorder();
    provider.addListener(notified.call);
  });

  void stubGetMissions(MissionBoardModel? board) {
    when(() => missionService.getMissions()).thenAnswer((_) async => board);
  }

  group('초기 상태', () {
    test('아무 것도 안 했을 때 배너를 그리지 않는다', () {
      expect(provider.board, isNull);
      expect(provider.hasMissions, isFalse);
      expect(provider.dailyTotalCount, 0);
      expect(provider.dailyCompletedCount, 0);
      expect(provider.unclaimedCount, 0);
      expect(provider.isLoading, isFalse);
    });
  });

  group('fetchMissions', () {
    test('성공하면 board 가 채워지고 진행도 게터가 맞는다', () async {
      stubGetMissions(buildBoard());

      await provider.fetchMissions();

      expect(provider.hasMissions, isTrue);
      expect(provider.dailyTotalCount, 2);
      expect(provider.dailyCompletedCount, 1);
      expect(provider.unclaimedCount, 1);
      expect(provider.isLoading, isFalse);
      expect(notified.count, greaterThan(0));
    });

    test('조회에 실패하면(null) 화면을 숨긴 채로 둔다', () async {
      stubGetMissions(null);

      await provider.fetchMissions();

      expect(provider.board, isNull);
      expect(provider.hasMissions, isFalse);
      expect(provider.isLoading, isFalse);
    });

    test('한 번 받아 둔 미션은 다음 조회가 실패해도 사라지지 않는다', () async {
      stubGetMissions(buildBoard());
      await provider.fetchMissions();

      stubGetMissions(null);
      await provider.fetchMissions();

      expect(provider.hasMissions, isTrue);
      expect(provider.dailyTotalCount, 2);
    });

    test('미션이 하나도 없으면 배너를 숨긴다', () async {
      stubGetMissions(buildBoard(daily: []));

      await provider.fetchMissions();

      expect(provider.board, isNotNull);
      expect(provider.hasMissions, isFalse);
    });

    test('예외가 나도 삼키고 isLoading 은 false 로 돌아온다', () async {
      when(() => missionService.getMissions())
          .thenThrow(Exception('network error'));

      await provider.fetchMissions();

      expect(provider.isLoading, isFalse);
      expect(provider.board, isNull);
    });

    test('조회 중에 또 부르면 요청은 겹치지 않지만 호출이 버려지지도 않는다', () async {
      // 받기 실패 뒤의 복구 조회가 여기로 들어온다. 그냥 return 해 버리면
      // 호출자의 await 가 갱신 없이 끝나고, 이미 받은 미션에 '받기' 버튼이
      // 그대로 남는다.
      var callCount = 0;
      var inFlight = 0;
      var maxInFlight = 0;
      when(() => missionService.getMissions()).thenAnswer((_) async {
        callCount++;
        inFlight++;
        maxInFlight = inFlight > maxInFlight ? inFlight : maxInFlight;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        inFlight--;
        return buildBoard();
      });

      final results = await Future.wait(
        [provider.fetchMissions(), provider.fetchMissions()],
      );

      expect(callCount, 2, reason: '두 번째 호출이 버려지면 복구 조회가 사라진다');
      expect(maxInFlight, 1, reason: '요청이 겹치면 안 된다');
      expect(results, everyElement(isTrue));
    });

    test('조회가 끝난 뒤에야 뒤따르는 호출의 future 가 끝난다', () async {
      var call = 0;
      when(() => missionService.getMissions()).thenAnswer((_) async {
        call++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        // 두 번째 조회에서만 받음으로 바뀐다.
        return buildBoard(daily: [buildMission(claimed: call >= 2)]);
      });

      final first = provider.fetchMissions();
      final second = provider.fetchMissions();
      await first;
      await second;

      expect(provider.dailyMissions.single.claimed, isTrue);
    });

    test('서버가 답하면 true, 못 받으면 false 를 돌려준다', () async {
      stubGetMissions(buildBoard());
      expect(await provider.fetchMissions(), isTrue);

      stubGetMissions(null);
      expect(await provider.fetchMissions(), isFalse);
    });

    test('일일 배지와 진행도는 같은 집합을 센다', () async {
      stubGetMissions(
        MissionBoardModel(
          daily: MissionGroupModel(
            periodKey: '2026-09-09',
            missions: [buildMission(completed: false, current: 0)],
          ),
          weekly: MissionGroupModel(
            periodKey: '2026-W37',
            missions: [
              buildMission(progressId: 9001, code: 'WEEKLY_NOTE_10'),
              buildMission(progressId: 9002, code: 'WEEKLY_SET_3'),
            ],
          ),
        ),
      );

      await provider.fetchMissions();

      expect(provider.dailyTotalCount, 1);
      expect(provider.dailyCompletedCount, 0);
      // 홈 배너가 쓰는 값. 일일에 받을 것이 없으면 배지도 없어야 한다.
      expect(provider.dailyUnclaimedCount, 0);
      // 미션 화면 전체 기준은 그대로 둘을 합쳐 센다.
      expect(provider.unclaimedCount, 2);
    });
  });

  group('지난 미션', () {
    MissionModel expiredMission({int progressId = 777}) => buildMission(
          progressId: progressId,
          code: 'WEEKLY_REVIEW_30',
        );

    test('진행도(n/m)에는 안 들어가고 배지에는 들어간다', () async {
      // 기간을 넘긴 미수령 보상이 배지에 안 잡히면 있는 줄도 모르고 지나간다.
      stubGetMissions(buildBoard(
        daily: [buildMission(completed: false, current: 0)],
        expired: [expiredMission()],
      ));

      await provider.fetchMissions();

      expect(provider.dailyTotalCount, 1);
      expect(provider.dailyCompletedCount, 0);
      expect(provider.dailyUnclaimedCount, 0);
      expect(provider.expiredUnclaimedCount, 1);
      expect(provider.bannerUnclaimedCount, 1);
      expect(provider.expiredMissions, hasLength(1));
    });

    test('지난 미션도 받으면 그 미션만 받음이 된다', () async {
      stubGetMissions(buildBoard(expired: [expiredMission()]));
      await provider.fetchMissions();
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenAnswer(
        (_) async => const MissionClaimResultModel(
          progressId: 777,
          rewardType: MissionRewardType.xp,
          rewardValue: 100,
          totalStudyLevel: 8,
          leveledUp: false,
        ),
      );

      final result = await provider.claim(777);

      expect(result, isNotNull);
      expect(provider.expiredMissions.single.claimed, isTrue);
      expect(provider.bannerUnclaimedCount, 1); // 일일 하나만 남는다
      expect(provider.missionByProgressId(777), isNotNull);
    });

    test('받은 뒤 조회가 커밋 전 상태를 내려줘도 받음이 유지된다', () async {
      stubGetMissions(buildBoard(expired: [expiredMission()]));
      await provider.fetchMissions();
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenAnswer(
        (_) async => const MissionClaimResultModel(
          progressId: 777,
          rewardType: MissionRewardType.xp,
          rewardValue: 100,
          totalStudyLevel: 8,
          leveledUp: false,
        ),
      );
      await provider.claim(777);

      await provider.fetchMissions();

      expect(provider.expiredMissions.single.claimed, isTrue);
    });

    test('계정을 바꾸면 지난 미션도 함께 비운다', () async {
      stubGetMissions(buildBoard(expired: [expiredMission()]));
      await provider.fetchMissions();
      expect(provider.expiredMissions, isNotEmpty);

      provider.clear();

      expect(provider.expiredMissions, isEmpty);
      expect(provider.bannerUnclaimedCount, 0);
    });
  });

  group('claim', () {
    void stubClaim(MissionClaimResultModel? result) {
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenAnswer((_) async => result);
    }

    void stubClaimFailure(MissionClaimFailure failure) {
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenAnswer((invocation) async {
        final onFailure = invocation.namedArguments[#onFailure] as void
            Function(MissionClaimFailure)?;
        onFailure?.call(failure);
        return null;
      });
    }

    test('성공하면 그 미션만 claimed 로 바뀐다', () async {
      stubGetMissions(buildBoard());
      await provider.fetchMissions();
      stubClaim(const MissionClaimResultModel(
        progressId: 1024,
        rewardType: MissionRewardType.xp,
        rewardValue: 10,
        totalStudyLevel: 7,
        leveledUp: true,
      ));

      final result = await provider.claim(1024);

      expect(result, isNotNull);
      expect(result!.leveledUp, isTrue);
      expect(provider.dailyMissions[0].claimed, isTrue);
      expect(provider.dailyMissions[1].claimed, isFalse);
      expect(provider.unclaimedCount, 0);
      expect(provider.isClaiming(1024), isFalse);
    });

    test('응답이 오기 전에는 같은 미션을 다시 받지 않는다 (버튼 잠금)', () async {
      stubGetMissions(buildBoard());
      await provider.fetchMissions();

      var callCount = 0;
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenAnswer((_) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return const MissionClaimResultModel(
          progressId: 1024,
          rewardType: MissionRewardType.xp,
          rewardValue: 10,
          totalStudyLevel: 7,
          leveledUp: false,
        );
      });

      final first = provider.claim(1024);
      final second = provider.claim(1024);
      final results = await Future.wait([first, second]);

      expect(callCount, 1);
      expect(results.where((r) => r != null).length, 1);
    });

    test('요청이 나가 있는 동안 isClaiming 이 true 다', () async {
      stubGetMissions(buildBoard());
      await provider.fetchMissions();
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return null;
      });

      final pending = provider.claim(1024);
      expect(provider.isClaiming(1024), isTrue);
      expect(provider.isClaiming(2048), isFalse);

      await pending;
      expect(provider.isClaiming(1024), isFalse);
    });

    test('실패하면 상태를 바꾸지 않고 실패 내용만 남긴다', () async {
      stubGetMissions(buildBoard());
      await provider.fetchMissions();
      stubClaimFailure(const MissionClaimFailure(
        kind: MissionClaimFailureKind.rejected,
        errorCode: 7012,
        message: '이미 보상을 받은 미션이에요.',
      ));

      final result = await provider.claim(1024);

      expect(result, isNull);
      expect(provider.dailyMissions[0].claimed, isFalse);

      final failure = provider.consumeClaimFailure();
      expect(failure, isNotNull);
      expect(failure!.message, '이미 보상을 받은 미션이에요.');
      expect(failure.isAlreadyClaimed, isTrue);
      expect(failure.isUnknown, isFalse);
      // 한 번 꺼내면 비워진다. 같은 문구가 두 번 뜨지 않는다.
      expect(provider.consumeClaimFailure(), isNull);
    });

    test('받기 응답을 기다리는 사이에 조회가 끼어들어도 받음이 되돌아가지 않는다', () async {
      // 받기 응답이 느릴 때 당겨서 새로고침하면, 새 GET 이 claim 커밋 전
      // 상태를 읽어 온다. 그대로 덮으면 버튼이 '받기' 로 되돌아가고 다시
      // 누르면 이미 받았다는 오류가 뜬다.
      stubGetMissions(buildBoard());
      await provider.fetchMissions();

      stubClaim(const MissionClaimResultModel(
        progressId: 1024,
        rewardType: MissionRewardType.xp,
        rewardValue: 10,
        totalStudyLevel: 7,
        leveledUp: false,
      ));
      await provider.claim(1024);
      expect(provider.dailyMissions[0].claimed, isTrue);

      // 서버는 아직 claim 을 반영하지 못한 상태를 내려준다.
      stubGetMissions(buildBoard());
      await provider.fetchMissions();

      expect(provider.dailyMissions[0].claimed, isTrue);
      expect(provider.unclaimedCount, 0);
    });

    test('서버가 받음으로 따라잡으면 그 뒤부터는 서버를 그대로 따른다', () async {
      stubGetMissions(buildBoard());
      await provider.fetchMissions();
      stubClaim(const MissionClaimResultModel(
        progressId: 1024,
        rewardType: MissionRewardType.xp,
        rewardValue: 10,
        totalStudyLevel: 7,
        leveledUp: false,
      ));
      await provider.claim(1024);

      // 서버가 받음으로 내려준다.
      stubGetMissions(buildBoard(daily: [buildMission(claimed: true)]));
      await provider.fetchMissions();
      expect(provider.dailyMissions[0].claimed, isTrue);

      // 기간이 넘어가 같은 미션이 새 진행도로 돌아와도 앞 기억이 남지 않는다.
      stubGetMissions(buildBoard(daily: [buildMission()]));
      await provider.fetchMissions();
      expect(provider.dailyMissions[0].claimed, isFalse);
    });

    test('예외가 나도 삼키고 null 을 돌려준다', () async {
      stubGetMissions(buildBoard());
      await provider.fetchMissions();
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenThrow(Exception('boom'));

      expect(await provider.claim(1024), isNull);
      expect(provider.isClaiming(1024), isFalse);
    });
  });

  group('clear', () {
    test('들고 있던 미션을 비운다', () async {
      stubGetMissions(buildBoard());
      await provider.fetchMissions();

      provider.clear();

      expect(provider.board, isNull);
      expect(provider.hasMissions, isFalse);
    });
  });
}
