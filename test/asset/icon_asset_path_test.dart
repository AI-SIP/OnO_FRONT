// `assets/Icon/` 을 가리키는 코드의 경로가 실제 파일과 맞는지 잠근다.
//
// 그림 경로는 문자열이라 오타가 나도 컴파일이 통과한다. 드러나는 것은
// 그 화면을 켠 사람 앞에서다. `ClayIcon` 은 그림이 없으면 빨간 상자 대신
// 빈자리를 두므로 더더욱 조용히 사라진다. 그래서 여기서 잠근다.
//
// SVG 를 PNG 로 갈아 끼우면서 확장자만 남은 곳이 없는지도 이 테스트가 본다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/TemplateType.dart';
import 'package:ono/Module/Theme/NoteIconHandler.dart';

/// `lib/` 안의 모든 다트 파일에서 `assets/Icon/...` 을 뽑는다.
Set<String> _iconPathsInSource() {
  final pattern = RegExp(r'''assets/Icon/[A-Za-z0-9_]+\.(png|svg|webp)''');
  final paths = <String>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    paths.addAll(
      pattern.allMatches(entity.readAsStringSync()).map((m) => m.group(0)!),
    );
  }
  return paths;
}

void main() {
  test('lib 안에서 부르는 assets/Icon 경로가 전부 실제 파일이다', () {
    final paths = _iconPathsInSource();

    // 하나도 못 찾았으면 정규식이 썩은 것이다. 통과로 착각하면 안 된다.
    expect(paths, isNotEmpty);

    final missing = paths.where((p) => !File(p).existsSync()).toList()..sort();
    expect(missing, isEmpty, reason: '이 그림이 없다: $missing');
  });

  test('공책 돌림판 일곱 색이 전부 점토 PNG 다', () {
    expect(NoteIconHandler.noteIcons, hasLength(7));
    for (final path in NoteIconHandler.noteIcons) {
      expect(path, endsWith('.png'), reason: '$path 가 아직 SVG 다');
      expect(File(path).existsSync(), isTrue, reason: '$path 가 없다');
    }

    // 돌림판이 한 바퀴 돌아 처음으로 온다.
    expect(
      NoteIconHandler.getNoteIcon(7),
      NoteIconHandler.getNoteIcon(0),
    );
  });

  test('템플릿 세 가지의 그림이 전부 있다', () {
    for (final type in TemplateType.values) {
      for (final path in [
        type.templateThumbnailImage,
        type.templateDetailImage
      ]) {
        expect(path, endsWith('.png'), reason: '$path 가 아직 SVG 다');
        expect(File(path).existsSync(), isTrue, reason: '$path 가 없다');
      }
    }
  });

  test('남은 SVG 는 새로 그린 것이 없는 셋뿐이다', () {
    // 점토로 다시 그리지 않은 것들이다. 디자인에서 새 그림이 오면 이 목록이
    // 줄어야 하고, 그때 이 테스트가 알려 준다.
    final svgs = Directory('assets/Icon')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.svg'))
        .toList()
      ..sort();

    expect(svgs, [
      'EraserWithCircle.svg',
      'PencilWriting.svg',
      'noImage.svg',
    ]);
  });
}
