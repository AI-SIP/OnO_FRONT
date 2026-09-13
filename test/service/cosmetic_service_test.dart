// CosmeticService 가 백엔드와 주고받는 계약을 검증한다.
//
// 프로바이더 테스트는 전부 `FakeCosmeticService` 를 써서 이 서비스를 건너뛴다.
// 그래서 요청 URL·메서드·바디 모양, `CommonResponse` 껍데기 벗기기, 응답
// 파싱은 여기서만 잠긴다.
//
// 실패 경로를 요청 경로만큼 자세히 본다. 치장은 있으면 좋은 것이지 앱 진입을
// 막을 것이 아니라서, 이 서비스는 어떤 실패에서도 예외를 밖으로 내보내지 않고
// null 로 떨어져야 한다. 화면 열일곱 군데가 개구리를 그리고 있어 여기서 던지면
// 하단 탭 아이콘부터 출석 도장까지 같이 무너진다.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Cosmetic/CosmeticAbilityLevels.dart';
import 'package:ono/Service/Api/Cosmetic/CosmeticService.dart';
import 'package:ono/Service/Api/HttpService.dart';

import '../helpers/helpers.dart';

/// `GET /api/cosmetics` 가 내려줄 것이라고 프론트가 적어 둔 응답 전체.
///
/// **래퍼까지 포함한 본문 그대로다.** 프론트가 벗겨내야 하는 껍데기도 계약이라,
/// `apiEnvelope()` 로 테스트에서 다시 씌우지 않고 파일에 같이 적었다.
///
/// [CosmeticMockData] 와 역할이 다르다. 그쪽은 어떤 아이템이 몇 레벨에 열리는지
/// (해금표)를 잠그고 가짜 서버의 밑천이 된다. 이쪽은 응답 한 번의 **본문 모양**만
/// 잠근다. 그래서 아이템도 파싱이 마주칠 모양별로 한 줄씩만 들어 있다.
const String _getCosmeticsFixture = 'cosmetic/get_cosmetics_response.json';

/// `PUT /api/cosmetics/equip-all` 이 내려줄 것이라고 프론트가 적어 둔 응답 전체.
const String _equipAllFixture = 'cosmetic/equip_all_response.json';

void main() {
  setUpOnoTest();

  CosmeticService buildService(
    TestHttpClient http, {
    String? accessToken = 'test-access-token',
  }) {
    return CosmeticService(
      httpService: HttpService(
        client: http.client,
        tokenProvider: buildMockTokenProvider(accessToken: accessToken),
      ),
    );
  }

  Map<String, dynamic> loadoutPayload() => {
        'baseImageUrl': 'assets/Cosmetic/BASE.png',
        'baseLayerOrder': 300,
        'slots': [
          {
            'slot': 'BACKGROUND',
            'layerOrder': 100,
            'nameKo': '배경',
            'composited': true,
          },
        ],
        'items': [
          {
            'itemKey': 'bg_spring',
            'slot': 'BACKGROUND',
            'nameKo': '봄',
            'imageUrl': 'assets/Cosmetic/bg_spring.png',
            'requiredLevel': 2,
            'requiredAbility': 'ATTENDANCE',
            'setId': null,
            'setNameKo': null,
            'conflictsWith': <String>[],
            'owned': true,
            'fullBody': false,
            'layerOrder': null,
          },
        ],
        'equipped': {'BACKGROUND': 'bg_spring'},
      };

  Map<String, dynamic> equipResultPayload() => {
        'equipped': {'BACKGROUND': 'bg_spring'},
        'unequippedSlots': <String>[],
      };

  group('getCosmetics', () {
    test('GET /api/cosmetics 로 옷장을 조회한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(loadoutPayload()));

      final loadout = await buildService(http).getCosmetics();

      expect(http.lastRequest.method, 'GET');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/cosmetics');
      expect(http.lastRequest.authorization, 'test-access-token');
      expect(loadout, isNotNull);
      expect(loadout!.items.single.itemKey, 'bg_spring');
      expect(loadout.equipped, {'BACKGROUND': 'bg_spring'});
    });

    test('API 가 아직 배포 전이라 404 가 와도 null 을 돌려준다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 404, message: 'Not Found'),
      );

      expect(await buildService(http).getCosmetics(), isNull);
    });

    test('서버가 500 을 줘도 예외를 던지지 않는다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '서버 오류'),
      );

      expect(await buildService(http).getCosmetics(), isNull);
    });

    test('네트워크가 끊겨도 null 을 돌려준다', () async {
      final http = TestHttpClient.throwing(const SocketException('offline'));

      expect(await buildService(http).getCosmetics(), isNull);
    });

    test('응답이 늦어 타임아웃이 나도 null 을 돌려준다', () async {
      final http = TestHttpClient.throwing(TimeoutException('too slow'));

      expect(await buildService(http).getCosmetics(), isNull);
    });

    test('2xx 인데 본문이 JSON 이 아니면 null 을 돌려준다', () async {
      // 프록시가 끼어들어 HTML 을 돌려주는 경우다. HttpService 는 원문을
      // 그대로 넘기고, 모델은 Map 이 아니면 읽지 않는다.
      final http =
          TestHttpClient.respondWith(textResponse('<html>점검 중</html>'));

      expect(await buildService(http).getCosmetics(), isNull);
    });

    test('data 가 맵이 아니면 null 을 돌려준다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope('unexpected'));

      expect(await buildService(http).getCosmetics(), isNull);
    });

    test('204 처럼 본문이 없으면 null 을 돌려준다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      expect(await buildService(http).getCosmetics(), isNull);
    });

    test('토큰이 없으면 호출하지 않고 null 을 돌려준다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(loadoutPayload()));

      final loadout =
          await buildService(http, accessToken: null).getCosmetics();

      expect(loadout, isNull);
      expect(http.callCount, 0);
    });
  });

  group('equip', () {
    test('PUT /api/cosmetics/equip 에 slot 과 itemKey 를 보낸다', () async {
      final http =
          TestHttpClient.respondJson(apiEnvelope(equipResultPayload()));

      await buildService(http).equip(slot: 'HEAD', itemKey: 'hat_graduate');

      expect(http.lastRequest.method, 'PUT');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/cosmetics/equip',
      );
      expect(http.lastRequest.contentType, contains('application/json'));
      expect(http.lastRequest.jsonBody, {
        'slot': 'HEAD',
        'itemKey': 'hat_graduate',
      });
    });

    test('itemKey 를 주지 않으면 itemKey 를 null 로 실어 보낸다', () async {
      // 해제 요청이다. 키가 아예 빠지면 서버가 "이 자리는 건드리지 마라"로
      // 읽을 수 있어서, 값이 null 인 키가 반드시 실려 나가야 한다.
      final http =
          TestHttpClient.respondJson(apiEnvelope(equipResultPayload()));

      await buildService(http).equip(slot: 'HEAD');

      final body = http.lastRequest.jsonBody!;
      expect(body.containsKey('itemKey'), isTrue);
      expect(body['itemKey'], isNull);
      expect(body['slot'], 'HEAD');
    });

    test('응답으로 차림 전체와 서버가 벗긴 자리를 읽는다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope({
        'equipped': {'HEAD': 'hat_graduate', 'OUTFIT': 'outfit_graduate'},
        'unequippedSlots': ['NECK'],
      }));

      final result =
          await buildService(http).equip(slot: 'HEAD', itemKey: 'hat_graduate');

      expect(result, isNotNull);
      expect(result!.equipped, {
        'HEAD': 'hat_graduate',
        'OUTFIT': 'outfit_graduate',
      });
      expect(result.unequippedSlots, ['NECK']);
    });

    test('equipped 의 값이 null 인 자리는 비운 것으로 읽는다', () async {
      // 서버가 "이 자리는 이제 비었다"를 null 로 내려줄 수 있다. 그 칸을
      // 그대로 담으면 개구리가 없는 아이템을 그리려 든다.
      final http = TestHttpClient.respondJson(apiEnvelope({
        'equipped': {'HEAD': null, 'OUTFIT': 'outfit_graduate'},
        'unequippedSlots': <String>[],
      }));

      final result = await buildService(http).equip(slot: 'HEAD');

      expect(result!.equipped, {'OUTFIT': 'outfit_graduate'});
    });

    test('404 면 예외 없이 null 을 돌려준다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 404, message: 'Not Found'),
      );

      expect(await buildService(http).equip(slot: 'HEAD'), isNull);
    });

    test('서버가 500 을 줘도 예외를 던지지 않는다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '서버 오류'),
      );

      expect(await buildService(http).equip(slot: 'HEAD'), isNull);
    });

    test('네트워크가 끊겨도 null 을 돌려준다', () async {
      final http = TestHttpClient.throwing(const SocketException('offline'));

      expect(await buildService(http).equip(slot: 'HEAD'), isNull);
    });

    test('2xx 인데 본문을 읽지 못하면 성공으로 다루지 않는다', () async {
      // 서버가 무엇을 걸었는지 알 수 없으니 null 이다. 프로바이더가 마지막으로
      // 받은 차림으로 되돌린다.
      final http = TestHttpClient.respondWith(textResponse('OK'));

      expect(await buildService(http).equip(slot: 'HEAD'), isNull);
    });
  });

  group('equipSet', () {
    test('PUT /api/cosmetics/equip-set 에 setId 를 보낸다', () async {
      final http =
          TestHttpClient.respondJson(apiEnvelope(equipResultPayload()));

      final result = await buildService(http).equipSet('graduate');

      expect(http.lastRequest.method, 'PUT');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/cosmetics/equip-set',
      );
      expect(http.lastRequest.jsonBody, {'setId': 'graduate'});
      expect(result, isNotNull);
    });

    test('404 면 예외 없이 null 을 돌려준다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 404, message: 'Not Found'),
      );

      expect(await buildService(http).equipSet('graduate'), isNull);
    });

    test('네트워크가 끊겨도 null 을 돌려준다', () async {
      final http = TestHttpClient.throwing(const SocketException('offline'));

      expect(await buildService(http).equipSet('graduate'), isNull);
    });
  });

  group('equipAll', () {
    test('PUT /api/cosmetics/equip-all 에 equipped 맵을 보낸다', () async {
      final http =
          TestHttpClient.respondJson(apiEnvelope(equipResultPayload()));

      await buildService(http).equipAll({
        'BACKGROUND': 'bg_spring',
        'HEAD': 'hat_graduate',
      });

      expect(http.lastRequest.method, 'PUT');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/cosmetics/equip-all',
      );
      expect(http.lastRequest.jsonBody, {
        'equipped': {
          'BACKGROUND': 'bg_spring',
          'HEAD': 'hat_graduate',
        },
      });
    });

    test('빈 맵도 요청을 보낸다. 전부 벗기라는 뜻이다', () async {
      // 요청을 건너뛰면 "다 벗었다"가 서버에 영영 안 간다. 앱에서만 벗은
      // 개구리가 다음 조회에 다시 옷을 입고 돌아온다.
      final http = TestHttpClient.respondJson(apiEnvelope({
        'equipped': <String, String>{},
        'unequippedSlots': <String>[],
      }));

      final result = await buildService(http).equipAll({});

      expect(http.callCount, 1);
      expect(http.lastRequest.jsonBody, {'equipped': <String, dynamic>{}});
      expect(result!.equipped, isEmpty);
    });

    test('아직 서버에 배포되지 않아 404 가 와도 null 을 돌려준다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 404, message: 'Not Found'),
      );

      expect(
          await buildService(http).equipAll({'HEAD': 'hat_graduate'}), isNull);
    });

    test('서버가 500 을 줘도 예외를 던지지 않는다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '서버 오류'),
      );

      expect(
          await buildService(http).equipAll({'HEAD': 'hat_graduate'}), isNull);
    });

    test('응답이 늦어 타임아웃이 나도 null 을 돌려준다', () async {
      final http = TestHttpClient.throwing(TimeoutException('too slow'));

      expect(
          await buildService(http).equipAll({'HEAD': 'hat_graduate'}), isNull);
    });

    test('2xx 인데 본문을 읽지 못하면 성공으로 다루지 않는다', () async {
      final http = TestHttpClient.respondWith(emptyResponse(statusCode: 200));

      expect(
          await buildService(http).equipAll({'HEAD': 'hat_graduate'}), isNull);
    });
  });

  // 아래 두 테스트만 손으로 적은 Dart 리터럴이 아니라 **파일에 적힌 응답**을
  // 그대로 읽어 파싱한다. 손으로 적은 Map 은 프론트가 지금 믿고 있는 것을 다시
  // 적은 것이라 오해가 있어도 드러나지 않는다. 파일로 빼 두면 백엔드가 실제
  // 응답에서 떠낸 것과 나란히 놓고 diff 할 수 있다.
  //
  // 확신이 없어 추측으로 적은 자리는 이렇다. 틀렸으면 여기가 먼저 깨진다.
  //
  // 1. 성공 응답에도 `errorCode`, `message` 키가 null 로 실려 온다고 봤다.
  //    (`docs/소셜 스터디룸/프론트_구현명세서.md:13` 은 성공 시 두 키가 아예
  //    빠진다고 적혀 있다. 둘 중 어느 쪽이든 `HttpService` 는 `data` 만 보므로
  //    앱 동작은 같지만, 계약서로는 한쪽이 틀린 것이다.)
  // 2. 슬롯 키가 대문자(`HEAD`)다. `docs/치장 시스템/구현_계획.md:98` 의 표는
  //    소문자(`head`)로 적혀 있다.
  // 3. `conflictsWith` 가 문자열 배열로 온다고 봤다. 구현 계획의 DDL 은
  //    `conflicts_with` 를 컬럼 하나로 두고 있어서, 쉼표로 이은 문자열이 그대로
  //    나올 가능성이 있다. 그러면 지금 파서는 조용히 빈 목록으로 읽는다.
  // 4. `composited`, `baseLayerOrder`, `setNameKo`, `items[].layerOrder`,
  //    `fullBody` 를 서버가 실제로 내려준다고 봤다. 넷 다 앱이 나중에 필요해서
  //    만든 필드라 서버에 없을 수 있다. 없으면 파서가 기본값으로 때우는데,
  //    `composited` 가 빠지면 프로필 테두리가 개구리 얼굴을 덮는다.
  // 5. `imageUrl` 이 앱 번들 경로(`assets/...`)다. S3 URL 로 바뀌었을 수 있다.
  // 6. 총 학습 레벨로 열리는 아이템은 `requiredAbility` 가 null 이다. 서버가
  //    `TOTAL_STUDY` 같은 값을 내려줄 수도 있는데, 그 경우 파서가 null 로
  //    떨어뜨려 결과적으로는 같게 읽힌다.
  // 7. `unequippedSlots` 라는 이름과, 그 안에 **슬롯 키**가 담긴다는 것.
  //    아이템 키가 담길 수도 있다.
  // 8. 아이템 목록은 실제 응답의 일부만 골라 적었다. 파싱이 마주칠 모양을
  //    한 벌씩 담는 것이 목적이라, 실제 응답은 예순 줄이 넘는다.
  group('픽스처로 적어 둔 서버 응답', () {
    test('GET /api/cosmetics 응답을 옷장으로 읽는다', () async {
      final http =
          TestHttpClient.respondJson(loadJsonFixture(_getCosmeticsFixture));

      final loadout = await buildService(http).getCosmetics();

      expect(loadout, isNotNull);
      expect(loadout!.baseImageUrl, 'assets/Cosmetic/BASE.png');
      expect(loadout.resolvedBaseLayerOrder, 300);

      // 탭 순서가 이 순서다. 앱은 정렬하지 않는다.
      expect(
        loadout.slots.map((slot) => slot.slot),
        ['BACKGROUND', 'OUTFIT', 'BAG', 'HEAD', 'HAND', 'FRAME'],
      );
      // 개구리에 겹치지 않는 유일한 자리.
      expect(loadout.slotOf('FRAME')!.composited, isFalse);
      expect(loadout.slotOf('BACKGROUND')!.composited, isTrue);
      expect(loadout.slotOf('BACKGROUND')!.nameKo, '배경');

      // 가진 것과 못 가진 것이 함께 온다.
      expect(loadout.itemOf('bg_spring')!.owned, isTrue);
      expect(loadout.itemOf('hat_graduate')!.owned, isFalse);

      // 능력치가 없는 줄은 총 학습 레벨 기준이다.
      expect(
        loadout.itemOf('bg_spring')!.requiredAbility,
        CosmeticAbility.attendance,
      );
      expect(loadout.itemOf('hat_graduate')!.requiredAbility, isNull);
      expect(loadout.itemOf('hat_graduate')!.requiredLevel, 20);

      // 자리 하나에 그리는 층이 둘인 경우. 배낭만 제 층을 들고 있다.
      expect(loadout.itemOf('back_backpack_navy')!.layerOrderOr(450), 200);
      expect(loadout.itemOf('bag_mini_backpack')!.layerOrderOr(450), 450);

      expect(loadout.itemOf('outfit_graduate')!.fullBody, isTrue);
      expect(loadout.itemOf('outfit_graduate')!.setId, 'graduate');
      expect(loadout.itemOf('outfit_graduate')!.setNameKo, '학사 세트');
      expect(loadout.itemOf('bg_spring')!.setId, isNull);
      expect(loadout.itemOf('hat_crown')!.conflictsWith, ['hat_graduate']);

      expect(loadout.equipped, {
        'BACKGROUND': 'bg_spring',
        'BAG': 'back_backpack_navy',
        'FRAME': 'frame_spring',
      });
    });

    test('그 응답을 겹쳐 그리면 프레임은 빠지고 배낭이 개구리 뒤에 온다', () async {
      final http =
          TestHttpClient.respondJson(loadJsonFixture(_getCosmeticsFixture));

      final loadout = await buildService(http).getCosmetics();
      final layers = loadout!.resolveLayers();

      // 뒤에서 앞 순서다. 마지막의 null 이 개구리 본체(300)다.
      expect(
        layers.map((layer) => layer.itemKey),
        ['bg_spring', 'back_backpack_navy', null],
      );
      expect(layers.map((layer) => layer.layerOrder), [100, 200, 300]);
    });

    test('PUT /equip-all 응답을 장착 결과로 읽는다', () async {
      final http =
          TestHttpClient.respondJson(loadJsonFixture(_equipAllFixture));

      final result = await buildService(http).equipAll({
        'BACKGROUND': 'bg_spring',
        'BAG': 'back_backpack_navy',
        'HEAD': 'hat_graduate',
      });

      expect(result, isNotNull);
      // 못 가진 학사모는 서버가 걷어 냈다. 요청에 담아 보냈는데도 빠진
      // 자리라서 사용자에게 알려야 한다.
      expect(result!.equipped, {
        'BACKGROUND': 'bg_spring',
        'BAG': 'back_backpack_navy',
      });
      expect(result.unequippedSlots, ['HEAD']);
    });
  });

  // 네 메서드 모두 `HttpService` 의 기본 알림을 끄고 부른다. 조회 실패는 알릴
  // 일이 아니고, 저장 실패는 `CosmeticProvider` 가 옷장 화면의 문구로 따로
  // 알린다. 켜 두면 같은 실패를 두 번 말한다.
  //
  // 이 플래그는 나가는 요청에 안 실려서 TestHttpClient 로는 볼 수 없다.
  // 여기서만 HttpService 를 mock 으로 바꾼다.
  group('showErrorSnackBar', () {
    late MockHttpService httpService;
    late CosmeticService service;

    setUp(() {
      httpService = MockHttpService();
      service = CosmeticService(httpService: httpService);
    });

    test('getCosmetics 는 알림을 끄고 부른다', () async {
      when(() => httpService.sendRequest(
            method: 'GET',
            url: '$testBaseUrl/api/cosmetics',
            showErrorSnackBar: false,
          )).thenAnswer((_) async => loadoutPayload());

      expect(await service.getCosmetics(), isNotNull);

      verify(() => httpService.sendRequest(
            method: 'GET',
            url: '$testBaseUrl/api/cosmetics',
            showErrorSnackBar: false,
          )).called(1);
    });

    test('equip 은 알림을 끄고 부른다', () async {
      when(() => httpService.sendRequest(
            method: 'PUT',
            url: '$testBaseUrl/api/cosmetics/equip',
            body: {'slot': 'HEAD', 'itemKey': null},
            showErrorSnackBar: false,
          )).thenAnswer((_) async => equipResultPayload());

      expect(await service.equip(slot: 'HEAD'), isNotNull);

      verify(() => httpService.sendRequest(
            method: 'PUT',
            url: '$testBaseUrl/api/cosmetics/equip',
            body: {'slot': 'HEAD', 'itemKey': null},
            showErrorSnackBar: false,
          )).called(1);
    });

    test('equipSet 은 알림을 끄고 부른다', () async {
      when(() => httpService.sendRequest(
            method: 'PUT',
            url: '$testBaseUrl/api/cosmetics/equip-set',
            body: {'setId': 'graduate'},
            showErrorSnackBar: false,
          )).thenAnswer((_) async => equipResultPayload());

      expect(await service.equipSet('graduate'), isNotNull);

      verify(() => httpService.sendRequest(
            method: 'PUT',
            url: '$testBaseUrl/api/cosmetics/equip-set',
            body: {'setId': 'graduate'},
            showErrorSnackBar: false,
          )).called(1);
    });

    test('equipAll 은 알림을 끄고 부른다', () async {
      when(() => httpService.sendRequest(
            method: 'PUT',
            url: '$testBaseUrl/api/cosmetics/equip-all',
            body: {
              'equipped': {'HEAD': 'hat_graduate'}
            },
            showErrorSnackBar: false,
          )).thenAnswer((_) async => equipResultPayload());

      expect(await service.equipAll({'HEAD': 'hat_graduate'}), isNotNull);

      verify(() => httpService.sendRequest(
            method: 'PUT',
            url: '$testBaseUrl/api/cosmetics/equip-all',
            body: {
              'equipped': {'HEAD': 'hat_graduate'}
            },
            showErrorSnackBar: false,
          )).called(1);
    });
  });
}
