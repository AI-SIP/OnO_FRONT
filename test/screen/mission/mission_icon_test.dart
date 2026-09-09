// 미션 아이콘 폴백 테스트.
//
// 에셋 19종이 아직 없어서 Material 아이콘으로 그린다. 서버가 앱이 모르는
// iconKey 를 내려도 빈칸이 아니라 기본 아이콘이 떠야 한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  group('MissionIcon 위젯', () {
    testWidgets('모르는 키를 줘도 기본 아이콘을 그린다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MissionIcon(iconKey: 'unknown_key', color: Colors.black),
          ),
        ),
      );

      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    });
  });
}
