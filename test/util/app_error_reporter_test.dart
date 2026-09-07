// lib/Util/AppErrorReporter.dart 검증.
//
// 커밋 c2a6cdd 이전에는 report() 가 sendDiscordAlert 를 직접(정적으로) 불러서
// 가짜로 바꿔 끼울 수 없었다. 지금은 `AppErrorReporter.discordAlertSender` 를
// `@visibleForTesting` 으로 열어 뒀으니, 이 전송기를 가짜로 바꿔 끼워서
// report() 가 언제 Discord 로 보내고 언제 건너뛰는지를 검증한다.
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Util/AppErrorReporter.dart';
import 'package:ono/Util/SendDiscordAlert.dart';

import '../helpers/helpers.dart';

/// discordAlertSender 자리에 끼워 넣는 가짜. 호출된 인자를 기록하고
/// 미리 정해 둔 결과를 돌려준다. 실제 HTTP 는 전혀 타지 않는다.
class _FakeDiscordAlertCall {
  _FakeDiscordAlertCall(
      {required this.message, this.stack, required this.webhookUrl});

  final String message;
  final StackTrace? stack;
  final String webhookUrl;
}

class _FakeDiscordAlertSender {
  final List<_FakeDiscordAlertCall> calls = [];
  DiscordAlertResult result = const DiscordAlertResult.success(statusCode: 204);

  Future<DiscordAlertResult> call({
    required String message,
    StackTrace? stack,
    required String webhookUrl,
    int maxAttempts = 2,
    http.Client? client,
  }) async {
    calls.add(_FakeDiscordAlertCall(
        message: message, stack: stack, webhookUrl: webhookUrl));
    return result;
  }
}

void main() {
  setUpOnoTest();

  late _FakeDiscordAlertSender fake;

  setUp(() {
    fake = _FakeDiscordAlertSender();
    AppErrorReporter.discordAlertSender = fake.call;
    // 기본값: 로컬 웹훅 URL 을 채워서 report() 가 discordAlertSender 까지 도달하게 한다.
    dotenv.testLoad(
      fileInput: [
        'DISCORD_WEBHOOK_LOCAL_URL=https://discord.test/local-webhook',
        'DISCORD_WEBHOOK_PROD_URL=',
      ].join('\n'),
    );
  });

  tearDown(() {
    AppErrorReporter.resetDiscordAlertSender();
    // 다음 테스트를 위해 test_setup.dart 가 깔아 둔 안전한 기본값(웹훅 URL 없음)으로 되돌린다.
    setUpTestDotenv();
    dotenv.testLoad(
      fileInput: [
        'BASE_URL_LOCAL=$testBaseUrl',
        'BASE_URL_DEV=$testBaseUrl',
        'BASE_URL_PROD=$testBaseUrl',
        'DISCORD_WEBHOOK_LOCAL_URL=',
        'DISCORD_WEBHOOK_PROD_URL=',
      ].join('\n'),
    );
  });

  group('정상 흐름', () {
    test('severity: error 이고 웹훅이 설정되어 있으면 Discord 로 보낸다', () async {
      await AppErrorReporter.report(
        Exception('문제 발생'),
        StackTrace.current,
        source: 'test_source',
      );

      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.message, '[test_source] Exception: 문제 발생');
      expect(
          fake.calls.single.webhookUrl, 'https://discord.test/local-webhook');
    });

    test('전송이 실패해도 report() 자체는 예외를 던지지 않는다', () async {
      fake.result = const DiscordAlertResult.failure(statusCode: 500);

      await expectLater(
        AppErrorReporter.report(Exception('문제'), StackTrace.current),
        completes,
      );
    });
  });

  group('전송을 건너뛰는 경우', () {
    test('severity: warning 이면 Discord 로 보내지 않는다', () async {
      await AppErrorReporter.report(
        Exception('경고'),
        StackTrace.current,
        severity: AppErrorSeverity.warning,
      );

      expect(fake.calls, isEmpty);
    });

    test('NetworkException 은 severity 가 warning 으로 낮아져 Discord 로 보내지 않는다',
        () async {
      await AppErrorReporter.report(
        NetworkException(),
        StackTrace.current,
        severity: AppErrorSeverity.error, // error 로 넘겨도 내부에서 낮아진다.
      );

      expect(fake.calls, isEmpty);
    });

    test('TimeoutException 도 severity 가 warning 으로 낮아져 Discord 로 보내지 않는다',
        () async {
      await AppErrorReporter.report(
        TimeoutException(),
        StackTrace.current,
        severity: AppErrorSeverity.fatal,
      );

      expect(fake.calls, isEmpty);
    });

    test('sendToDiscord: false 면 보내지 않는다', () async {
      await AppErrorReporter.report(
        Exception('무시'),
        StackTrace.current,
        sendToDiscord: false,
      );

      expect(fake.calls, isEmpty);
    });

    test('웹훅 URL 이 비어 있으면 건너뛴다', () async {
      dotenv.testLoad(
        fileInput: [
          'DISCORD_WEBHOOK_LOCAL_URL=',
          'DISCORD_WEBHOOK_PROD_URL=',
        ].join('\n'),
      );

      await AppErrorReporter.report(Exception('웹훅 없음'), StackTrace.current);

      expect(fake.calls, isEmpty);
    });

    test('공백만 있는 웹훅 URL 도 비어 있는 것으로 취급한다', () async {
      dotenv.testLoad(
        fileInput: [
          'DISCORD_WEBHOOK_LOCAL_URL=   ',
          'DISCORD_WEBHOOK_PROD_URL=',
        ].join('\n'),
      );

      await AppErrorReporter.report(Exception('공백 웹훅'), StackTrace.current);

      expect(fake.calls, isEmpty);
    });
  });

  group('웹훅 URL 우선순위 (local/prod 폴백)', () {
    test('local 웹훅이 비어 있으면 prod 웹훅으로 폴백한다 (kReleaseMode == false 인 테스트 환경 기준)',
        () async {
      expect(kReleaseMode, isFalse, reason: '이 테스트는 디버그 모드에서 도는 것을 전제로 한다');

      dotenv.testLoad(
        fileInput: [
          'DISCORD_WEBHOOK_LOCAL_URL=',
          'DISCORD_WEBHOOK_PROD_URL=https://discord.test/prod-webhook',
        ].join('\n'),
      );

      await AppErrorReporter.report(Exception('폴백'), StackTrace.current);

      expect(fake.calls.single.webhookUrl, 'https://discord.test/prod-webhook');
    });
  });

  group(
    'dotenv 미초기화 버그 (#174)',
    () {
      test(
        '한 번도 dotenv 를 로드하지 않은 프로세스에서 report() 를 부르면 NotInitializedError 로 죽는다',
        () async {
          // TODO(#174): 실제 버그. lib/Util/AppErrorReporter.dart:96
          // `_ensureDotenvLoaded()` 의 `if (dotenv.env.isNotEmpty) return;` 검사가
          // try/catch 바깥에 있다. dotenv 가 한 번도 초기화되지 않은 상태(_isInitialized
          // == false)에서 `dotenv.env` 에 접근하면 flutter_dotenv 가 NotInitializedError 를
          // 던지는데, 이건 try 블록 진입 전에 일어나서 잡히지 않고 report() 밖으로
          // 그대로 전파된다. 이 테스트 파일은 setUpOnoTest() 가 dotenv 를 이미 채워 둬서
          // 평소엔 절대 이 경로를 안 타므로, 완전히 새 isolate 를 띄워 "한 번도 로드된 적
          // 없는 프로세스" 상태를 재현한다(isolate 는 전역/정적 상태를 공유하지 않는다).
          final errorTypeName = await Isolate.run(() async {
            try {
              await AppErrorReporter.report(
                Exception('아직 아무것도 초기화 안 됨'),
                StackTrace.current,
                sendToDiscord: false,
              );
              return 'no-throw';
            } catch (error) {
              return error.runtimeType.toString();
            }
          });

          expect(errorTypeName, 'NotInitializedError');
        },
        skip: '#174 에서 수정 예정',
      );
    },
  );
}
