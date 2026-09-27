// 기간 키를 사람이 읽는 말로 바꾸는 규칙을 잠근다.
//
// 지난 미션 목록은 여러 기간이 섞여 오기 때문에 줄마다 어느 때 것인지가
// 보여야 한다. 서버 키를 그대로 보여 주면(`2026-W36`) 아무도 못 읽는다.
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/Mission/MissionPeriodLabel.dart';

void main() {
  // 2026-09-09 는 수요일이다. 그 주는 2026-W37.
  final now = DateTime(2026, 9, 9);

  group('일일 키', () {
    test('어제 것은 어제라고 한다', () {
      expect(MissionPeriodLabel.of('2026-09-08', now: now), '어제');
    });

    test('더 지난 것은 날짜로 말한다', () {
      expect(MissionPeriodLabel.of('2026-09-03', now: now), '9월 3일');
      expect(MissionPeriodLabel.of('2025-12-31', now: now), '12월 31일');
    });

    test('오늘 것은 오늘이라고 한다', () {
      expect(MissionPeriodLabel.of('2026-09-09', now: now), '오늘');
    });
  });

  group('주간 키', () {
    test('바로 지난주는 지난주라고 한다', () {
      expect(MissionPeriodLabel.of('2026-W36', now: now), '지난주');
    });

    test('더 지난 주는 몇 주 전인지 말한다', () {
      expect(MissionPeriodLabel.of('2026-W34', now: now), '3주 전');
    });

    test('이번 주 것은 이번 주라고 한다', () {
      expect(MissionPeriodLabel.of('2026-W37', now: now), '이번 주');
    });
  });

  group('읽지 못하는 키', () {
    test('null 이나 빈 값이면 기본 문구다', () {
      expect(MissionPeriodLabel.of(null), MissionPeriodLabel.unknown);
      expect(MissionPeriodLabel.of(''), MissionPeriodLabel.unknown);
      expect(MissionPeriodLabel.of('   '), MissionPeriodLabel.unknown);
    });

    test('모양이 다르거나 말이 안 되는 키여도 던지지 않는다', () {
      for (final key in [
        '2026',
        '2026-13-01',
        '2026-02-31',
        '2026-W99',
        'W36',
        '지난주',
      ]) {
        expect(
          MissionPeriodLabel.of(key, now: now),
          MissionPeriodLabel.unknown,
          reason: '$key 를 읽지 못하면 기본 문구로 떨어져야 한다',
        );
      }
    });
  });
}
