// 미션 색 테스트.
//
// 색은 장식이 아니라 정보다. 미션마다 오르는 능력치가 정해져 있고, 그 색은
// 마이페이지 활동별 레벨과 같아야 한다. 그래야 카드 색만 보고 "이건 복습
// 경험치구나"를 알 수 있다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/Mission/MissionPalette.dart';

void main() {
  group('kindOf', () {
    test('미션 코드로 오르는 능력치를 가른다', () {
      // 서버의 MissionMetric 이 세는 항목과 같은 갈래다.
      expect(
        MissionPalette.kindOf(code: 'DAILY_ATTEND'),
        MissionKind.attendance,
      );
      expect(
        MissionPalette.kindOf(code: 'DAILY_MOOD'),
        MissionKind.attendance,
        reason: '기분 남기기도 출석 경험치가 오른다',
      );
      expect(
        MissionPalette.kindOf(code: 'WEEKLY_ATTEND_5'),
        MissionKind.attendance,
      );
      expect(
        MissionPalette.kindOf(code: 'DAILY_NOTE_WRITE'),
        MissionKind.noteWrite,
      );
      expect(
        MissionPalette.kindOf(code: 'WEEKLY_NOTE_10'),
        MissionKind.noteWrite,
      );
      expect(
        MissionPalette.kindOf(code: 'DAILY_REVIEW_3'),
        MissionKind.problemPractice,
      );
      expect(
        MissionPalette.kindOf(code: 'DAILY_CORRECT_3'),
        MissionKind.problemPractice,
        reason: '정확하게도 문제 복습 경험치가 오른다',
      );
      expect(
        MissionPalette.kindOf(code: 'WEEKLY_REVIEW_30'),
        MissionKind.problemPractice,
      );
      expect(
        MissionPalette.kindOf(code: 'DAILY_PRACTICE_SET'),
        MissionKind.notePractice,
      );
      expect(
        MissionPalette.kindOf(code: 'WEEKLY_SET_3'),
        MissionKind.notePractice,
      );
    });

    test('갈래는 마이페이지 활동 네 가지와 폴백 하나뿐이다', () {
      expect(MissionKind.values, hasLength(5));
    });

    test('모르는 코드면 아이콘 키로 가른다', () {
      expect(
        MissionPalette.kindOf(code: 'DAILY_SOMETHING_NEW', iconKey: 'review'),
        MissionKind.problemPractice,
      );
    });

    test('능력치 이름을 말로도 준다', () {
      expect(MissionPalette.labelOf(code: 'DAILY_ATTEND'), '출석');
      expect(MissionPalette.labelOf(code: 'WEEKLY_NOTE_10'), '오답노트');
      expect(MissionPalette.labelOf(code: 'WEEKLY_REVIEW_30'), '문제 복습');
      expect(MissionPalette.labelOf(code: 'WEEKLY_SET_3'), '복습 세트');
      // 모르는 미션은 이름을 지어내지 않는다.
      expect(MissionPalette.labelOf(code: '없는코드'), '');
    });

    test('둘 다 모르면 중성색으로 떨어진다', () {
      expect(
        MissionPalette.kindOf(code: '없는코드', iconKey: '없는키'),
        MissionKind.etc,
      );
      expect(MissionPalette.kindOf(), MissionKind.etc);
    });
  });

  group('색', () {
    test('갈래마다 다른 색을 준다', () {
      final accents = MissionKind.values
          .map((kind) => MissionPalette.of(kind).accent.toARGB32())
          .toSet();

      expect(
        accents.length,
        MissionKind.values.length,
        reason: '갈래가 같은 색을 쓰면 나눈 뜻이 없다',
      );
    });

    test('바탕과 강조가 서로 다른 색이다', () {
      // 같으면 아이콘이 타일에 묻힌다.
      for (final kind in MissionKind.values) {
        final colors = MissionPalette.of(kind);
        expect(
          colors.surface.toARGB32(),
          isNot(colors.accent.toARGB32()),
          reason: '$kind 의 바탕과 아이콘이 같은 색이다',
        );
      }
    });

    test('타일 바탕은 옅고 아이콘은 진하다', () {
      // 바탕이 진하면 아이콘이 묻히고, 목록 전체가 촌스러워진다.
      for (final kind in MissionKind.values) {
        final colors = MissionPalette.of(kind);
        expect(
          colors.surface.computeLuminance(),
          greaterThan(colors.accent.computeLuminance()),
          reason: '$kind 의 바탕이 아이콘보다 어둡다',
        );
        expect(colors.surface.computeLuminance(), greaterThan(0.8));
      }
    });

    test('강조색이 탁하지 않다', () {
      // 회색 섞인 중간톤은 앱의 흰 바탕과 부드러운 초록 옆에서 답답해 보인다.
      // 채도를 낮추는 대신 명도를 올린 파스텔이어야 한다.
      for (final kind in MissionKind.values) {
        if (kind == MissionKind.etc) continue;
        final accent = HSLColor.fromColor(MissionPalette.of(kind).accent);
        expect(
          accent.lightness,
          greaterThan(0.55),
          reason: '$kind 의 강조색이 어둡다',
        );
        expect(
          accent.saturation,
          greaterThan(0.35),
          reason: '$kind 의 강조색이 탁하다',
        );
      }
    });

    test('마이페이지 활동 색과 같은 색을 쓴다', () {
      // 두 화면이 같은 것을 다른 색으로 부르면 색이 정보를 잃는다.
      expect(
          MissionPalette.of(MissionKind.attendance).accent, Colors.pink[300]);
      expect(
          MissionPalette.of(MissionKind.noteWrite).accent, Colors.purple[300]);
      expect(
        MissionPalette.of(MissionKind.problemPractice).accent,
        Colors.green[400],
      );
      expect(
          MissionPalette.of(MissionKind.notePractice).accent, Colors.blue[300]);
    });
  });
}
