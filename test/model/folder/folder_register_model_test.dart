import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Folder/FolderRegisterModel.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('FolderRegisterModel.toJson', () {
    test('모든 필드가 채워진 요청 바디를 만든다', () {
      final model = FolderRegisterModel(
        folderName: '새 폴더',
        folderId: 1,
        parentFolderId: 2,
      );

      expect(model.toJson(), {
        'folderName': '새 폴더',
        'folderId': 1,
        'parentFolderId': 2,
      });
    });

    test('folderId 가 없는 신규 생성 요청도 키 자체는 유지한 채 null 로 보낸다', () {
      final model = FolderRegisterModel(
        folderName: '새 폴더',
        parentFolderId: null,
      );

      expect(model.toJson(), {
        'folderName': '새 폴더',
        'folderId': null,
        'parentFolderId': null,
      });
    });

    test('folderName 이 null 이어도 키는 유지된다', () {
      final model = FolderRegisterModel(
        folderName: null,
        parentFolderId: 1,
      );

      expect(model.toJson(), {
        'folderName': null,
        'folderId': null,
        'parentFolderId': 1,
      });
    });
  });
}
