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

MissionBoardModel buildBoard({List<MissionModel>? daily}) {
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
  );
}

void main() {
  setUpOnoTest();

  setUpAll(() {
    setUpProviderTestEnv();
    registerFallbackValue((String _) {});
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

    test('이미 로딩 중이면 재진입하지 않는다 (동시 호출 가드)', () async {
      var callCount = 0;
      when(() => missionService.getMissions()).thenAnswer((_) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return buildBoard();
      });

      await Future.wait([provider.fetchMissions(), provider.fetchMissions()]);

      expect(callCount, 1);
    });
  });

  group('claim', () {
    void stubClaim(MissionClaimResultModel? result) {
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenAnswer((_) async => result);
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

    test('실패하면 상태를 바꾸지 않고 문구만 남긴다', () async {
      stubGetMissions(buildBoard());
      await provider.fetchMissions();
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenAnswer((invocation) async {
        final onFailure =
            invocation.namedArguments[#onFailure] as void Function(String)?;
        onFailure?.call('이미 보상을 받은 미션이에요.');
        return null;
      });

      final result = await provider.claim(1024);

      expect(result, isNull);
      expect(provider.dailyMissions[0].claimed, isFalse);
      expect(provider.consumeClaimError(), '이미 보상을 받은 미션이에요.');
      // 한 번 꺼내면 비워진다. 같은 문구가 두 번 뜨지 않는다.
      expect(provider.consumeClaimError(), isNull);
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
