import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/StudyRoom/SharedProblemCommentModel.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('SharedProblemCommentModel.fromJson - 정상 응답 (중첩 reactions 포함)', () {
    test('모든 필드를 파싱한다', () {
      final json = {
        'commentId': 1,
        'content': '저도 이거 헷갈렸어요',
        'authorId': 10,
        'authorName': '기승민',
        'authorProfileImageUrl': 'https://cdn.test/p.png',
        'createdAt': '2026-01-01T09:00:00.000Z',
        'updatedAt': '2026-01-01T10:00:00.000Z',
        'isEdited': true,
        'isMine': true,
        'canDelete': true,
        'reactions': [
          {'emoji': '❤️', 'count': 1, 'reactedByMe': true},
        ],
      };

      final model = SharedProblemCommentModel.fromJson(json);

      expect(model.commentId, 1);
      expect(model.content, '저도 이거 헷갈렸어요');
      expect(model.authorId, 10);
      expect(model.authorName, '기승민');
      expect(model.authorProfileImageUrl, 'https://cdn.test/p.png');
      expect(model.createdAt, DateTime.parse('2026-01-01T09:00:00.000Z'));
      expect(model.updatedAt, DateTime.parse('2026-01-01T10:00:00.000Z'));
      expect(model.isEdited, isTrue);
      expect(model.isMine, isTrue);
      expect(model.canDelete, isTrue);
      expect(model.reactions, hasLength(1));
    });
  });

  group('SharedProblemCommentModel.fromJson - nullable / 키 누락', () {
    test('updatedAt, authorProfileImageUrl 이 null 이면 null 로 파싱된다', () {
      final model = SharedProblemCommentModel.fromJson({
        'commentId': 1,
        'content': '댓글',
        'authorId': 10,
        'authorName': '기승민',
        'createdAt': '2026-01-01T09:00:00.000Z',
        'updatedAt': null,
        'isEdited': false,
        'isMine': false,
        'canDelete': false,
      });

      expect(model.updatedAt, isNull);
      expect(model.authorProfileImageUrl, isNull);
    });

    test('reactions 키가 없으면 빈 리스트가 된다', () {
      final model = SharedProblemCommentModel.fromJson({
        'commentId': 1,
        'content': '댓글',
        'authorId': 10,
        'authorName': '기승민',
        'createdAt': '2026-01-01T09:00:00.000Z',
      });

      expect(model.reactions, isEmpty);
    });

    test('canDelete 키가 없어도 isMine 이 true 면 canDelete 는 true 다', () {
      final model = SharedProblemCommentModel.fromJson({
        'commentId': 1,
        'content': '댓글',
        'authorId': 10,
        'authorName': '기승민',
        'createdAt': '2026-01-01T09:00:00.000Z',
        'isMine': true,
      });

      expect(model.canDelete, isTrue);
    });

    test('authorProfileImageUrl 은 여러 대체 키 이름 중 하나만 있어도 채워진다', () {
      final model = SharedProblemCommentModel.fromJson({
        'commentId': 1,
        'content': '댓글',
        'authorId': 10,
        'authorName': '기승민',
        'createdAt': '2026-01-01T09:00:00.000Z',
        'userProfileImageUrl': 'https://cdn.test/fallback.png',
      });

      expect(model.authorProfileImageUrl, 'https://cdn.test/fallback.png');
    });

    test('authorName, content 키가 없으면 기본값으로 떨어진다', () {
      final model = SharedProblemCommentModel.fromJson({
        'commentId': 1,
        'authorId': 10,
        'createdAt': '2026-01-01T09:00:00.000Z',
      });

      expect(model.authorName, '알 수 없음');
      expect(model.content, '');
    });
  });
}
