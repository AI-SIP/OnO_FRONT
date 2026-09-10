// 미션 아이콘 폴백 테스트.
//
// 전용 아이콘 19종이 아직 없어서 앱이 이미 가진 이모지를 빌려 쓴다. 서버가
// 앱이 모르는 코드나 iconKey 를 내려도 빈칸이 아니라 새싹이 떠야 한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Emoji/OnoEmojiCatalog.dart';
import 'package:ono/Screen/Mission/MissionIcon.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  group('MissionIcon.resolve', () {
    test('아는 키는 그 키의 아이콘을 준다', () {
      expect(MissionIcon.resolve('note_write'), Icons.edit_note);
      expect(MissionIcon.resolve('attendance'), Icons.event_available_outlined);
      expect(MissionIcon.isKnown('note_write'), isTrue);
    });

    test('모르는 키는 기본 아이콘으로 떨어진다', () {
      expect(MissionIcon.resolve('아직_없는_키'), Icons.flag_outlined);
      expect(MissionIcon.resolve(null), Icons.flag_outlined);
      expect(MissionIcon.resolve(''), Icons.flag_outlined);
      expect(MissionIcon.isKnown('아직_없는_키'), isFalse);
    });

    test('시드 미션이 쓰는 아이콘 키는 모두 알고 있다', () {
      const seedKeys = [
        'attendance',
        'note_write',
        'review',
        'accuracy',
        'practice_set',
        'mood',
      ];

      for (final key in seedKeys) {
        expect(MissionIcon.isKnown(key), isTrue, reason: '$key 를 모른다');
      }
    });
  });

  group('MissionIcon.resolveEmojiKey', () {
    test('미션 코드가 있으면 코드로 고른다', () {
      // 일일 출석과 주간 출석은 iconKey 가 같다. 코드로 갈라야 다른 그림이 된다.
      expect(
        MissionIcon.resolveEmojiKey(
          code: 'DAILY_ATTEND',
          iconKey: 'attendance',
        ),
        'success_checkmark',
      );
      expect(
        MissionIcon.resolveEmojiKey(
          code: 'WEEKLY_ATTEND_5',
          iconKey: 'attendance',
        ),
        'fired_up_sparkle_eyes',
      );
    });

    test('모르는 코드면 iconKey 로 고른다', () {
      expect(
        MissionIcon.resolveEmojiKey(
          code: 'DAILY_SOMETHING_NEW',
          iconKey: 'review',
        ),
        'reading_with_glasses',
      );
    });

    test('둘 다 모르면 새싹으로 떨어진다', () {
      expect(
        MissionIcon.resolveEmojiKey(code: '아직_없는_코드', iconKey: '아직_없는_키'),
        MissionIconKeys.fallbackEmoji,
      );
      expect(MissionIcon.resolveEmojiKey(), MissionIconKeys.fallbackEmoji);
    });

    test('고른 이모지 키가 실제로 있는 그림인지', () {
      for (final key in [
        'DAILY_ATTEND',
        'DAILY_NOTE_WRITE',
        'DAILY_REVIEW_3',
        'DAILY_CORRECT_3',
        'DAILY_PRACTICE_SET',
        'DAILY_MOOD',
        'WEEKLY_ATTEND_5',
        'WEEKLY_NOTE_10',
        'WEEKLY_REVIEW_30',
        'WEEKLY_SET_3',
      ]) {
        final emojiKey = MissionIcon.resolveEmojiKey(code: key);
        expect(
          OnoEmojiCatalog.byKey(emojiKey),
          isNotNull,
          reason: '$key 가 가리키는 $emojiKey 가 이모지 목록에 없다',
        );
      }
      expect(
        OnoEmojiCatalog.byKey(MissionIconKeys.fallbackEmoji),
        isNotNull,
      );
    });
  });

  group('MissionIcon 위젯', () {
    testWidgets('모르는 키를 줘도 빈칸이 아니라 그림을 그린다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MissionIcon(iconKey: 'unknown_key', color: Colors.black),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('그림은 화면 크기에 맞춰 작게 디코딩한다', (tester) async {
      // 이모지 원본이 한 장에 200KB 가까이 된다. 목록에 카드가 여럿 뜨므로
      // 디코딩 크기를 제한하지 않으면 메모리가 크게 는다.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MissionIcon(
              iconKey: 'note_write',
              color: Colors.black,
              size: 30,
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image;
      expect(provider, isA<ResizeImage>());
      expect((provider as ResizeImage).width, isNotNull);
      expect(provider.width, lessThanOrEqualTo(256));
    });
  });
}
