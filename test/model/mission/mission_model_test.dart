// 미션 모델 파싱 테스트.
//
// 계약 JSON 이 그대로 읽히는지와, 서버에 새 값이 생겼을 때 구버전 앱이
// 죽지 않고 그 줄만 건너뛰는지가 관찰 대상이다.
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Mission/MissionClaimResultModel.dart';
import 'package:ono/Model/Mission/MissionGroupModel.dart';
import 'package:ono/Model/Mission/MissionModel.dart';

Map<String, dynamic> dailyMissionJson({
  Object? category = 'DAILY',
  Object? rewardType = 'XP',
  Object? progressId = 1024,
  String iconKey = 'note_write',
  int current = 1,
  bool completed = true,
  bool claimed = false,
}) {
  return <String, dynamic>{
    'progressId': progressId,
    'code': 'DAILY_NOTE_WRITE',
    'title': '오늘의 오답',
    'description': '오답노트 1개 등록',
    'iconKey': iconKey,
    'category': category,
    'current': current,
    'target': 1,
    'completed': completed,
    'claimed': claimed,
    'rewardType': rewardType,
    'rewardValue': 10,
  };
}

void main() {
  group('MissionModel', () {
    test('계약 JSON 을 그대로 읽는다', () {
      final mission = MissionModel.fromJsonOrNull(dailyMissionJson());

      expect(mission, isNotNull);
      expect(mission!.progressId, 1024);
      expect(mission.code, 'DAILY_NOTE_WRITE');
      expect(mission.title, '오늘의 오답');
      expect(mission.description, '오답노트 1개 등록');
      expect(mission.iconKey, 'note_write');
      expect(mission.category, MissionCategory.daily);
      expect(mission.current, 1);
      expect(mission.target, 1);
      expect(mission.completed, isTrue);
      expect(mission.claimed, isFalse);
      expect(mission.rewardType, MissionRewardType.xp);
      expect(mission.rewardValue, 10);
      expect(mission.isClaimable, isTrue);
    });

    test('모르는 category 가 오면 null 을 돌려준다 (크래시하지 않는다)', () {
      final mission =
          MissionModel.fromJsonOrNull(dailyMissionJson(category: 'SEASON'));

      expect(mission, isNull);
    });

    test('모르는 rewardType 이 오면 null 을 돌려준다', () {
      final mission =
          MissionModel.fromJsonOrNull(dailyMissionJson(rewardType: 'THEME'));

      expect(mission, isNull);
    });

    test('code 가 비었거나 JSON 이 아니면 null 이다', () {
      expect(MissionModel.fromJsonOrNull(<String, dynamic>{}), isNull);
      expect(MissionModel.fromJsonOrNull('mission'), isNull);
      expect(MissionModel.fromJsonOrNull(null), isNull);
    });

    test('progressId 가 없으면 받기를 열지 않는다', () {
      final mission =
          MissionModel.fromJsonOrNull(dailyMissionJson(progressId: null));

      expect(mission, isNotNull);
      expect(mission!.progressId, isNull);
      expect(mission.isClaimable, isFalse);
    });

    test('이미 받은 미션은 다시 받을 수 없다', () {
      final mission =
          MissionModel.fromJsonOrNull(dailyMissionJson(claimed: true));

      expect(mission!.isClaimable, isFalse);
    });

    test('참/거짓이 0/1 로 와도 읽는다 (미션 하나 때문에 보드가 날아가면 안 된다)', () {
      final json = dailyMissionJson()
        ..['completed'] = 1
        ..['claimed'] = 0;

      final mission = MissionModel.fromJsonOrNull(json);

      expect(mission, isNotNull);
      expect(mission!.completed, isTrue);
      expect(mission.claimed, isFalse);
      expect(mission.isClaimable, isTrue);
    });

    test('숫자 자리에 문자열이, 문자 자리에 숫자가 와도 읽는다', () {
      final json = dailyMissionJson()
        ..['current'] = '1'
        ..['target'] = 1.0
        ..['title'] = 7;

      final mission = MissionModel.fromJsonOrNull(json);

      expect(mission, isNotNull);
      expect(mission!.current, 1);
      expect(mission.target, 1);
      expect(mission.title, '7');
    });

    test('iconKey 가 없으면 기본 키로 떨어진다', () {
      final json = dailyMissionJson()..remove('iconKey');

      expect(
        MissionModel.fromJsonOrNull(json)!.iconKey,
        MissionModel.fallbackIconKey,
      );
    });

    test('읽을 수 없는 모양이 와도 던지지 않고 그 미션만 버린다', () {
      final json = dailyMissionJson()..['category'] = {'nested': 'map'};

      expect(() => MissionModel.fromJsonOrNull(json), returnsNormally);
      expect(MissionModel.fromJsonOrNull(json), isNull);
    });

    test('진행률은 0 과 1 사이로 잘린다', () {
      final partial = MissionModel.fromJsonOrNull(
        dailyMissionJson(current: 0, completed: false),
      );
      final over = MissionModel.fromJsonOrNull(dailyMissionJson(current: 5));

      expect(partial!.progressRatio, 0.0);
      expect(over!.progressRatio, 1.0);
    });
  });

  group('MissionGroupModel', () {
    test('읽지 못한 미션만 빠지고 나머지는 살아남는다', () {
      final group = MissionGroupModel.fromJson(<String, dynamic>{
        'periodKey': '2026-09-09',
        'missions': [
          dailyMissionJson(),
          dailyMissionJson(category: 'SEASON'), // 모르는 종류
          dailyMissionJson(rewardType: 'TITLE'), // 모르는 보상
          dailyMissionJson(completed: false, current: 0),
        ],
      });

      expect(group.periodKey, '2026-09-09');
      expect(group.missions.length, 2);
      expect(group.completedCount, 1);
      expect(group.claimableCount, 1);
    });

    test('필드 타입이 어긋난 미션이 섞여도 나머지는 살아남는다', () {
      final broken = dailyMissionJson()..['category'] = ['DAILY'];
      final group = MissionGroupModel.fromJson(<String, dynamic>{
        'periodKey': '2026-09-09',
        'missions': [
          broken,
          dailyMissionJson()..['completed'] = 1,
          'not a map',
          null,
        ],
      });

      expect(group.missions.length, 1);
      expect(group.missions.single.completed, isTrue);
    });

    test('periodKey 가 문자열이 아니어도 묶음은 살아남는다', () {
      final group = MissionGroupModel.fromJson(<String, dynamic>{
        'periodKey': 20260909,
        'missions': [dailyMissionJson()],
      });

      expect(group.periodKey, '');
      expect(group.missions, hasLength(1));
    });

    test('missions 가 없거나 모양이 다르면 빈 묶음이다', () {
      expect(MissionGroupModel.fromJson(null).missions, isEmpty);
      expect(
        MissionGroupModel.fromJson(<String, dynamic>{'periodKey': '2026-W37'})
            .missions,
        isEmpty,
      );
    });
  });

  group('MissionBoardModel', () {
    MissionBoardModel buildBoard() {
      return MissionBoardModel.fromJson(<String, dynamic>{
        'daily': {
          'periodKey': '2026-09-09',
          'missions': [
            dailyMissionJson(),
            dailyMissionJson(progressId: 2048, completed: false, current: 0),
          ],
        },
        'weekly': {'periodKey': '2026-W37', 'missions': []},
      });
    }

    test('일일과 주간을 나눠 읽는다', () {
      final board = buildBoard();

      expect(board.daily.periodKey, '2026-09-09');
      expect(board.daily.missions.length, 2);
      expect(board.weekly.periodKey, '2026-W37');
      expect(board.weekly.missions, isEmpty);
      expect(board.isEmpty, isFalse);
      expect(board.claimableCount, 1);
    });

    test('미션 하나가 깨져도 보드 전체가 날아가지 않는다', () {
      final board = MissionBoardModel.fromJson(<String, dynamic>{
        'daily': {
          'periodKey': '2026-09-09',
          'missions': [
            dailyMissionJson()..['rewardType'] = 99,
            dailyMissionJson(progressId: 2048, completed: false, current: 0),
          ],
        },
        'weekly': {'periodKey': '2026-W37', 'missions': []},
      });

      expect(board.isEmpty, isFalse);
      expect(board.daily.missions, hasLength(1));
      expect(board.daily.missions.single.progressId, 2048);
    });

    test('양쪽이 모두 비면 isEmpty 다 (배너와 화면을 숨기는 조건)', () {
      final board = MissionBoardModel.fromJson(<String, dynamic>{});

      expect(board.isEmpty, isTrue);
    });

    test('markClaimed 는 그 미션만 받음으로 바꾼다', () {
      final board = buildBoard().markClaimed(1024);

      expect(board.daily.missions[0].claimed, isTrue);
      expect(board.daily.missions[1].claimed, isFalse);
      expect(board.claimableCount, 0);
    });
  });

  group('MissionClaimResultModel', () {
    test('계약 JSON 을 그대로 읽는다', () {
      final result = MissionClaimResultModel.fromJsonOrNull(<String, dynamic>{
        'progressId': 1024,
        'rewardType': 'XP',
        'rewardValue': 10,
        'totalStudyLevel': 7,
        'leveledUp': true,
      });

      expect(result, isNotNull);
      expect(result!.progressId, 1024);
      expect(result.rewardType, MissionRewardType.xp);
      expect(result.rewardValue, 10);
      expect(result.totalStudyLevel, 7);
      expect(result.leveledUp, isTrue);
    });

    test('모르는 rewardType 이 와도 결과 자체는 버리지 않는다', () {
      final result = MissionClaimResultModel.fromJsonOrNull(<String, dynamic>{
        'progressId': 1024,
        'rewardType': 'THEME',
        'rewardValue': 1,
      });

      expect(result, isNotNull);
      expect(result!.rewardType, isNull);
      expect(result.leveledUp, isFalse);
    });

    test('progressId 가 없으면 읽지 않는다', () {
      expect(
        MissionClaimResultModel.fromJsonOrNull(<String, dynamic>{'a': 1}),
        isNull,
      );
      expect(MissionClaimResultModel.fromJsonOrNull(null), isNull);
    });
  });
}
