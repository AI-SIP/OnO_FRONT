import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Config/AppConfig.dart';

/// 모든 테스트 파일의 main() 맨 앞에서 한 번 부른다.
///
/// Service 들은 필드 초기화 시점에 [AppConfig.baseUrl] 을 읽기 때문에,
/// 이걸 부르지 않으면 Service 를 생성하는 것만으로 LateInitializationError 가 난다.
///
/// ```dart
/// void main() {
///   setUpOnoTest();
///
///   group('ProblemService', () { ... });
/// }
/// ```
void setUpOnoTest() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppConfig.loadForTest();
}

/// 테스트에서 쓰는 API 기본 주소. [AppConfig.loadForTest] 의 기본값과 같다.
/// URL 검증에서 문자열을 직접 쓰지 말고 이걸 쓴다.
const String testBaseUrl = 'https://test.ono.local';
