import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// HttpService 가 실제로 내보낸 요청을 기록해 둔 것.
/// URL, 메서드, 헤더, 바디가 계약대로인지 검증할 때 쓴다.
class CapturedRequest {
  final String method;
  final Uri url;
  final Map<String, String> headers;
  final Uint8List bodyBytes;

  CapturedRequest({
    required this.method,
    required this.url,
    required this.headers,
    required this.bodyBytes,
  });

  String get body => utf8.decode(bodyBytes, allowMalformed: true);

  /// JSON 바디를 Map 으로 읽는다. 바디가 비어 있으면 null 이다.
  Map<String, dynamic>? get jsonBody {
    if (bodyBytes.isEmpty) return null;
    return jsonDecode(body) as Map<String, dynamic>;
  }

  /// Authorization 헤더. HttpService 는 대문자 A 로 넣지만 대소문자 모두 본다.
  String? get authorization =>
      headers['Authorization'] ?? headers['authorization'];

  String? get contentType => headers['Content-Type'] ?? headers['content-type'];

  /// 쿼리 파라미터. `?cursor=10&size=20` 같은 것을 검증할 때 쓴다.
  Map<String, String> get queryParameters => url.queryParameters;

  @override
  String toString() => '$method $url';
}

/// 응답을 고정해 두고 요청을 기록하는 http.Client.
///
/// ```dart
/// final http = TestHttpClient.respondJson({'data': {'problemId': 1}});
/// final service = ProblemService(httpService: HttpService(
///   client: http.client,
///   tokenProvider: buildMockTokenProvider(),
/// ));
///
/// await service.getProblem(1);
/// expect(http.lastRequest.method, 'GET');
/// expect(http.lastRequest.url.path, '/api/problems/1');
/// ```
class TestHttpClient {
  final List<CapturedRequest> captured = [];
  late final MockClient client;

  TestHttpClient._(Future<http.Response> Function(CapturedRequest) handler) {
    client = MockClient((http.Request request) async {
      final record = CapturedRequest(
        method: request.method,
        url: request.url,
        headers: Map<String, String>.from(request.headers),
        bodyBytes: Uint8List.fromList(request.bodyBytes),
      );
      captured.add(record);
      return handler(record);
    });
  }

  /// 요청 내용에 따라 응답을 다르게 주고 싶을 때.
  factory TestHttpClient.handler(
    Future<http.Response> Function(CapturedRequest request) handler,
  ) =>
      TestHttpClient._(handler);

  /// 모든 요청에 같은 응답을 준다.
  factory TestHttpClient.respondWith(http.Response response) =>
      TestHttpClient._((_) async => response);

  /// 모든 요청에 같은 JSON 응답을 준다.
  factory TestHttpClient.respondJson(
    Object? body, {
    int statusCode = 200,
  }) =>
      TestHttpClient._(
        (_) async => jsonResponse(body, statusCode: statusCode),
      );

  /// 요청 순서대로 응답을 하나씩 준다.
  /// 401 뒤에 토큰을 갱신하고 재시도하는 흐름처럼, 호출마다 응답이 달라야 할 때 쓴다.
  /// 준비한 응답을 다 쓰면 마지막 응답을 반복한다.
  factory TestHttpClient.sequence(List<http.Response> responses) {
    assert(responses.isNotEmpty, 'sequence 에는 응답이 최소 하나 필요하다');
    var index = 0;
    return TestHttpClient._((_) async {
      final response =
          responses[index < responses.length ? index : responses.length - 1];
      index++;
      return response;
    });
  }

  /// 전송 자체가 실패하는 상황(SocketException, ClientException 등)을 만든다.
  factory TestHttpClient.throwing(Object error) =>
      TestHttpClient._((_) async => throw error);

  int get callCount => captured.length;

  CapturedRequest get lastRequest {
    if (captured.isEmpty) {
      throw StateError('요청이 한 번도 오지 않았다');
    }
    return captured.last;
  }

  CapturedRequest get firstRequest {
    if (captured.isEmpty) {
      throw StateError('요청이 한 번도 오지 않았다');
    }
    return captured.first;
  }
}

/// JSON 응답을 만든다.
///
/// charset 을 반드시 utf-8 로 박는다. package:http 의 Response 는 content-type 에
/// charset 이 없으면 latin1 으로 인코딩해서, 한글이 들어간 응답이 깨진다.
http.Response jsonResponse(
  Object? body, {
  int statusCode = 200,
  Map<String, String>? headers,
}) {
  return http.Response(
    body == null ? '' : jsonEncode(body),
    statusCode,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      ...?headers,
    },
  );
}

/// 바디가 없는 응답. 204 No Content 처럼.
http.Response emptyResponse({int statusCode = 204}) =>
    http.Response('', statusCode);

/// JSON 이 아닌 응답. 파싱 실패 경로를 볼 때 쓴다.
http.Response textResponse(String body, {int statusCode = 200}) =>
    http.Response(
      body,
      statusCode,
      headers: {'content-type': 'text/plain; charset=utf-8'},
    );

/// 서버가 쓰는 `{ errorCode, message, data }` 래퍼를 씌운다.
/// HttpService 는 `data` 키가 있으면 그 안쪽만 돌려주므로, Service 테스트에서는
/// 실제 응답 모양을 그대로 쓰는 편이 계약 검증에 정확하다.
Map<String, dynamic> apiEnvelope(
  Object? data, {
  int? errorCode,
  String? message,
}) =>
    {
      'errorCode': errorCode,
      'message': message,
      'data': data,
    };

/// 서버 에러 응답. errorCode 로 예외 타입이 갈리는 경로를 볼 때 쓴다.
http.Response errorResponse({
  required int statusCode,
  int? errorCode,
  String? message,
}) =>
    jsonResponse(
      {
        'errorCode': errorCode,
        'message': message,
      },
      statusCode: statusCode,
    );
