// HttpService 가 모든 요청에 붙이는 `X-App-Version` 헤더를 잠근다.
//
// 서버는 이 헤더로 요청이 어느 앱 버전에서 왔는지 보고 XP 자동 적립을 켤지
// 끌지 정한다. 헤더가 없으면 구버전으로 보고 자동 적립을 켠다. 그래서
// **버전을 못 읽었을 때 빈 문자열을 보내는 것이 가장 나쁘다.** 신버전인데
// 값이 이상한 것으로 오인될 수 있다. 키 자체가 없어야 한다.
//
// 앱의 모든 API 호출이 HttpService 를 지나므로, 헤더 하나를 더하는 일이
// 기존 헤더나 호출부가 넘긴 헤더를 밀어내지 않는지도 같이 본다.
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ono/Config/AppConfig.dart';
import 'package:ono/Service/Api/HttpService.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  // 정적 값이라 테스트 사이로 새어 나간다. 매번 "못 읽은 상태"에서 시작한다.
  setUp(() => AppConfig.setAppVersionForTest(null));
  tearDown(() => AppConfig.setAppVersionForTest(null));

  HttpService buildHttpService(
    TestHttpClient http, {
    String? accessToken = 'test-access-token',
  }) {
    return HttpService(
      client: http.client,
      tokenProvider: buildMockTokenProvider(accessToken: accessToken),
    );
  }

  group('X-App-Version 헤더', () {
    test('버전을 읽었으면 pubspec 의 version 그대로 나간다', () async {
      AppConfig.setAppVersionForTest('4.0.0+70');
      final client = TestHttpClient.respondJson(apiEnvelope(null));

      await buildHttpService(client).sendRequest(
        method: 'GET',
        url: '$testBaseUrl/api/missions',
      );

      expect(client.lastRequest.appVersion, '4.0.0+70');
    });

    test('버전을 못 읽었으면 헤더 키 자체가 없다', () async {
      final client = TestHttpClient.respondJson(apiEnvelope(null));

      await buildHttpService(client).sendRequest(
        method: 'GET',
        url: '$testBaseUrl/api/missions',
      );

      // 빈 문자열이 아니라 키가 없어야 한다. 서버가 헤더 없음을 구버전으로 읽는다.
      expect(client.lastRequest.hasAppVersionHeader, isFalse);
    });

    test('기존 헤더와 호출부가 넘긴 헤더가 그대로 살아 있다', () async {
      AppConfig.setAppVersionForTest('4.0.0+70');
      final client = TestHttpClient.respondJson(apiEnvelope(null));

      await buildHttpService(client).sendRequest(
        method: 'POST',
        url: '$testBaseUrl/api/problems',
        body: {'title': '문제'},
        headers: {'X-Custom': 'kept'},
      );

      final request = client.lastRequest;
      expect(request.authorization, 'test-access-token');
      expect(request.contentType, 'application/json; charset=UTF-8');
      expect(request.headers['X-Custom'], 'kept');
      expect(request.appVersion, '4.0.0+70');
    });

    test('토큰이 필요 없는 요청에도 붙는다', () async {
      AppConfig.setAppVersionForTest('4.0.0+70');
      final client = TestHttpClient.respondJson(apiEnvelope(null));

      await buildHttpService(client, accessToken: null).sendRequest(
        method: 'POST',
        url: '$testBaseUrl/api/auth/signup/guest',
        requiredToken: false,
      );

      final request = client.lastRequest;
      expect(request.appVersion, '4.0.0+70');
      expect(request.authorization, isNull);
    });

    test('multipart 요청에도 붙는다', () async {
      AppConfig.setAppVersionForTest('4.0.0+70');
      final client = TestHttpClient.respondJson(apiEnvelope(null));

      await buildHttpService(client).sendRequest(
        method: 'POST',
        url: '$testBaseUrl/api/fileUpload',
        isMultipart: true,
        filesBuilder: () async => [
          http.MultipartFile.fromString('file', 'content', filename: 'a.txt'),
        ],
      );

      final request = client.lastRequest;
      expect(request.appVersion, '4.0.0+70');
      // multipart 는 boundary 가 들어간 자기 Content-Type 을 쓴다.
      expect(request.contentType, contains('multipart/form-data'));
    });

    test('토큰 갱신 후 재시도한 요청에도 붙는다', () async {
      AppConfig.setAppVersionForTest('4.0.0+70');
      final client = TestHttpClient.sequence([
        errorResponse(statusCode: 401, errorCode: 1005),
        jsonResponse(apiEnvelope(null)),
      ]);

      await buildHttpService(client).sendRequest(
        method: 'GET',
        url: '$testBaseUrl/api/missions',
      );

      expect(client.callCount, 2);
      expect(client.firstRequest.appVersion, '4.0.0+70');
      expect(client.lastRequest.appVersion, '4.0.0+70');
    });
  });

  group('AppConfig 의 버전 읽기', () {
    // 아래 두 테스트는 순서를 지킨다. PackageInfo 는 한 번 읽은 값을 static 에
    // 쥐고 있어서, 가짜 값을 심고 나면 "못 읽는 상태"로 되돌릴 수 없다.
    test('플랫폼 채널이 없으면 던지지 않고 null 로 남는다', () async {
      await expectLater(AppConfig.loadAppVersionForTest(), completes);

      expect(AppConfig.appVersion, isNull);
    });

    test('version 과 buildNumber 를 `+` 로 이어 붙인다', () async {
      PackageInfo.setMockInitialValues(
        appName: 'OnO',
        packageName: 'com.aisip.OnO',
        version: '4.0.0',
        buildNumber: '70',
        buildSignature: '',
      );

      await AppConfig.loadAppVersionForTest();

      expect(AppConfig.appVersion, '4.0.0+70');
    });
  });
}
