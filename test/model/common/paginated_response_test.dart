import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Common/PaginatedResponse.dart';

// 테스트용 원소 타입. content 안의 fromJsonT 콜백 동작을 확인하기 위해 쓴다.
class _Item {
  final int id;
  _Item(this.id);
  factory _Item.fromJson(Map<String, dynamic> json) => _Item(json['id'] as int);
}

void main() {
  group('PaginatedResponse.fromJson', () {
    test('data 래퍼가 있는 응답을 파싱한다', () {
      final response = PaginatedResponse<_Item>.fromJson(
        {
          'errorCode': null,
          'message': null,
          'data': {
            'content': [
              {'id': 1},
              {'id': 2},
            ],
            'nextCursor': 3,
            'hasNext': true,
            'size': 2,
          },
        },
        (json) => _Item.fromJson(json),
      );

      expect(response.content.map((e) => e.id), [1, 2]);
      expect(response.nextCursor, 3);
      expect(response.hasNext, isTrue);
      expect(response.size, 2);
    });

    test('data 래퍼가 없는 응답(최상위가 바로 데이터)도 파싱한다', () {
      final response = PaginatedResponse<_Item>.fromJson(
        {
          'content': [
            {'id': 5},
          ],
          'nextCursor': null,
          'hasNext': false,
          'size': 1,
        },
        (json) => _Item.fromJson(json),
      );

      expect(response.content.map((e) => e.id), [5]);
      expect(response.nextCursor, isNull);
      expect(response.hasNext, isFalse);
    });

    test('content 가 빈 배열이면 빈 리스트로 파싱된다', () {
      final response = PaginatedResponse<_Item>.fromJson(
        {
          'content': <Map<String, dynamic>>[],
          'nextCursor': null,
          'hasNext': false,
          'size': 0
        },
        (json) => _Item.fromJson(json),
      );

      expect(response.content, isEmpty);
    });

    test('content 키가 아예 없으면 예외가 난다 (필드가 non-nullable 이라 의도된 동작)', () {
      expect(
        () => PaginatedResponse<_Item>.fromJson(
          {'nextCursor': null, 'hasNext': false, 'size': 0},
          (json) => _Item.fromJson(json),
        ),
        throwsA(isA<TypeError>()),
      );
    });

    test(
      'size 가 double(2.0)로 오면 예외가 난다',
      () {
        // TODO(#174): 실제 버그. lib/Model/Common/PaginatedResponse.dart:28 에서
        // size: dataMap['size'] as int 로, num 이 아닌 int 로만 캐스팅한다.
        // 서버가 2.0 같은 double 을 내려주면 TypeError 로 죽는다.
        expect(
          () => PaginatedResponse<_Item>.fromJson(
            {
              'content': <Map<String, dynamic>>[],
              'nextCursor': null,
              'hasNext': false,
              'size': 2.0,
            },
            (json) => _Item.fromJson(json),
          ),
          throwsA(isA<TypeError>()),
        );
      },
      skip: '#174 에서 수정 예정',
    );

    test(
      'nextCursor 가 double(3.0)로 오면 예외가 난다',
      () {
        // TODO(#174): 실제 버그. lib/Model/Common/PaginatedResponse.dart:26 에서
        // nextCursor: dataMap['nextCursor'] as int? 로, num 이 아닌 int? 로만
        // 캐스팅한다. 서버가 3.0 같은 double 을 내려주면 TypeError 로 죽는다.
        expect(
          () => PaginatedResponse<_Item>.fromJson(
            {
              'content': <Map<String, dynamic>>[],
              'nextCursor': 3.0,
              'hasNext': true,
              'size': 0,
            },
            (json) => _Item.fromJson(json),
          ),
          throwsA(isA<TypeError>()),
        );
      },
      skip: '#174 에서 수정 예정',
    );
  });

  group('PaginatedResponse.isLastPage', () {
    test('hasNext 가 false 면 nextCursor 와 무관하게 마지막 페이지다', () {
      final response = PaginatedResponse<_Item>(
        content: const [],
        nextCursor: 5,
        hasNext: false,
        size: 0,
      );

      expect(response.isLastPage, isTrue);
    });

    test('hasNext 가 true 이고 nextCursor 가 있으면 마지막 페이지가 아니다', () {
      final response = PaginatedResponse<_Item>(
        content: const [],
        nextCursor: 5,
        hasNext: true,
        size: 10,
      );

      expect(response.isLastPage, isFalse);
    });

    test('hasNext 가 true 인데 nextCursor 가 null 이면 그래도 마지막 페이지로 취급된다', () {
      // hasNext 와 nextCursor 가 서로 모순된 응답이 와도 nextCursor == null 쪽이
      // 우선한다 (더 이상 커서로 다음 페이지를 요청할 수 없기 때문).
      final response = PaginatedResponse<_Item>(
        content: const [],
        nextCursor: null,
        hasNext: true,
        size: 10,
      );

      expect(response.isLastPage, isTrue);
    });
  });
}
