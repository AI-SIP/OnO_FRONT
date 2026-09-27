// 미션 아이콘 테스트.
//
// 전용 아이콘 열아홉 종이 `assets/MissionIcon/{iconKey}.svg` 로 들어왔다.
// 파일 이름이 곧 서버가 내려주는 키다. 서버가 앱이 모르는 코드나 iconKey 를
// 내려도 빈칸이 아니라 기본 그림이 떠야 한다.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  group('MissionIcon.resolveName', () {
    test('미션 코드가 주간이면 코드로 갈아 끼운다', () {
      // 일일 출석과 주간 출석은 iconKey 가 같게 온다. 한 주를 채운 것과 오늘
      // 하루 켠 것이 같은 그림이면 안 된다.
      expect(
        MissionIcon.resolveName(code: 'DAILY_ATTEND', iconKey: 'attendance'),
        'attendance',
      );
      expect(
        MissionIcon.resolveName(
          code: 'WEEKLY_ATTEND_5',
          iconKey: 'attendance',
        ),
        'streak',
      );
    });

    test('갈아 끼울 것이 없으면 iconKey 를 그대로 쓴다', () {
      expect(
        MissionIcon.resolveName(code: 'DAILY_SOMETHING_NEW', iconKey: 'review'),
        'review',
      );
    });

    test('둘 다 모르면 기본 그림으로 떨어진다', () {
      expect(
        MissionIcon.resolveName(code: '아직_없는_코드', iconKey: '아직_없는_키'),
        MissionIconKeys.fallback,
      );
      expect(MissionIcon.resolveName(), MissionIconKeys.fallback);
    });

    test('고른 그림이 실제로 있는 파일인지', () {
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
        final path = MissionIcon.resolveAsset(code: key);
        expect(File(path).existsSync(), isTrue,
            reason: '$key 가 가리키는 $path 가 없다');
      }
    });

    test('앱이 안다고 적어 둔 이름이 전부 파일로 있다', () {
      // 목록과 파일이 어긋나면 그 키가 올 때만 조용히 기본 그림이 뜬다.
      for (final name in MissionIconKeys.known) {
        final path = '${MissionIconKeys.assetDirectory}/$name.svg';
        expect(File(path).existsSync(), isTrue, reason: '$path 가 없다');
      }
    });

    test('갈아 끼우는 표가 가리키는 이름도 앱이 아는 것이다', () {
      for (final code in [
        'WEEKLY_ATTEND_5',
        'WEEKLY_NOTE_10',
        'WEEKLY_SET_3'
      ]) {
        expect(
          MissionIconKeys.known,
          contains(MissionIcon.resolveName(code: code)),
          reason: code,
        );
      }
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

      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('아는 키는 그 키의 그림 파일을 가리킨다', (tester) async {
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

      expect(
        MissionIcon.resolveAsset(iconKey: 'note_write'),
        'assets/MissionIcon/note_write.svg',
      );
      final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(picture.width, 30);
      expect(picture.height, 30);
    });
  });
}
