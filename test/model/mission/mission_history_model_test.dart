// 보상 기록 파싱 테스트.
//
// 합계는 첫 페이지에만 온다. 두 번째 페이지부터는 없거나 null 이라, 화면이
// 첫 페이지 값을 들고 있어야 한다는 것이 계약이다.
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Mission/MissionHistoryModel.dart';
import 'package:ono/Model/Mission/MissionModel.dart';

Map<String, dynamic> itemJson({
  Object? progressId = 1024,
  Object? claimedAt = '2026-09-10T14:33:47',
  Object? category = 'WEEKLY',
  Object? rewardType = 'XP',
}) {
  return <String, dynamic>{
    'progressId': progressId,
    'code': 'WEEKLY_NOTE_10',
    'title': '열 권의 노트',
    'iconKey': 'writing_wink',
    'category': category,
    'periodKey': '2026-W37',
    'rewardType': rewardType,
    'rewardValue': 80,
    'claimedAt': claimedAt,
  };
}

void main() {
  group('MissionHistoryItemModel', () {
    test('계약 JSON 을 그대로 읽는다', () {
      final item = MissionHistoryItemModel.fromJsonOrNull(itemJson());

      expect(item, isNotNull);
      expect(item!.progressId, 1024);
      expect(item.code, 'WEEKLY_NOTE_10');
      expect(item.title, '열 권의 노트');
      expect(item.iconKey, 'writing_wink');
      expect(item.category, MissionCategory.weekly);
      expect(item.periodKey, '2026-W37');
      expect(item.rewardType, MissionRewardType.xp);
      expect(item.rewardValue, 80);
      expect(item.claimedAt, DateTime(2026, 9, 10, 14, 33, 47));
    });

    test('claimedAt 을 읽지 못하면 그 줄만 버린다', () {
      expect(
        MissionHistoryItemModel.fromJsonOrNull(itemJson(claimedAt: '어제쯤')),
        isNull,
      );
      expect(
        MissionHistoryItemModel.fromJsonOrNull(itemJson(claimedAt: null)),
        isNull,
      );
    });

    test('모르는 category 나 rewardType 이 와도 기록은 남긴다', () {
      // 이미 끝난 일이다. 종류를 모른다고 지난 일이 없던 일이 되면 안 된다.
      final item = MissionHistoryItemModel.fromJsonOrNull(
        itemJson(category: 'SEASON', rewardType: 'THEME'),
      );

      expect(item, isNotNull);
      expect(item!.category, isNull);
      expect(item.rewardType, isNull);
      expect(item.rewardValue, 80);
    });

    test('JSON 이 아니거나 progressId 가 없으면 null 이다', () {
      expect(MissionHistoryItemModel.fromJsonOrNull(null), isNull);
      expect(MissionHistoryItemModel.fromJsonOrNull('기록'), isNull);
      expect(
        MissionHistoryItemModel.fromJsonOrNull(itemJson(progressId: null)),
        isNull,
      );
    });
  });

  group('MissionHistoryPageModel', () {
    test('첫 페이지는 합계를 함께 읽는다', () {
      final page = MissionHistoryPageModel.fromJson(<String, dynamic>{
        'content': [itemJson()],
        'nextCursor': 998,
        'hasNext': true,
        'size': 20,
        'totalClaimedXp': 1250,
        'totalClaimedCount': 37,
      });

      expect(page.content, hasLength(1));
      expect(page.nextCursor, 998);
      expect(page.hasNext, isTrue);
      expect(page.totalClaimedXp, 1250);
      expect(page.totalClaimedCount, 37);
      expect(page.isLastPage, isFalse);
    });

    test('다음 페이지에 합계가 없어도 읽힌다', () {
      final page = MissionHistoryPageModel.fromJson(<String, dynamic>{
        'content': [itemJson()],
        'nextCursor': null,
        'hasNext': false,
        'size': 20,
      });

      expect(page.totalClaimedXp, isNull);
      expect(page.totalClaimedCount, isNull);
      expect(page.isLastPage, isTrue);
    });

    test('hasNext 가 true 여도 커서가 없으면 마지막 페이지다', () {
      final page = MissionHistoryPageModel.fromJson(<String, dynamic>{
        'content': const [],
        'nextCursor': null,
        'hasNext': true,
      });

      expect(page.isLastPage, isTrue);
    });

    test('읽지 못한 줄만 빠지고 나머지는 남는다', () {
      final page = MissionHistoryPageModel.fromJson(<String, dynamic>{
        'content': [
          itemJson(),
          itemJson(claimedAt: '언젠가'),
          'not a map',
          null,
        ],
        'hasNext': false,
      });

      expect(page.content, hasLength(1));
    });

    test('모양이 다르면 빈 페이지다', () {
      expect(MissionHistoryPageModel.fromJson(null).content, isEmpty);
      expect(
        MissionHistoryPageModel.fromJson(<String, dynamic>{}).isLastPage,
        isTrue,
      );
    });
  });
}
