import 'dart:io';

import 'package:camera/camera.dart' show XFile;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Service/Api/FileUpload/FileUploadService.dart';
import 'package:ono/Service/Api/Problem/ProblemService.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'e2e_app.dart';

/// 로그인한 계정의 책장에 오답노트를 [references] 개수만큼 넣는다.
///
/// 오답노트 등록 화면은 사진이 필수라, 사진 선택(OS 화면)을 거치지 않고는 UI 로
/// 만들 수 없다. 복습 동선을 보는 테스트는 등록이 관심사가 아니므로 앱의 서비스
/// 클래스를 그대로 불러 서버에 직접 넣는다. 로그인 토큰도 앱이 저장한 것을 쓴다.
///
/// 사진은 앱에 들어 있는 훈장 그림 한 장을 올린다. dev 서버의 S3 에 실제로 올라간다.
Future<void> seedProblems(
  WidgetTester tester, {
  required List<String> references,
}) async {
  final context = tester.element(find.byType(MaterialApp).first);
  final foldersProvider = Provider.of<FoldersProvider>(context, listen: false);
  final rootFolderId = foldersProvider.rootFolder?.folderId;
  if (rootFolderId == null) {
    throw TestFailure('책장(루트 폴더)을 아직 못 받았다. 로그인 뒤에 불러야 한다.');
  }

  final bytes = await rootBundle.load('assets/Medal/first_step.png');
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/e2e_problem.png');
  await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

  final imageUrl = await FileUploadService().uploadImageFile(XFile(file.path));
  final problemService = ProblemService();
  for (final reference in references) {
    await problemService.registerProblemV2(
      reference: reference,
      folderId: rootFolderId,
      // 등록 화면은 늘 푼 날짜를 채워 보낸다. 비워 두면 문제 상세 화면이
      // solvedAt! 에서 멈추는데, 앱에서는 생길 수 없는 데이터라 화면 탓이 아니다.
      solvedAt: DateTime.now(),
      problemImageUrls: [imageUrl],
      answerImageUrls: const [],
    );
  }

  await foldersProvider.refreshFolder(rootFolderId);
  await pumpFor(tester, const Duration(milliseconds: 500));
}
