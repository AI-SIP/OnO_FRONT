// 테스트 공용 SecureStorage 스텁.
//
// TokenProvider 와 UserProvider 는 `const FlutterSecureStorage()` 를 필드로 직접
// 들고 있어 생성자로 주입할 수 없다. 단위 테스트 환경(flutter tester)에는 플랫폼
// 채널 구현체가 없어 그냥 두면 모든 read/write/delete 가
// `MissingPluginException` 을 던진다.
//
// flutter_secure_storage 패키지가 테스트용으로 `TestFlutterSecureStoragePlatform`
// 을 함께 배포하므로 그걸로 `FlutterSecureStoragePlatform.instance` 를 바꿔치기한다.

import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

/// 메모리 기반 가짜 SecureStorage 로 플랫폼 델리게이트를 바꿔치운다.
/// 반환된 맵을 직접 들여다보거나 채워 넣어 테스트 시나리오를 구성할 수 있다.
Map<String, String> stubSecureStorage({Map<String, String>? initialData}) {
  final data = initialData ?? <String, String>{};
  FlutterSecureStoragePlatform.instance =
      TestFlutterSecureStoragePlatform(data);
  return data;
}
