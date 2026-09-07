import 'dart:convert';
import 'dart:io';

/// `test/fixtures/` 아래의 JSON 파일을 읽는다.
///
/// ```dart
/// final json = loadJsonFixture('problem/problem_full.json');
/// final model = ProblemModel.fromJson(json);
/// ```
///
/// 백엔드 응답을 그대로 떠 온 것을 픽스처로 두면, 응답 모양이 바뀌었을 때
/// 어느 필드가 달라졌는지 diff 로 바로 보인다.
Map<String, dynamic> loadJsonFixture(String relativePath) {
  return jsonDecode(readFixture(relativePath)) as Map<String, dynamic>;
}

/// 최상위가 배열인 픽스처를 읽는다.
List<dynamic> loadJsonListFixture(String relativePath) {
  return jsonDecode(readFixture(relativePath)) as List<dynamic>;
}

/// 픽스처 파일의 원본 문자열.
String readFixture(String relativePath) {
  final file = File('test/fixtures/$relativePath');
  if (!file.existsSync()) {
    throw ArgumentError('픽스처를 찾을 수 없다: ${file.path}');
  }
  return file.readAsStringSync();
}
