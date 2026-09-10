// 미션 갈래 색 테스트.
//
// 목록이 흰 카드에 같은 색 아이콘 타일만 반복되면 무엇이 무슨 미션인지
// 눈으로 갈리지 않는다. 갈래마다 색이 달라야 하고, 서버가 모르는 미션을
// 내려도 색이 없어서 빈칸이 되면 안 된다.
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/Mission/MissionPalette.dart';

void main() {
  group('kindOf', () {
    test('미션 코드로 갈래를 가른다', () {
      expect(
        MissionPalette.kindOf(code: 'DAILY_NOTE_WRITE'),
        MissionKind.record,
      );
      expect(MissionPalette.kindOf(code: 'DAILY_REVIEW_3'), MissionKind.review);
      expect(
        MissionPalette.kindOf(code: 'DAILY_CORRECT_3'),
        MissionKind.accuracy,
      );
      expect(
        MissionPalette.kindOf(code: 'WEEKLY_ATTEND_5'),
        MissionKind.attendance,
      );
      expect(
        MissionPalette.kindOf(code: 'WEEKLY_SET_3'),
        MissionKind.practiceSet,
      );
    });

    test('모르는 코드면 아이콘 키로 가른다', () {
      expect(
        MissionPalette.kindOf(code: 'DAILY_SOMETHING_NEW', iconKey: 'review'),
        MissionKind.review,
      );
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

    test('모든 갈래에 색이 있다', () {
      for (final kind in MissionKind.values) {
        expect(MissionPalette.of(kind).surface, isNotNull);
        expect(MissionPalette.of(kind).accent, isNotNull);
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
  });
}
