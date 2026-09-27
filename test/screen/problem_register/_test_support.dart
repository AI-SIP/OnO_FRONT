// ProblemRegister 화면 테스트 전용 공용 헬퍼.
//
// 이 디렉토리(test/screen/problem_register) 안에서만 쓴다. `_` 로 시작해
// flutter test 가 테스트 스위트로 집어먹지 않는다(테스트는 파일명이 `_test.dart`로
// 끝나야 실행된다).
//
// 여기 있는 것들이 필요한 이유:
//
// 1. TagSelectionScreen / ProblemRegisterTemplate / MultiProblemRegisterScreen 은
//    TagService·FileUploadService·ProblemService 를 생성자 주입이 아니라 상태
//    필드에서 직접 `TagService()` 식으로 만든다. `pumpOnoWidget` 의 Provider
//    치환으로는 손댈 수 없으므로, `HttpOverrides` 로 dart:io 의 HttpClient 자체를
//    가짜로 바꿔치기해 package:http 가 실제로 내보내는 요청에 미리 정해 둔 JSON
//    응답을 돌려준다. `test/helpers/widget_harness.dart` 의
//    `withMockedNetworkImages` 와 같은 기법이고, package:http 의 IOClient 가
//    쓰는 HttpClientRequest/Response 인터페이스를 조금 더 채워야 동작한다
//    (addStream, redirects 등 — 빠지면 IOClient 가 `Null is not a subtype of
//    ...` 로 죽는다).
// 2. TokenProvider 는 accessToken 이 3분 이내 만료면 refresh 를 먼저 시도한다.
//    이 파일의 fakeJwt 로 만든, 충분히 나중에 만료되는 토큰을 시크릿 스토리지에
//    미리 넣어 두면 refresh 요청 없이 바로 accessToken 을 쓴다.
// 3. image_picker 는 연합 플러그인 패턴(federated plugin)이라
//    `ImagePickerPlatform.instance` 를 가짜로 바꿔치기할 수 있다.
//    `firebase_analytics_stub.dart` 가 FirebaseAnalyticsPlatform 을 바꿔치기하는
//    것과 같은 방식이라, 실제 플랫폼 채널(MissingPluginException)을 전혀 타지
//    않는다. MultiProblemRegisterScreen 은 initState 직후 프레임 콜백에서
//    갤러리를 자동으로 여는데, 이 스텁이 없으면 그 시점에 바로 죽는다.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../helpers/helpers.dart';

/// 만료 시각을 직접 지정할 수 있는 가짜 JWT.
/// 서명 검증은 하지 않고 `exp` 클레임만 읽는 [TokenProvider] 를 속이는 용도라
/// 서명부는 아무 문자열이나 넣는다.
String fakeJwt({required int expiresInSeconds}) {
  String encodePart(Map<String, dynamic> part) {
    return base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', '');
  }

  final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresInSeconds;
  final header = encodePart({'alg': 'none', 'typ': 'JWT'});
  final payload = encodePart({'exp': exp});
  return '$header.$payload.signature';
}

/// 시크릿 스토리지에 만료되지 않은 accessToken/refreshToken 을 미리 채워 둔다.
/// TagService 등 주입 불가능한 서비스가 HttpService 를 통해 실제로 토큰을
/// 요구할 때, refresh 요청 없이 곧장 이 토큰을 쓰게 한다.
Map<String, String> seedValidAuthToken() {
  return stubSecureStorage(initialData: {
    'accessToken': fakeJwt(expiresInSeconds: 3600),
    'refreshToken': 'test-refresh-token',
  });
}

/// [body] 안에서 나가는 모든 HTTP 요청(package:http 의 기본 클라이언트 경유)에
/// 같은 JSON 응답을 돌려준다. TagService/FileUploadService/ProblemService 처럼
/// 생성자 주입이 안 되는 서비스가 실제로 내보내는 요청을 가로챌 때 쓴다.
///
/// ```dart
/// await withFakeJsonApi(() async {
///   await pumpOnoWidget(tester, const TagSelectionScreen(...));
/// }, json: [{'tagId': 1, 'name': '수학'}]);
/// ```
Future<T> withFakeJsonApi<T>(
  Future<T> Function() body, {
  Object? json,
  int statusCode = 200,
}) {
  return withFakeApi(body,
      responder: (method, url) => ApiResponse(json, statusCode));
}

/// [withFakeJsonApi] 의 일반형. HTTP 메서드/URL 별로 다른 응답을 돌려주고 싶을
/// 때(예: GET 은 목록, POST 는 생성된 항목 하나) [responder] 로 분기한다.
Future<T> withFakeApi<T>(
  Future<T> Function() body, {
  required ApiResponse Function(String method, Uri url) responder,
}) {
  return HttpOverrides.runZoned(
    body,
    createHttpClient: (_) => _FakeApiHttpClient(responder),
  );
}

class ApiResponse {
  final Object? json;
  final int statusCode;
  const ApiResponse(this.json, [this.statusCode = 200]);
}

class _FakeApiHttpClient implements HttpClient {
  final ApiResponse Function(String method, Uri url) _responder;
  _FakeApiHttpClient(this._responder);

  @override
  bool autoUncompress = true;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  Duration? connectionTimeout;
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _FakeApiRequest(_responder('GET', url));
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeApiRequest(_responder(method, url));
  @override
  void close({bool force = false}) {}
  @override
  noSuchMethod(Invocation invocation) => throw UnsupportedError(
      '테스트에서 지원하지 않는 HttpClient 호출: ${invocation.memberName}');
}

class _FakeApiRequest implements HttpClientRequest {
  final ApiResponse _response;
  _FakeApiRequest(this._response);

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeApiResponse(_response);
  @override
  Future<HttpClientResponse> get done async => _FakeApiResponse(_response);

  // package:http 의 IOClient 는 요청 바디를 이 스트림으로 흘려보낸다.
  // 응답은 이미 고정돼 있으니 그냥 다 읽어서 버린다.
  @override
  Future addStream(Stream<List<int>> stream) async {
    await stream.drain<void>();
  }

  @override
  noSuchMethod(Invocation invocation) => null;
}

class _FakeApiResponse implements HttpClientResponse {
  final List<int> _bytes;
  final int _statusCode;
  _FakeApiResponse(ApiResponse response)
      : _bytes = utf8.encode(jsonEncode(response.json)),
        _statusCode = response.statusCode;

  @override
  int get statusCode => _statusCode;
  @override
  int get contentLength => _bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  final HttpHeaders headers = _FakeHttpHeaders();
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => true;
  @override
  String get reasonPhrase => 'OK';
  @override
  List<RedirectInfo> get redirects => const [];

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_bytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  void forEach(void Function(String name, List<String> values) action) {}
  @override
  noSuchMethod(Invocation invocation) => null;
}

// ── image_picker 스텁 ──────────────────────────────────────────────

/// 1x1 투명 PNG 를 임시 디렉터리에 실제 파일로 써서 [XFile] 로 돌려준다.
/// `Image.file` 이 실제로 디코딩 가능한 바이트를 읽어야 하므로 존재하지 않는
/// 경로를 주면 안 된다.
XFile writeFakePngFile(String label) {
  final dir = Directory.systemTemp.createTempSync('ono_problem_register_test');
  addTearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  final file = File('${dir.path}/$label.png');
  file.writeAsBytesSync(kTransparentPngBytes);
  return XFile(file.path);
}

/// [ImagePickerPlatform.instance] 를 가짜로 바꿔치기해 `pickMultiImage` 계열
/// 호출을 실제 플랫폼 채널 없이 가로챈다. [queue] 에 넣어 둔 리스트를 호출
/// 순서대로 하나씩 돌려주고, 다 쓰면 빈 리스트를 돌려준다.
class StubImagePicker {
  final List<List<XFile>> queue;
  int callCount = 0;

  StubImagePicker([List<List<XFile>>? queue]) : queue = queue ?? [];

  void install() {
    ImagePickerPlatform.instance = _FakeImagePickerPlatform(this);
  }
}

class _FakeImagePickerPlatform extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  final StubImagePicker _stub;
  _FakeImagePickerPlatform(this._stub);

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    final index = _stub.callCount;
    _stub.callCount++;
    if (index >= _stub.queue.length) return [];
    return _stub.queue[index];
  }
}
