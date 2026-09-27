// lib/Util/SentryEnvironment.dart 검증.
//
// 단계적 출시를 멈출지는 Sentry 에서 운영 사용자 에러만 걸러 보고 정한다.
// 개발 서버 빌드나 로컬 디버그 실행이 production 으로 섞이면 그 판단이
// 틀어지므로, 빌드 모드와 ENV 조합마다 어떤 이름이 나가는지를 잠근다.
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Util/SentryEnvironment.dart';

void main() {
  String resolve(
    String appEnv, {
    bool release = false,
    bool profile = false,
  }) =>
      SentryEnvironment.resolve(
        appEnv: appEnv,
        isReleaseMode: release,
        isProfileMode: profile,
      );

  group('릴리즈 빌드', () {
    test('ENV=prod 는 기존 필터가 안 깨지게 production 으로 보낸다', () {
      expect(resolve('prod', release: true), 'production');
    });

    test('ENV=dev 는 운영과 섞이지 않게 dev 로 보낸다', () {
      expect(resolve('dev', release: true), 'dev');
    });

    test('ENV=local 은 local 로 보낸다', () {
      expect(resolve('local', release: true), 'local');
    });

    test('ENV 가 비어 있으면 AppConfig 기본값과 같은 local 로 본다', () {
      expect(resolve('', release: true), 'local');
    });

    test('모르는 ENV 는 그대로 보내서 오타가 드러나게 한다', () {
      expect(resolve('prd', release: true), 'prd');
    });
  });

  group('디버그 실행', () {
    for (final appEnv in ['prod', 'dev', 'local']) {
      test('ENV=$appEnv 여도 debug 로 보낸다', () {
        expect(resolve(appEnv), 'debug');
      });
    }
  });

  test('프로파일 빌드는 ENV 와 상관없이 profile 로 보낸다', () {
    expect(resolve('prod', profile: true), 'profile');
  });
}
