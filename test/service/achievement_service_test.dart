// AchievementService 가 백엔드와 주고받는 계약을 검증한다.
//
// 프로바이더 테스트와 화면 테스트는 전부 `FakeAchievementService` 를 써서 이
// 서비스를 건너뛴다. 그래서 요청 URL·메서드, `CommonResponse` 껍데기 벗기기,
// 응답 파싱은 여기서만 잠긴다. 치장 때는 이 파일이 빠져 있어서 요청 모양과
// 응답 파싱이 한 번도 검증되지 않은 채로 갈 뻔했다.
//
// 실패 경로를 요청 경로만큼 자세히 본다. 훈장은 가끔 보고 흐뭇한 것이지 앱
// 진입을 막을 것이 아니라서, 이 서비스는 어떤 실패에서도 예외를 밖으로
// 내보내지 않고 null 로 떨어져야 한다. 옷장 탭의 성장 카드가 이 조회를 보고
// 있어서 여기서 던지면 탭 하나가 통째로 안 뜬다.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Service/Api/Achievement/AchievementService.dart';
import 'package:ono/Service/Api/HttpService.dart';

import '../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  AchievementService buildService(
    TestHttpClient http, {
    String? accessToken = 'test-access-token',
  }) {
    return AchievementService(
      httpService: HttpService(
        client: http.client,
        tokenProvider: buildMockTokenProvider(accessToken: accessToken),
      ),
    );
  }

  Map<String, dynamic> boardPayload() => {
        'achievements': [
          {
            'key': 'archivist',
            'nameKo': '기록광',
            'descriptionKo': '오답노트를 백 개나 모았어요',
            'imageUrl': 'assets/Medal/archivist.png',
            'earned': true,
            'earnedAt': '2026-09-14T01:23:45',
            'current': 100,
            'target': 100,
          },
        ],
        'newlyEarned': ['archivist'],
      };

  group('getAchievements', () {
    test('GET /api/achievements 로 훈장을 조회한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(boardPayload()));

      final board = await buildService(http).getAchievements();

      expect(http.lastRequest.method, 'GET');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/achievements');
      expect(http.lastRequest.authorization, 'test-access-token');
      expect(board, isNotNull);
      expect(board!.achievements.single.key, 'archivist');
      expect(board.newlyEarned, ['archivist']);
    });

    test('API 가 아직 배포 전이라 404 가 와도 null 을 돌려준다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 404, message: 'Not Found'),
      );

      expect(await buildService(http).getAchievements(), isNull);
    });

    test('서버가 500 을 줘도 예외를 던지지 않는다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '서버 오류'),
      );

      expect(await buildService(http).getAchievements(), isNull);
    });

    test('네트워크가 끊겨도 null 을 돌려준다', () async {
      final http = TestHttpClient.throwing(const SocketException('offline'));

      expect(await buildService(http).getAchievements(), isNull);
    });

    test('응답이 늦어 타임아웃이 나도 null 을 돌려준다', () async {
      final http = TestHttpClient.throwing(TimeoutException('too slow'));

      expect(await buildService(http).getAchievements(), isNull);
    });

    test('2xx 인데 본문이 JSON 이 아니면 null 을 돌려준다', () async {
      // 프록시가 끼어들어 HTML 을 돌려주는 경우다. HttpService 는 원문을
      // 그대로 넘기고, 모델은 Map 이 아니면 읽지 않는다.
      final http =
          TestHttpClient.respondWith(textResponse('<html>점검 중</html>'));

      expect(await buildService(http).getAchievements(), isNull);
    });

    test('data 가 맵이 아니면 null 을 돌려준다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope('unexpected'));

      expect(await buildService(http).getAchievements(), isNull);
    });

    test('achievements 가 목록이 아니면 null 을 돌려준다', () async {
      // 빈 훈장판으로 떨어뜨리면 화면이 "훈장이 하나도 없어요"를 조용히
      // 그려서, 통신이 깨진 것과 정말로 비어 있는 것이 구분되지 않는다.
      final http = TestHttpClient.respondJson(
        apiEnvelope({'achievements': 'broken', 'newlyEarned': <String>[]}),
      );

      expect(await buildService(http).getAchievements(), isNull);
    });

    test('204 처럼 본문이 없으면 null 을 돌려준다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      expect(await buildService(http).getAchievements(), isNull);
    });

    test('토큰이 없으면 호출하지 않고 null 을 돌려준다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(boardPayload()));

      final board =
          await buildService(http, accessToken: null).getAchievements();

      expect(board, isNull);
      expect(http.callCount, 0);
    });

    test('줄 하나가 깨져도 나머지는 읽는다', () async {
      // key 가 없는 줄은 그림 경로도 못 찾고 새로 받은 것과 맞춰 볼 수도 없어서
      // 화면에 세울 자리가 없다. 그 줄만 버리고 나머지 열한 개는 그려야 한다.
      final http = TestHttpClient.respondJson(apiEnvelope({
        'achievements': [
          {'nameKo': '이름만 있는 줄'},
          {'key': 'phoenix', 'nameKo': '불사조', 'earned': false},
        ],
        'newlyEarned': <String>[],
      }));

      final board = await buildService(http).getAchievements();

      expect(board!.achievements, hasLength(1));
      expect(board.achievements.single.key, 'phoenix');
    });

    test('newlyEarned 가 아예 없으면 빈 목록으로 읽는다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope({
        'achievements': <Map<String, Object?>>[],
      }));

      expect(
          (await buildService(http).getAchievements())!.newlyEarned, isEmpty);
    });
  });

  // 아래 테스트들만 손으로 적은 Dart 리터럴이 아니라 **파일에 적힌 응답**을
  // 그대로 읽어 파싱한다. 손으로 적은 Map 은 프론트가 지금 믿고 있는 것을 다시
  // 적은 것이라 오해가 있어도 드러나지 않는다. 파일로 빼 두면 백엔드가 실제
  // 응답에서 떠낸 것과 나란히 놓고 diff 할 수 있다.
  //
  // 이 파일은 백엔드가 확정해 준 계약(이슈 #211)을 그대로 옮긴 것이다.
  // 성공 응답에 `errorCode` 와 `message` 가 아예 빠지는 것도 계약이라
  // `apiEnvelope()` 로 씌우지 않고 파일에 그 모양 그대로 적었다.
  group('픽스처로 적어 둔 서버 응답', () {
    test('GET /api/achievements 응답을 훈장판으로 읽는다', () async {
      final http = TestHttpClient.respondJson(
        loadJsonFixture(AchievementMockData.fullFixture),
      );

      final board = await buildService(http).getAchievements();

      expect(board, isNotNull);
      expect(board!.achievements, hasLength(12));
      expect(board.total, 12);

      // 훈장표의 순서 그대로다. 앱은 정렬하지 않는다.
      expect(board.achievements.first.key, 'first_step');
      expect(board.achievements.last.key, 'cheerleader');

      // 받은 것과 못 받은 것이 함께 온다.
      expect(board.of('first_step')!.earned, isTrue);
      expect(board.of('archivist')!.earned, isFalse);
      expect(board.earnedCount, 3);

      // 못 받은 것에도 이름과 설명과 그림이 실려 온다. 무엇이 기다리고
      // 있는지 보여야 갖고 싶어진다.
      final archivist = board.of('archivist')!;
      expect(archivist.nameKo, '기록광');
      expect(archivist.descriptionKo, '오답노트를 백 개나 모았어요');
      expect(archivist.imageUrl, 'assets/Medal/archivist.png');
      expect(archivist.current, 87);
      expect(archivist.target, 100);
      expect(archivist.hasProgress, isTrue);
      expect(archivist.progressRatio, closeTo(0.87, 0.0001));
      expect(archivist.remaining, 13);

      // 못 받았으면 받은 날짜가 없다.
      expect(archivist.earnedAt, isNull);
      expect(
        board.of('perfect_month')!.earnedAt,
        DateTime(2026, 9, 14, 1, 23, 45),
      );

      // 진행도가 없는 둘. 눈금을 세울 것이 없다.
      expect(board.of('phoenix')!.hasProgress, isFalse);
      expect(board.of('first_step')!.hasProgress, isFalse);
      expect(board.of('phoenix')!.current, isNull);
      expect(board.of('phoenix')!.target, isNull);

      expect(board.newlyEarned, ['perfect_month']);
    });

    test('새로 받은 것이 없으면 newlyEarned 가 빈 배열로 온다', () async {
      final http = TestHttpClient.respondJson(
        loadJsonFixture(AchievementMockData.noNewsFixture),
      );

      final board = await buildService(http).getAchievements();

      expect(board, isNotNull);
      expect(board!.newlyEarned, isEmpty);
      expect(board.achievements, hasLength(2));
    });
  });

  // 이 플래그는 나가는 요청에 안 실려서 TestHttpClient 로는 볼 수 없다.
  // 여기서만 HttpService 를 mock 으로 바꾼다.
  group('showErrorSnackBar', () {
    test('getAchievements 는 알림을 끄고 부른다', () async {
      // 훈장을 못 불러온 것은 사용자가 지금 하려던 일과 상관이 없다. 다른
      // 화면을 보고 있는데 알림이 내려오면 무엇이 실패했는지도 모른 채
      // 놀라기만 한다.
      final httpService = MockHttpService();
      final service = AchievementService(httpService: httpService);

      when(() => httpService.sendRequest(
            method: 'GET',
            url: '$testBaseUrl/api/achievements',
            showErrorSnackBar: false,
          )).thenAnswer((_) async => boardPayload());

      expect(await service.getAchievements(), isNotNull);

      verify(() => httpService.sendRequest(
            method: 'GET',
            url: '$testBaseUrl/api/achievements',
            showErrorSnackBar: false,
          )).called(1);
    });
  });
}
