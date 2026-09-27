import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Folder/FolderThumbnailModel.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('FolderThumbnailModel.fromJson - 정상 응답', () {
    test('모든 필드가 채워진 응답을 파싱한다', () {
      final json = {
        'folderId': 3,
        'folderName': '영어',
        'problemCount': 7,
      };

      final model = FolderThumbnailModel.fromJson(json);

      expect(model.folderId, 3);
      expect(model.folderName, '영어');
      expect(model.problemCount, 7);
    });
  });

  group('FolderThumbnailModel.fromJson - problemCount 방어 파싱', () {
    test('problemCount 가 null 이면 0 이 된다', () {
      final json = {
        'folderId': 3,
        'folderName': '영어',
        'problemCount': null,
      };

      final model = FolderThumbnailModel.fromJson(json);

      expect(model.problemCount, 0);
    });

    test('problemCount 키가 아예 없으면 0 이 된다', () {
      final json = {
        'folderId': 3,
        'folderName': '영어',
      };

      final model = FolderThumbnailModel.fromJson(json);

      expect(model.problemCount, 0);
    });

    test('problemCount 가 double 로 와도 int 로 변환된다', () {
      final json = {
        'folderId': 3,
        'folderName': '영어',
        'problemCount': 7.0,
      };

      final model = FolderThumbnailModel.fromJson(json);

      expect(model.problemCount, 7);
    });

    test('problemCount 가 숫자 형태의 String 으로 와도 int 로 변환된다', () {
      final json = {
        'folderId': 3,
        'folderName': '영어',
        'problemCount': '9',
      };

      final model = FolderThumbnailModel.fromJson(json);

      expect(model.problemCount, 9);
    });

    test('problemCount 가 파싱 불가능한 String 이면 0 으로 떨어진다', () {
      final json = {
        'folderId': 3,
        'folderName': '영어',
        'problemCount': 'abc',
      };

      final model = FolderThumbnailModel.fromJson(json);

      expect(model.problemCount, 0);
    });
  });

  group('FolderThumbnailModel.toJson', () {
    test('서버가 받는 키 이름과 정확히 일치하고 round-trip 된다', () {
      final model = FolderThumbnailModel(
        folderId: 5,
        folderName: '과학',
        problemCount: 4,
      );

      final json = model.toJson();

      expect(json, {
        'folderId': 5,
        'folderName': '과학',
        'problemCount': 4,
      });

      final roundTripped = FolderThumbnailModel.fromJson(json);
      expect(roundTripped.folderId, model.folderId);
      expect(roundTripped.folderName, model.folderName);
      expect(roundTripped.problemCount, model.problemCount);
    });
  });
}
