import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Util/ApiHelper.dart';

import '../helpers/helpers.dart';

/// lib/Util/ApiHelper.dart 의 call / callAndThrow 검증.
///
/// ApiHelper 는 실패 시 내부적으로 AppErrorReporter.report() 를 부르는데,
/// 거기서 dotenv 를 한 번도 로드하지 않았으면 NotInitializedError 로 죽고
/// (실제 버그, 아래 참고), dotenv 가 실제 .env 를 읽으면 이 저장소의 진짜
/// Discord 웹훅 URL 이 잡혀서 sendToDiscord 값과 무관하게 실제 웹훅 전송
/// 경로를 타게 된다. 그래서 매 테스트 전에 dotenv 를 가짜 값으로만 채워
/// - dotenv.env 접근이 죽지 않게 하고
/// - DISCORD_WEBHOOK_* 키가 없어 웹훅 URL 이 항상 null 로 풀리게 만든다.
/// 여기에 더해 매 호출마다 sendToDiscord: false 도 명시해 이중으로 막는다.
void main() {
  setUpOnoTest();

  setUp(() {
    dotenv.testLoad(fileInput: 'TEST_ENV=1');
  });

  Future<BuildContext> pumpScaffold(WidgetTester tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return capturedContext;
  }

  group('ApiHelper.call', () {
    testWidgets('성공하면 결과를 반환하고 successMessage 스낵바를 띄운다', (tester) async {
      final context = await pumpScaffold(tester);

      final result = await ApiHelper.call<int>(
        context,
        () async => 42,
        successMessage: '성공했습니다',
      );
      await tester.pump();

      expect(result, 42);
      expect(find.text('성공했습니다'), findsOneWidget);
    });

    testWidgets('successMessage 가 없으면 성공해도 스낵바를 띄우지 않는다', (tester) async {
      final context = await pumpScaffold(tester);

      final result = await ApiHelper.call<int>(context, () async => 1);
      await tester.pump();

      expect(result, 1);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('실패하면 null 을 반환하고 에러 메시지를 스낵바로 띄운다', (tester) async {
      final context = await pumpScaffold(tester);

      final result = await ApiHelper.call<int>(
        context,
        () async =>
            throw ServerException(statusCode: 500, message: '서버 점검 중입니다.'),
        sendToDiscord: false,
      );
      await tester.pump();

      expect(result, isNull);
      expect(find.text('서버 점검 중입니다.'), findsOneWidget);
    });

    testWidgets('showErrorSnackBar 를 false 로 주면 실패해도 스낵바를 띄우지 않는다',
        (tester) async {
      final context = await pumpScaffold(tester);

      final result = await ApiHelper.call<int>(
        context,
        () async => throw ServerException(statusCode: 500),
        showErrorSnackBar: false,
        sendToDiscord: false,
      );
      await tester.pump();

      expect(result, isNull);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('실패 시 onError 콜백에 발생한 예외가 그대로 전달된다', (tester) async {
      final context = await pumpScaffold(tester);
      Object? capturedError;

      await ApiHelper.call<int>(
        context,
        () async => throw ServerException(statusCode: 500),
        showErrorSnackBar: false,
        sendToDiscord: false,
        onError: (error) => capturedError = error,
      );

      expect(capturedError, isA<ServerException>());
    });

    testWidgets('성공하면 onError 콜백은 호출되지 않는다', (tester) async {
      final context = await pumpScaffold(tester);
      var onErrorCalled = false;

      await ApiHelper.call<int>(
        context,
        () async => 1,
        onError: (_) => onErrorCalled = true,
      );

      expect(onErrorCalled, isFalse);
    });

    testWidgets('context 가 dispose 된 뒤 성공 응답이 와도 크래시하지 않는다', (tester) async {
      final context = await pumpScaffold(tester);
      final completer = Completer<int>();

      final future = ApiHelper.call<int>(
        context,
        () => completer.future,
        successMessage: '성공했습니다',
      );

      // 위젯이 dispose 된 뒤 응답이 도착하는 상황을 재현한다:
      // 완전히 다른 트리로 교체해 context 를 unmount 시킨다.
      await tester.pumpWidget(const SizedBox.shrink());
      expect(context.mounted, isFalse);

      completer.complete(1);
      final result = await future;

      expect(result, 1);
    });

    testWidgets('context 가 dispose 된 뒤 실패 응답이 와도 크래시하지 않는다', (tester) async {
      final context = await pumpScaffold(tester);
      final completer = Completer<int>();

      final future = ApiHelper.call<int>(
        context,
        () => completer.future,
        sendToDiscord: false,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      expect(context.mounted, isFalse);

      completer.completeError(ServerException(statusCode: 500));
      final result = await future;

      expect(result, isNull);
    });
  });

  group('ApiHelper.callAndThrow', () {
    testWidgets('성공하면 결과를 반환하고 successMessage 스낵바를 띄운다', (tester) async {
      final context = await pumpScaffold(tester);

      final result = await ApiHelper.callAndThrow<int>(
        context,
        () async => 7,
        successMessage: '완료',
      );
      await tester.pump();

      expect(result, 7);
      expect(find.text('완료'), findsOneWidget);
    });

    testWidgets('실패하면 에러 스낵바를 띄우고 예외를 다시 던진다', (tester) async {
      final context = await pumpScaffold(tester);

      await expectLater(
        ApiHelper.callAndThrow<int>(
          context,
          () async => throw BadRequestException(
            statusCode: 400,
            errorCode: 5001,
            message: '폴더를 찾을 수 없습니다.',
          ),
          sendToDiscord: false,
        ),
        throwsA(isA<BadRequestException>()),
      );
      await tester.pump();

      expect(find.text('폴더를 찾을 수 없습니다.'), findsOneWidget);
    });

    testWidgets('call 과 달리 실패를 삼키지 않고 호출부까지 전파한다', (tester) async {
      final context = await pumpScaffold(tester);
      var caught = false;

      try {
        await ApiHelper.callAndThrow<int>(
          context,
          () async => throw ServerException(statusCode: 500),
          showErrorSnackBar: false,
          sendToDiscord: false,
        );
      } on ServerException {
        caught = true;
      }

      expect(caught, isTrue);
    });

    testWidgets('context 가 dispose 된 뒤 실패해도 크래시 없이 예외만 던진다', (tester) async {
      final context = await pumpScaffold(tester);
      final completer = Completer<int>();

      final future = ApiHelper.callAndThrow<int>(
        context,
        () => completer.future,
        sendToDiscord: false,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      expect(context.mounted, isFalse);

      completer.completeError(ServerException(statusCode: 500));

      await expectLater(future, throwsA(isA<ServerException>()));
    });
  });
}
