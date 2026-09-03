// TokenProvider 상태 전이 테스트 (가능한 범위만).
//
// TokenProvider 는 `const FlutterSecureStorage()` 를 필드로 직접 들고 있어
// 생성자로 주입할 수 없다. flutter_secure_storage 가 테스트용으로 제공하는
// `TestFlutterSecureStoragePlatform` 으로 플랫폼 델리게이트를 바꿔치워
// 저장소 자체는 테스트할 수 있다(support/secure_storage_stub.dart).
//
// 하지만 `refreshAccessToken()` / `_refreshAccessTokenInternal()` 은
// `package:http` 의 top-level `http.post` 를 직접 호출하고 HttpService 처럼
// Client 를 주입받지 않는다. 그래서 "액세스 토큰이 없거나 곧 만료될 때
// 자동으로 갱신하는" 경로는 실제 네트워크 호출 없이는 단위 테스트로 격리할 수
// 없다 — 진짜 서버로 요청이 나가거나(느리고 외부 의존적), 존재하지 않는
// 호스트로 실패하는 것을 관찰하는 수밖에 없는데 둘 다 이 테스트 스위트의
// 목적(빠르고 결정적인 단위 테스트)에 맞지 않아 제외했다. 아래는 네트워크를
// 타지 않는 경로만 검증한다.
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Provider/TokenProvider.dart';

import '../helpers/helpers.dart';
import 'support/secure_storage_stub.dart';

/// SecureStorage 가 복호화 실패(BAD_DECRYPT)로 깨진 상황을 흉내내는 가짜 플랫폼.
class _CorruptedSecureStoragePlatform extends FlutterSecureStoragePlatform {
  final List<String> deletedKeys = [];

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async {
    throw PlatformException(
      code: 'Exception encountered',
      message: 'read',
      details: 'javax.crypto.BadPaddingException: ...BAD_DECRYPT...',
    );
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {}

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async =>
      false;

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    deletedKeys.add(key);
  }

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async =>
      {};

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {}
}

String _fakeJwt({required int expiresInSeconds}) {
  String encodePart(Map<String, dynamic> part) {
    return base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', '');
  }

  final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresInSeconds;
  final header = encodePart({'alg': 'none', 'typ': 'JWT'});
  final payload = encodePart({'exp': exp});
  return '$header.$payload.signature';
}

void main() {
  setUpOnoTest();

  late Map<String, String> storageData;
  late TokenProvider tokenProvider;

  setUp(() {
    storageData = stubSecureStorage();
    tokenProvider = TokenProvider();
  });

  group('토큰 저장/조회/삭제 (네트워크 없이)', () {
    test('setRefreshToken 후 getRefreshToken 이 그대로 돌려준다', () async {
      await tokenProvider.setRefreshToken('refresh-abc');

      expect(await tokenProvider.getRefreshToken(), 'refresh-abc');
    });

    test('만료가 임박하지 않은 액세스 토큰은 네트워크 없이 그대로 반환된다', () async {
      final validToken = _fakeJwt(expiresInSeconds: 3600); // 1시간 뒤 만료
      await tokenProvider.setAccessToken(validToken);

      expect(await tokenProvider.getAccessToken(), validToken);
    });

    test('deleteToken 은 access/refresh 토큰을 저장소에서 실제로 지운다', () async {
      await tokenProvider.setAccessToken('a');
      await tokenProvider.setRefreshToken('r');

      await tokenProvider.deleteToken();

      // getAccessToken()/getRefreshToken() 은 토큰이 없으면 자동 갱신을
      // 시도하다 refreshToken 도 없어 UnauthorizedException 을 던지므로,
      // 여기서는 "삭제가 저장소에 실제로 반영됐는지"를 직접 확인한다.
      expect(storageData.containsKey('accessToken'), isFalse);
      expect(storageData.containsKey('refreshToken'), isFalse);
    });

    test('저장된 게 없으면 refreshToken 조회는 null', () async {
      expect(await tokenProvider.getRefreshToken(), isNull);
    });
  });

  group('SecureStorage 복호화 실패(BAD_DECRYPT) 복구', () {
    test(
      '읽기가 BAD_DECRYPT 로 깨지면 토큰을 지우고 인증 실패로 처리한다',
      () async {
        final corrupted = _CorruptedSecureStoragePlatform();
        FlutterSecureStoragePlatform.instance = corrupted;
        var notified = false;
        TokenProvider.registerAuthFailureHandler(() async {
          notified = true;
        });

        await expectLater(
          tokenProvider.getRefreshToken(),
          throwsA(isA<UnauthorizedException>()),
        );

        expect(corrupted.deletedKeys,
            containsAll(['accessToken', 'refreshToken']));
        expect(notified, isTrue);
      },
    );
  });

  group('registerAuthFailureHandler / notifyAuthFailure', () {
    test('등록한 핸들러가 notifyAuthFailure 호출 시 실행된다', () async {
      var callCount = 0;
      TokenProvider.registerAuthFailureHandler(() async {
        callCount++;
      });

      await tokenProvider.notifyAuthFailure();
      await tokenProvider.notifyAuthFailure();

      expect(callCount, 2);
    });

    test('핸들러를 다시 등록하면 이전 핸들러 대신 새 핸들러만 불린다', () async {
      var firstCalled = false;
      var secondCalled = false;
      TokenProvider.registerAuthFailureHandler(() async {
        firstCalled = true;
      });
      TokenProvider.registerAuthFailureHandler(() async {
        secondCalled = true;
      });

      await tokenProvider.notifyAuthFailure();

      expect(firstCalled, isFalse);
      expect(secondCalled, isTrue);
    });
  });
}
