import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/PracticeNote/PracticeNotificationModel.dart';
import 'package:ono/Model/PracticeNote/RepeatType.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('PracticeNotificationModel.fromJson - 정상 응답', () {
    test('모든 필드가 채워진 응답을 파싱한다', () {
      final json = {
        'intervalDays': 3,
        'hour': 21,
        'minute': 15,
        'repeatType': 'weekly',
        'weekDays': [1, 2, 3],
      };

      final model = PracticeNotificationModel.fromJson(json);

      expect(model.intervalDays, 3);
      expect(model.hour, 21);
      expect(model.minute, 15);
      expect(model.repeatType, RepeatType.weekly);
      expect(model.weekDays, [1, 2, 3]);
    });
  });

  group('PracticeNotificationModel.fromJson - 키 누락 시 기본값', () {
    test('intervalDays, hour, minute 키가 없으면 각각 7, 18, 0 으로 떨어진다', () {
      final model = PracticeNotificationModel.fromJson({});

      expect(model.intervalDays, 7);
      expect(model.hour, 18);
      expect(model.minute, 0);
    });

    test('repeatType 키가 없으면 daily 로 떨어진다', () {
      final model = PracticeNotificationModel.fromJson({});

      expect(model.repeatType, RepeatType.daily);
    });

    test('weekDays 키가 없으면 null 로 파싱된다', () {
      final model = PracticeNotificationModel.fromJson({});

      expect(model.weekDays, isNull);
    });
  });

  group('PracticeNotificationModel.fromJson - repeatType 매핑', () {
    test('서버가 모르는 repeatType 문자열이 오면 daily 로 대체된다', () {
      final model = PracticeNotificationModel.fromJson({
        'repeatType': 'monthly',
      });

      expect(model.repeatType, RepeatType.daily);
    });

    test('repeatType 이 문자열이 아니면 daily 로 대체된다', () {
      final model = PracticeNotificationModel.fromJson({
        'repeatType': 1,
      });

      expect(model.repeatType, RepeatType.daily);
    });
  });

  group('PracticeNotificationModel.fromJson - 알려진 버그', () {
    test('hour, minute, intervalDays 가 double 로 와도 크래시하지 않아야 한다', () {
      // TODO(#174): 실제 버그. lib/Model/PracticeNote/PracticeNotificationModel.dart:30-32
      // `json['hour'] ?? 18` 등은 타입 변환이 없어서, 서버가 18.0 처럼 double 을 내려주면
      // nullable 이긴 하지만 실제로는 int? 필드에 double 이 대입되어 TypeError 로 크래시한다.
      final json = {
        'intervalDays': 3.0,
        'hour': 21.0,
        'minute': 15.0,
      };

      expect(() => PracticeNotificationModel.fromJson(json), returnsNormally);
    }, skip: '#174 에서 수정 예정');

    test('weekDays 원소가 double 로 와도 크래시하지 않아야 한다', () {
      // TODO(#174): 실제 버그. lib/Model/PracticeNote/PracticeNotificationModel.dart:40
      // `(json['weekDays'] as List<dynamic>?)?.map((e) => e as int)` 는
      // 원소가 double 이면 TypeError 로 크래시한다.
      final json = {
        'weekDays': [1.0, 3.0],
      };

      expect(() => PracticeNotificationModel.fromJson(json), returnsNormally);
    }, skip: '#174 에서 수정 예정');
  });

  group('PracticeNotificationModel.toJson', () {
    test('서버가 받는 키 이름과 정확히 일치하고 round-trip 된다', () {
      final model = PracticeNotificationModel(
        intervalDays: 7,
        hour: 20,
        minute: 0,
        repeatType: RepeatType.weekly,
        weekDays: const [1, 4],
      );

      final json = model.toJson();

      expect(json, {
        'intervalDays': 7,
        'hour': 20,
        'minute': 0,
        'repeatType': 'weekly',
        'weekDays': [1, 4],
      });

      final roundTripped = PracticeNotificationModel.fromJson(json);
      expect(roundTripped.intervalDays, model.intervalDays);
      expect(roundTripped.hour, model.hour);
      expect(roundTripped.minute, model.minute);
      expect(roundTripped.repeatType, model.repeatType);
      expect(roundTripped.weekDays, model.weekDays);
    });

    test('repeatType 이 null 이면 toJson 의 repeatType 도 null 이다', () {
      final model = PracticeNotificationModel();

      expect(model.toJson()['repeatType'], isNull);
    });
  });
}
