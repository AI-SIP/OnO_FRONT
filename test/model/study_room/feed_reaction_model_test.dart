import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/StudyRoom/FeedReactionModel.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('FeedReactionModel.fromJson - 정상 응답', () {
    test('모든 필드가 채워진 응답을 파싱한다', () {
      final json = {
        'emoji': '👍',
        'count': 3,
        'reactedByMe': true,
      };

      final model = FeedReactionModel.fromJson(json);

      expect(model.emoji, '👍');
      expect(model.count, 3);
      expect(model.reactedByMe, isTrue);
    });

    test('count 가 double 로 와도 int 로 변환된다', () {
      final model = FeedReactionModel.fromJson({
        'emoji': '👍',
        'count': 3.0,
        'reactedByMe': false,
      });

      expect(model.count, 3);
    });
  });

  group('FeedReactionModel.fromJson - 키 누락 시 기본값', () {
    test('키가 모두 없으면 emoji 빈 문자열, count 0, reactedByMe false 로 떨어진다', () {
      final model = FeedReactionModel.fromJson({});

      expect(model.emoji, '');
      expect(model.count, 0);
      expect(model.reactedByMe, isFalse);
    });

    test('reactedByMe 가 true 가 아닌 다른 truthy 값이면 false 로 처리된다', () {
      final model = FeedReactionModel.fromJson({
        'emoji': '👍',
        'count': 1,
        'reactedByMe': 'true',
      });

      expect(model.reactedByMe, isFalse);
    });
  });
}
