// lib/Util/SendDiscordAlert.dart 의 sendDiscordAlert() 검증.
//
// 커밋 c2a6cdd 이전에는 최상위 `http.post` 를 직접 불러서 Client 를 갈아끼울 수
// 없었다. 지금은 `client:` 로 주입할 수 있어서 진짜 웹훅 없이 요청 모양과
// 재시도 로직을 볼 수 있다.
//
// 429/5xx 재시도는 실제로 Future.delayed 를 기다리므로, 아래 테스트들은 초 단위의
// 실제 대기 시간이 든다(재시도 1회당 1초 안팎). fake_async 는 이 레포의 의존성에
// 없어 쓰지 않는다.
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ono/Util/SendDiscordAlert.dart';

import '../helpers/helpers.dart';

/// 주입한 client 가 실제로 close() 되는지 추적하는 래퍼.
class _CloseTrackingClient extends http.BaseClient {
  _CloseTrackingClient(this._inner);

  final http.Client _inner;
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request);

  @override
  void close() {
    closed = true;
    _inner.close();
  }
}

void main() {
  setUpOnoTest();

  const webhookUrl = 'https://discord.test/webhook';

  group('요청 모양', () {
    test('웹훅 URL 로 POST 하고 embed 페이로드를 담는다', () async {
      final http =
          TestHttpClient.respondWith(jsonResponse(null, statusCode: 204));

      final result = await sendDiscordAlert(
        message: '문제가 발생했습니다',
        stack: StackTrace.current,
        webhookUrl: webhookUrl,
        client: http.client,
      );

      expect(result.isSuccess, isTrue);
      expect(http.lastRequest.method, 'POST');
      expect(http.lastRequest.url.toString(), webhookUrl);
      expect(http.lastRequest.contentType, contains('application/json'));

      final body = http.lastRequest.jsonBody!;
      final embeds = body['embeds'] as List;
      expect(embeds, hasLength(1));
      final embed = embeds.first as Map<String, dynamic>;
      expect(embed['title'], contains('Flutter 앱 에러'));
      expect(embed['description'], contains('문제가 발생했습니다'));
      expect(embed['timestamp'], isNotNull);

      final fields = embed['fields'] as List;
      expect(fields, hasLength(1));
      expect((fields.first as Map)['name'], 'StackTrace');
    });

    test('stack 을 주지 않으면 fields 가 비어 있다', () async {
      final http =
          TestHttpClient.respondWith(jsonResponse(null, statusCode: 204));

      await sendDiscordAlert(
        message: '스택 없음',
        webhookUrl: webhookUrl,
        client: http.client,
      );

      final body = http.lastRequest.jsonBody!;
      final embed = (body['embeds'] as List).first as Map<String, dynamic>;
      expect(embed['fields'], isEmpty);
    });

    test('message 가 1500자를 넘으면 잘라서 보낸다', () async {
      final http =
          TestHttpClient.respondWith(jsonResponse(null, statusCode: 204));
      final longMessage = 'x' * 2000;

      await sendDiscordAlert(
        message: longMessage,
        webhookUrl: webhookUrl,
        client: http.client,
      );

      final body = http.lastRequest.jsonBody!;
      final embed = (body['embeds'] as List).first as Map<String, dynamic>;
      final description = embed['description'] as String;
      // description 은 ```{메시지}``` 형태로 감싼다.
      final safeMessage = description.substring(3, description.length - 3);
      expect(safeMessage.length, 1500);
      expect(safeMessage, endsWith('...'));
    });

    test('스택트레이스가 3500자를 넘으면 잘라서 보낸다', () async {
      final http =
          TestHttpClient.respondWith(jsonResponse(null, statusCode: 204));
      final longStack =
          List.generate(500, (i) => 'at frame$i (file.dart:$i)').join('\n');
      expect(longStack.length, greaterThan(3500));

      await sendDiscordAlert(
        message: '에러',
        stack: StackTrace.fromString(longStack),
        webhookUrl: webhookUrl,
        client: http.client,
      );

      final body = http.lastRequest.jsonBody!;
      final embed = (body['embeds'] as List).first as Map<String, dynamic>;
      final fields = embed['fields'] as List;
      final stackValue = (fields.first as Map)['value'] as String;
      final safeStack = stackValue.substring(3, stackValue.length - 3);
      expect(safeStack.length, 3500);
      expect(safeStack, endsWith('...'));
    });
  });

  group('결과', () {
    test('2xx 응답이면 성공으로 끝난다', () async {
      final http =
          TestHttpClient.respondWith(jsonResponse(null, statusCode: 200));

      final result = await sendDiscordAlert(
        message: '성공',
        webhookUrl: webhookUrl,
        client: http.client,
      );

      expect(result.isSuccess, isTrue);
      expect(result.statusCode, 200);
      expect(http.callCount, 1);
    });

    test('4xx 응답이면 재시도 없이 바로 실패로 끝난다', () async {
      final http =
          TestHttpClient.respondWith(jsonResponse(null, statusCode: 400));

      final result = await sendDiscordAlert(
        message: '실패',
        webhookUrl: webhookUrl,
        client: http.client,
      );

      expect(result.isSuccess, isFalse);
      expect(result.statusCode, 400);
      expect(http.callCount, 1);
    });
  });

  group('재시도', () {
    test(
      '429 응답이면 retry-after 만큼 기다렸다가 재시도해서 성공할 수 있다',
      () async {
        var attempt = 0;
        final http = TestHttpClient.handler((req) async {
          attempt++;
          if (attempt == 1) {
            return jsonResponse(
              null,
              statusCode: 429,
              headers: {'retry-after': '1'},
            );
          }
          return jsonResponse(null, statusCode: 200);
        });

        final stopwatch = Stopwatch()..start();
        final result = await sendDiscordAlert(
          message: '429 재시도',
          webhookUrl: webhookUrl,
          client: http.client,
        );
        stopwatch.stop();

        expect(result.isSuccess, isTrue);
        expect(http.callCount, 2);
        // retry-after=1초 만큼 실제로 기다렸는지 느슨하게 확인한다(타이밍 유연성을 위해 900ms).
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(900));
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    test(
      '5xx 응답이면 1초 기다렸다가 재시도해서 성공할 수 있다',
      () async {
        var attempt = 0;
        final http = TestHttpClient.handler((req) async {
          attempt++;
          if (attempt == 1) {
            return jsonResponse(null, statusCode: 503);
          }
          return jsonResponse(null, statusCode: 200);
        });

        final stopwatch = Stopwatch()..start();
        final result = await sendDiscordAlert(
          message: '5xx 재시도',
          webhookUrl: webhookUrl,
          client: http.client,
        );
        stopwatch.stop();

        expect(result.isSuccess, isTrue);
        expect(http.callCount, 2);
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(900));
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    test(
      'maxAttempts 를 넘기면 계속 429 여도 실패로 끝난다',
      () async {
        final http = TestHttpClient.respondWith(
          jsonResponse(null, statusCode: 429, headers: {'retry-after': '1'}),
        );

        final result = await sendDiscordAlert(
          message: '계속 실패',
          webhookUrl: webhookUrl,
          maxAttempts: 2,
          client: http.client,
        );

        expect(result.isSuccess, isFalse);
        expect(result.statusCode, 429);
        // maxAttempts=2 이므로 재시도는 한 번만 일어나고, 두 번째 시도에서 그대로 끝난다.
        expect(http.callCount, 2);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    test('전송 자체가 계속 실패하면(SocketException) maxAttempts 만큼 재시도 후 실패로 끝난다',
        () async {
      final http = TestHttpClient.throwing(Exception('전송 실패'));

      final result = await sendDiscordAlert(
        message: '전송 실패',
        webhookUrl: webhookUrl,
        maxAttempts: 2,
        client: http.client,
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, isNotNull);
      expect(http.callCount, 2);
    });
  });

  group('client 생명주기', () {
    test('주입한 client 는 함수가 끝나도 닫지 않는다', () async {
      final http =
          TestHttpClient.respondWith(jsonResponse(null, statusCode: 204));
      final tracked = _CloseTrackingClient(http.client);

      await sendDiscordAlert(
        message: '메시지',
        webhookUrl: webhookUrl,
        client: tracked,
      );

      expect(tracked.closed, isFalse);
    });
  });
}
