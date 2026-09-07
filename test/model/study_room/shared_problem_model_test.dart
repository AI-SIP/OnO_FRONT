import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/StudyRoom/SharedProblemModel.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('SharedProblemModel.fromJson - 정상 응답 (중첩 reactions 포함)', () {
    test('모든 필드를 파싱한다', () {
      final json = {
        'sharedProblemId': 1,
        'sharedByUserId': 10,
        'sharedByName': '기승민',
        'sharedByProfileImageUrl': 'https://cdn.test/p.png',
        'problemId': 55,
        'problemImageUrls': [
          'https://cdn.test/1.png',
          'https://cdn.test/2.png'
        ],
        'reference': '수학 3단원',
        'comment': '이거 어렵네요',
        'commentCount': 2,
        'sharedAt': '2026-01-01T09:00:00.000Z',
        'reactions': [
          {'emoji': '👍', 'count': 1, 'reactedByMe': false},
        ],
      };

      final model = SharedProblemModel.fromJson(json);

      expect(model.sharedProblemId, 1);
      expect(model.sharedByUserId, 10);
      expect(model.sharedByName, '기승민');
      expect(model.sharedByProfileImageUrl, 'https://cdn.test/p.png');
      expect(model.problemId, 55);
      expect(model.problemImageUrls, hasLength(2));
      expect(model.reference, '수학 3단원');
      expect(model.comment, '이거 어렵네요');
      expect(model.commentCount, 2);
      expect(model.sharedAt, DateTime.parse('2026-01-01T09:00:00.000Z'));
      expect(model.reactions, hasLength(1));
    });
  });

  group('SharedProblemModel.fromJson - nullable / 키 누락', () {
    test('problemId, comment, commentCount, 프로필 이미지가 null 이면 null 로 파싱된다', () {
      final model = SharedProblemModel.fromJson({
        'sharedProblemId': 1,
        'sharedByUserId': 10,
        'sharedByName': '기승민',
        'problemId': null,
        'problemImageUrls': [],
        'comment': null,
        'commentCount': null,
        'sharedAt': '2026-01-01T09:00:00.000Z',
      });

      expect(model.problemId, isNull);
      expect(model.comment, isNull);
      expect(model.commentCount, isNull);
      expect(model.sharedByProfileImageUrl, isNull);
    });

    test('problemImageUrls, reactions 키가 없으면 빈 리스트가 된다', () {
      final model = SharedProblemModel.fromJson({
        'sharedProblemId': 1,
        'sharedByUserId': 10,
        'sharedByName': '기승민',
        'sharedAt': '2026-01-01T09:00:00.000Z',
      });

      expect(model.problemImageUrls, isEmpty);
      expect(model.reactions, isEmpty);
    });

    test('sharedByName, reference 키가 없으면 기본값으로 떨어진다', () {
      final model = SharedProblemModel.fromJson({
        'sharedProblemId': 1,
        'sharedByUserId': 10,
        'sharedAt': '2026-01-01T09:00:00.000Z',
      });

      expect(model.sharedByName, '알 수 없음');
      expect(model.reference, '공유 문제');
    });

    test('sharedByProfileImageUrl 은 여러 대체 키 이름 중 하나만 있어도 채워진다', () {
      final model = SharedProblemModel.fromJson({
        'sharedProblemId': 1,
        'sharedByUserId': 10,
        'sharedByName': '기승민',
        'sharedAt': '2026-01-01T09:00:00.000Z',
        'profileImageUrl': 'https://cdn.test/fallback.png',
      });

      expect(model.sharedByProfileImageUrl, 'https://cdn.test/fallback.png');
    });

    test('problemId, commentCount 가 double 로 와도 int 로 변환된다', () {
      final model = SharedProblemModel.fromJson({
        'sharedProblemId': 1,
        'sharedByUserId': 10,
        'sharedByName': '기승민',
        'problemId': 55.0,
        'commentCount': 2.0,
        'sharedAt': '2026-01-01T09:00:00.000Z',
      });

      expect(model.problemId, 55);
      expect(model.commentCount, 2);
    });
  });
}
