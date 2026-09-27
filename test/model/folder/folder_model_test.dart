import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Folder/FolderModel.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('FolderModel.fromJson - 정상 응답', () {
    test('모든 필드가 채워진 응답을 파싱한다', () {
      final json = {
        'folderId': 10,
        'folderName': '수학',
        'parentFolder': {
          'folderId': 1,
          'folderName': '루트',
          'problemCount': 5,
        },
        'problemIdList': [1, 2, 3],
        'subFolderList': [
          {'folderId': 11, 'folderName': '미적분', 'problemCount': 2},
          {'folderId': 12, 'folderName': '기하', 'problemCount': 0},
        ],
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updateAt': '2026-02-01T12:30:00.000Z',
      };

      final model = FolderModel.fromJson(json);

      expect(model.folderId, 10);
      expect(model.folderName, '수학');
      expect(model.parentFolder?.folderId, 1);
      expect(model.parentFolder?.folderName, '루트');
      expect(model.problemIdList, [1, 2, 3]);
      expect(model.subFolderList, hasLength(2));
      expect(model.subFolderList[0].folderName, '미적분');
      expect(model.createdAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
      expect(model.updateAt, DateTime.parse('2026-02-01T12:30:00.000Z'));
    });
  });

  group('FolderModel.fromJson - nullable 필드', () {
    test('parentFolder 가 null 이면 null 로 파싱된다', () {
      final json = {
        'folderId': 1,
        'folderName': '루트',
        'parentFolder': null,
        'problemIdList': [],
        'subFolderList': [],
      };

      final model = FolderModel.fromJson(json);

      expect(model.parentFolder, isNull);
    });

    test('createdAt, updateAt 이 null 이면 null 로 파싱된다', () {
      final json = {
        'folderId': 1,
        'folderName': '루트',
        'problemIdList': [],
        'subFolderList': [],
        'createdAt': null,
        'updateAt': null,
      };

      final model = FolderModel.fromJson(json);

      expect(model.createdAt, isNull);
      expect(model.updateAt, isNull);
    });
  });

  group('FolderModel.fromJson - 키 누락', () {
    test('parentFolder 키가 아예 없으면 null 로 파싱된다', () {
      final json = {
        'folderId': 1,
        'folderName': '루트',
        'problemIdList': [],
        'subFolderList': [],
      };

      final model = FolderModel.fromJson(json);

      expect(model.parentFolder, isNull);
    });

    test('problemIdList 키가 없으면 빈 리스트가 된다', () {
      final json = {
        'folderId': 1,
        'folderName': '루트',
        'subFolderList': [],
      };

      final model = FolderModel.fromJson(json);

      expect(model.problemIdList, isEmpty);
    });

    test('subFolderList 키가 없으면 빈 리스트가 된다', () {
      final json = {
        'folderId': 1,
        'folderName': '루트',
        'problemIdList': [],
      };

      final model = FolderModel.fromJson(json);

      expect(model.subFolderList, isEmpty);
    });

    test('createdAt, updateAt 키가 아예 없으면 null 로 파싱된다', () {
      final json = {
        'folderId': 1,
        'folderName': '루트',
        'problemIdList': [],
        'subFolderList': [],
      };

      final model = FolderModel.fromJson(json);

      expect(model.createdAt, isNull);
      expect(model.updateAt, isNull);
    });
  });

  group('FolderModel.fromJson - 빈 배열', () {
    test('problemIdList, subFolderList 가 빈 배열이면 빈 리스트로 파싱된다', () {
      final json = {
        'folderId': 1,
        'folderName': '루트',
        'problemIdList': [],
        'subFolderList': [],
      };

      final model = FolderModel.fromJson(json);

      expect(model.problemIdList, isEmpty);
      expect(model.subFolderList, isEmpty);
    });
  });

  group('FolderModel.fromJson - 알려진 버그', () {
    test('folderId 키가 없어도 크래시하지 않아야 한다', () {
      // TODO(#174): 실제 버그. lib/Model/Folder/FolderModel.dart:42
      // `json['folderId'] as int` 는 folderId 키가 없거나 값이 null 이면
      // null 을 int 로 캐스팅하려다 TypeError 로 크래시한다.
      // FolderThumbnailModel 처럼 기본값으로 떨어지는 방어 코드가 없다.
      final json = {
        'folderName': '루트',
        'problemIdList': [],
        'subFolderList': [],
      };

      expect(() => FolderModel.fromJson(json), returnsNormally);
    }, skip: '#174 에서 수정 예정');

    test('folderName 키가 없어도 크래시하지 않아야 한다', () {
      // TODO(#174): 실제 버그. lib/Model/Folder/FolderModel.dart:43
      // `json['folderName'] as String` 도 마찬가지로 키가 없으면 TypeError 로 크래시한다.
      final json = {
        'folderId': 1,
        'problemIdList': [],
        'subFolderList': [],
      };

      expect(() => FolderModel.fromJson(json), returnsNormally);
    }, skip: '#174 에서 수정 예정');

    test('problemIdList 원소가 double 로 와도 크래시하지 않아야 한다', () {
      // TODO(#174): 실제 버그. lib/Model/Folder/FolderModel.dart:29
      // `problemIdDynamic.map((e) => e as int)` 는 원소가 double(예: 1.0) 이면
      // TypeError 로 크래시한다. 서버가 숫자를 JSON 부동소수점으로 내려줄 경우 재현된다.
      final json = {
        'folderId': 1,
        'folderName': '루트',
        'problemIdList': [1.0, 2.0],
        'subFolderList': [],
      };

      expect(() => FolderModel.fromJson(json), returnsNormally);
    }, skip: '#174 에서 수정 예정');
  });
}
