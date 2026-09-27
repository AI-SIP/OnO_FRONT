import 'dart:async' as async_lib;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import '../../Config/AppConfig.dart';
import '../../Constants/ErrorMessages.dart';
import '../../Exception/ApiException.dart';
import '../../Provider/TokenProvider.dart';
import '../../Util/AppSnackBar.dart';
import '../../Util/ErrorMessageMapper.dart';

class HttpService {
  final TokenProvider tokenProvider;

  /// 실제 HTTP 전송을 담당한다.
  /// 테스트에서 http.testing 의 MockClient 등을 주입해 응답을 고정할 수 있다.
  final http.Client _client;

  HttpService({
    http.Client? client,
    TokenProvider? tokenProvider,
  })  : _client = client ?? http.Client(),
        tokenProvider = tokenProvider ?? TokenProvider();

  String _getErrorMessage(Object error) {
    if (error is UnauthorizedException) {
      return error.getUserMessage();
    }
    if (error is NetworkException) {
      return ErrorMessageMapper.sanitizeRawMessage(
        error.getUserMessage(),
        fallback: ErrorMessages.network,
      );
    }
    if (error is TimeoutException) {
      return ErrorMessageMapper.sanitizeRawMessage(
        error.getUserMessage(),
        fallback: ErrorMessages.timeout,
      );
    }
    if (error is ServerException) {
      return ErrorMessageMapper.sanitizeRawMessage(
        error.getUserMessage(),
        fallback: ErrorMessages.server,
      );
    }
    if (error is BadRequestException) {
      return error.getUserMessage();
    }
    if (error is ParseException) {
      return ErrorMessageMapper.sanitizeRawMessage(
        error.getUserMessage(),
        fallback: ErrorMessages.parse,
      );
    }
    if (error is ApiException) {
      return error.getUserMessage();
    }
    return ErrorMessages.unknown;
  }

  Never _throwWithSnackBar(Exception error, {bool showErrorSnackBar = true}) {
    if (showErrorSnackBar) {
      AppSnackBar.showError(_getErrorMessage(error));
    }
    throw error;
  }

  Future<dynamic> sendRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool isMultipart = false,
    // multipart 로 보낼 파일을 "만드는 방법"을 받는다. 만들어진 MultipartFile 을
    // 받으면 안 된다. http 패키지의 MultipartFile 은 한 번 전송하면 finalize 되어
    // 두 번째 전송에서 StateError 를 던지는데, 토큰 갱신 후 재시도할 때 같은
    // 인스턴스를 다시 실으면 그 StateError 가 "알 수 없는 오류"로 나갔다.
    Future<List<http.MultipartFile>> Function()? filesBuilder,
    bool requiredToken = true,
    bool retry = false,
    bool showErrorSnackBar = true,
  }) async {
    String? accessToken;

    if (requiredToken) {
      accessToken = await tokenProvider.getAccessToken();

      if (accessToken == null) {
        _throwWithSnackBar(
          UnauthorizedException(message: 'Cannot find Authorization Token'),
          showErrorSnackBar: showErrorSnackBar,
        );
      }
    }

    // 서버가 요청이 어느 앱 버전에서 왔는지 보고 XP 자동 적립 여부를 가른다.
    // 버전을 못 읽었으면 빈 값 대신 키 자체를 뺀다. 헤더가 없으면 서버가
    // 구버전으로 보고 자동 적립을 켜는데, 그게 안전한 쪽이다.
    final appVersion = AppConfig.appVersion;

    Map<String, String> mergedHeaders = {
      if (requiredToken) 'Authorization': '$accessToken',
      if (!isMultipart) 'Content-Type': 'application/json; charset=UTF-8',
      if (appVersion != null) 'X-App-Version': appVersion,
      ...?headers,
    };

    Uri uri = Uri.parse(url);
    if (queryParams != null) {
      uri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...queryParams, // 기존 쿼리 파라미터에 새 쿼리 파라미터 추가
      });
    }

    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client
              .get(uri, headers: mergedHeaders)
              .timeout(const Duration(seconds: 30));
          break;

        case 'POST':
          if (isMultipart && filesBuilder != null) {
            final req = http.MultipartRequest('POST', uri)
              ..headers.addAll(mergedHeaders)
              ..files.addAll(await filesBuilder());

            // body의 각 항목을 처리
            if (body != null) {
              body.forEach((key, value) {
                if (value is List) {
                  // List인 경우 쉼표로 구분된 문자열로 변환
                  // Spring에서 @RequestParam으로 받을 때 자동으로 split됨
                  req.fields[key] = value.join(',');
                } else {
                  req.fields[key] = value.toString();
                }
              });
            }

            debugPrint('[HttpService] req: ${req.fields}');
            final streamed =
                await _client.send(req).timeout(const Duration(seconds: 90));
            response = await http.Response.fromStream(streamed);
          } else {
            response = body != null
                ? await _client
                    .post(
                      uri,
                      headers: mergedHeaders,
                      body: json.encode(body),
                    )
                    .timeout(const Duration(seconds: 30))
                : await _client
                    .post(uri, headers: mergedHeaders)
                    .timeout(const Duration(seconds: 30));
          }
          break;

        case 'PATCH':
          if (isMultipart && filesBuilder != null) {
            final req = http.MultipartRequest('PATCH', uri)
              ..headers.addAll(mergedHeaders)
              ..fields
                  .addAll(body?.map((k, v) => MapEntry(k, v.toString())) ?? {})
              ..files.addAll(await filesBuilder());
            final streamed =
                await _client.send(req).timeout(const Duration(seconds: 30));
            response = await http.Response.fromStream(streamed);
          } else {
            response = body != null
                ? await _client
                    .patch(uri, headers: mergedHeaders, body: json.encode(body))
                    .timeout(const Duration(seconds: 30))
                : await _client
                    .patch(uri, headers: mergedHeaders)
                    .timeout(const Duration(seconds: 30));
          }
          break;

        case 'PUT':
          response = body != null
              ? await _client
                  .put(uri, headers: mergedHeaders, body: json.encode(body))
                  .timeout(const Duration(seconds: 30))
              : await _client
                  .put(uri, headers: mergedHeaders)
                  .timeout(const Duration(seconds: 30));
          break;

        case 'DELETE':
          if (body != null) {
            response = await _client
                .delete(
                  uri,
                  headers: mergedHeaders,
                  body: json.encode(body),
                )
                .timeout(const Duration(seconds: 30));
          } else {
            response = await _client
                .delete(uri, headers: mergedHeaders)
                .timeout(const Duration(seconds: 30));
          }
          break;

        default:
          _throwWithSnackBar(
            ApiException(message: 'Not Supported HTTP Method: $method'),
            showErrorSnackBar: showErrorSnackBar,
          );
      }
    } on SocketException {
      _throwWithSnackBar(
        NetworkException(),
        showErrorSnackBar: showErrorSnackBar,
      );
    } on http.ClientException {
      // package:http 는 연결이 중간에 끊긴 경우 등을 ClientException 으로 던진다.
      _throwWithSnackBar(
        NetworkException(),
        showErrorSnackBar: showErrorSnackBar,
      );
    } on async_lib.TimeoutException {
      // .timeout() 이 던지는 것은 dart:async 의 TimeoutException 이다.
      // 앱 자체 TimeoutException 과 이름이 같아 접두 없이 쓰면 앱 쪽으로 해석되어
      // 이 절이 영영 걸리지 않았고, 타임아웃이 "일시적인 오류"로 뭉개졌다.
      // (Sentry FLUTTER-15Q/160/161/15T/15M)
      _throwWithSnackBar(
        TimeoutException(),
        showErrorSnackBar: showErrorSnackBar,
      );
    } on FormatException {
      _throwWithSnackBar(
        ParseException(message: ErrorMessages.parse),
        showErrorSnackBar: showErrorSnackBar,
      );
    } catch (error) {
      // 이미 우리가 정의한 커스텀 예외라면 그대로 던짐
      if (error is ApiException ||
          error is NetworkException ||
          error is TimeoutException ||
          error is UnauthorizedException ||
          error is ServerException ||
          error is BadRequestException ||
          error is ParseException) {
        rethrow;
      }
      // 알 수 없는 에러는 일반적인 ApiException으로 래핑
      _throwWithSnackBar(
        ApiException(message: ErrorMessages.unknown),
        showErrorSnackBar: showErrorSnackBar,
      );
    }

    final status = response.statusCode;

    // 요청 로깅
    debugPrint('[HttpService] [$method] $uri — Status: $status');

    // 빈 응답이거나 응답 본문이 없는 경우 처리 (예: 204 No Content)
    if (response.body.isEmpty) {
      if (status >= 200 && status < 300) {
        return null; // 성공적인 빈 응답
      } else {
        _throwWithSnackBar(
          ApiException(
            statusCode: status,
            message: response.reasonPhrase ?? '알 수 없는 오류',
          ),
          showErrorSnackBar: showErrorSnackBar,
        );
      }
    }

    // JSON 파싱 시도
    dynamic decodedBody;
    try {
      decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      // JSON 파싱 실패 시
      if (status >= 200 && status < 300) {
        // 성공 응답인데 JSON이 아니면 원본 텍스트 반환
        return utf8.decode(response.bodyBytes);
      } else {
        // 실패 응답인데 JSON이 아니면 에러 발생
        _throwWithSnackBar(
          ParseException(
            message: ErrorMessages.responseParse,
          ),
          showErrorSnackBar: showErrorSnackBar,
        );
      }
    }

    final dynamic rawErrorCode =
        decodedBody is Map ? decodedBody['errorCode'] : null;
    final int? errorCode = rawErrorCode is int
        ? rawErrorCode
        : (rawErrorCode is String ? int.tryParse(rawErrorCode) : null);

    if (status < 200 || status >= 300) {
      final serverMessage = decodedBody is Map
          ? decodedBody['message'] as String?
          : response.reasonPhrase;
      final message = _safeResponseMessage(
        status: status,
        errorCode: errorCode,
        rawMessage: serverMessage,
      );

      // 서버의 범용 오류 핸들러는 errorCode 자리에 HTTP 상태값을 그대로 넣는다.
      // dev 실측으로 405 → errorCode:405, 잘못된 파라미터 → errorCode:500 이
      // 확인됐다. 업무 에러 코드는 네 자리(1000 이상)라 세 자리 값은 에러 코드가
      // 아니라 상태 코드로 읽는다. 본문의 상태값이 응답 상태와 어긋날 때 진짜
      // 원인을 들고 있는 쪽은 본문이다.
      final effectiveStatus = _effectiveStatusOf(
        status: status,
        errorCode: errorCode,
      );

      // 액세스 토큰이 거절되면 갱신 후 한 번만 재시도한다.
      // requiredToken이 true이고, 아직 재시도하지 않았다면 토큰 갱신 후 재시도
      // - 1005 ACCESS_TOKEN_EXPIRED: 만료된 액세스 토큰에 나온다. dev 실측으로
      //   401 + 1005 를 확인했다(JwtTokenizer → JwtTokenFilter 경로).
      // - 1007 AUTHENTICATION_FAILED: Authorization 헤더가 없거나 Bearer 접두사가
      //   빠졌을 때다. 토큰 검증 중의 다른 예외(블랙리스트 조회 실패 등)도 이리로
      //   묶여서, 멀쩡한 토큰에도 1007 이 나갈 수 있다.
      // - 1009 INVALID_ACCESS_TOKEN: 서명이 훼손됐거나 형식이 틀렸거나 로그아웃된
      //   토큰이다. 리프레시 토큰이 살아 있으면 새 토큰으로 되살아나고, 아니면
      //   갱신이 인증 실패로 끝나 어차피 로그아웃된다.
      // 리프레시 토큰 계열(1001·1002·1004·1006)과 권한 부족(1008)은 액세스 토큰을
      // 새로 받아도 달라지지 않으므로 갱신하지 않는다.
      final shouldRefreshToken = errorCode == 1005 ||
          errorCode == 1007 ||
          errorCode == 1009 ||
          (errorCode == null && status == 401);
      if (requiredToken && !retry && shouldRefreshToken) {
        await tokenProvider.refreshAccessToken();
        return sendRequest(
          method: method,
          url: url,
          headers: headers,
          body: body,
          queryParams: queryParams,
          isMultipart: isMultipart,
          filesBuilder: filesBuilder,
          requiredToken: requiredToken,
          retry: true,
          showErrorSnackBar: showErrorSnackBar,
        );
      }

      // errorCode 기반으로 예외 타입 결정 (서버가 모든 에러를 400으로 통일)
      // errorCode가 있으면 우선적으로 errorCode로 판단
      if (errorCode != null) {
        // 인증 관련 에러 코드
        if (errorCode >= 1000 && errorCode < 2000) {
          _throwIfServerAuthIsTemporarilyDown(
            status: status,
            errorCode: errorCode,
            requiredToken: requiredToken,
            retry: retry,
            showErrorSnackBar: showErrorSnackBar,
          );
          if (requiredToken) {
            await tokenProvider.notifyAuthFailure();
          }
          _throwWithSnackBar(
            UnauthorizedException(
              errorCode: errorCode,
              message: message,
            ),
            showErrorSnackBar: requiredToken ? false : showErrorSnackBar,
          );
        }
        // 서버 쪽이 깨진 것(5xx)은 잘못된 요청이 아니다. 사용자가 고칠 것이
        // 없으므로 "잠시 후 다시 시도" 성격의 안내로 가야 한다. 인증 구간을
        // 가른 뒤에 보기 때문에 1xxx 가 여기로 내려올 일은 없다.
        if (effectiveStatus >= 500) {
          _throwWithSnackBar(
            ServerException(statusCode: effectiveStatus, message: message),
            showErrorSnackBar: showErrorSnackBar,
          );
        }
        // 기타 비즈니스 로직 에러는 BadRequestException으로 처리
        _throwWithSnackBar(
          BadRequestException(
            statusCode: status,
            errorCode: errorCode,
            message: message,
          ),
          showErrorSnackBar: showErrorSnackBar,
        );
      }

      // errorCode가 없을 경우 상태 코드로 판단
      if (status == 401) {
        _throwIfServerAuthIsTemporarilyDown(
          status: status,
          errorCode: errorCode,
          requiredToken: requiredToken,
          retry: retry,
          showErrorSnackBar: showErrorSnackBar,
        );
        if (requiredToken) {
          await tokenProvider.notifyAuthFailure();
        }
        _throwWithSnackBar(
          UnauthorizedException(
            errorCode: errorCode,
            message: message,
          ),
          showErrorSnackBar: requiredToken ? false : showErrorSnackBar,
        );
      } else if (status >= 400 && status < 500) {
        _throwWithSnackBar(
          BadRequestException(
            statusCode: status,
            errorCode: errorCode,
            message: message,
          ),
          showErrorSnackBar: showErrorSnackBar,
        );
      } else if (status >= 500) {
        _throwWithSnackBar(
          ServerException(
            statusCode: status,
            message: message,
          ),
          showErrorSnackBar: showErrorSnackBar,
        );
      } else {
        _throwWithSnackBar(
          ApiException(
            statusCode: status,
            errorCode: errorCode,
            message: message,
          ),
          showErrorSnackBar: showErrorSnackBar,
        );
      }
    }

    // 5. Extract data from parsed JSON
    if (decodedBody is Map<String, dynamic> &&
        decodedBody.containsKey('data')) {
      return decodedBody['data'];
    }
    return decodedBody;
  }

  /// 토큰 갱신에 성공하고 재시도했는데도 인증 오류가 온 경우, 저장된 토큰을
  /// 지우지 않고 "잠시 후 다시 시도" 성격의 예외로 끝낸다.
  ///
  /// 백엔드 JwtTokenFilter 는 토큰 검증 중 발생한 모든 예외를 catch (Exception) 으로
  /// 받아 1007 AUTHENTICATION_FAILED 로 내린다. 여기에는 Redis 블랙리스트 조회 실패도
  /// 들어가므로, Redis 가 죽어 있는 동안에는 멀쩡한 토큰을 가진 모든 요청이 1007 을
  /// 받는다. 갱신은 DB 만 보기 때문에 성공하는데, 재시도가 또 1007 이라고 방금 받은
  /// 유효한 토큰을 지워 버리면 게스트 사용자는 소셜 자격증명이 없어 계정으로 영영
  /// 돌아올 수 없다.
  ///
  /// 반대로 리프레시 토큰 자체가 거절된 코드(1001·1002·1003·1004·1006)는 새 토큰을
  /// 받을 방법이 없으므로 그대로 로그아웃시킨다.
  /// 갱신을 거치지 않고 바로 올라온 인증 오류(retry == false)도 기존대로 둔다.
  ///
  /// 탈퇴한 계정은 여기에 기대지 못한다. dev 실측으로, 지금 서버는 탈퇴해도
  /// 리프레시 토큰을 지우지 않아 갱신이 200 으로 성공한다(백엔드 AI-SIP/OnO_BACKEND#298
  /// 에서 수정 중). 고쳐지면 갱신이 1002 로 끝나 이 경로가 로그아웃을 막지 않는다.
  void _throwIfServerAuthIsTemporarilyDown({
    required int status,
    required int? errorCode,
    required bool requiredToken,
    required bool retry,
    required bool showErrorSnackBar,
  }) {
    if (!requiredToken || !retry) return;
    if (_isRefreshTokenRejected(errorCode)) return;

    _throwWithSnackBar(
      ServerException(statusCode: status, message: ErrorMessages.server),
      showErrorSnackBar: showErrorSnackBar,
    );
  }

  /// 리프레시 토큰 자체가 거절된 에러 코드.
  /// TokenProvider 가 갱신 응답에서 보는 목록과 같다.
  bool _isRefreshTokenRejected(int? errorCode) =>
      errorCode == 1001 || // INVALID_REFRESH_TOKEN
      errorCode == 1002 || // REFRESH_TOKEN_NOT_FOUND
      errorCode == 1003 || // INVALID_AUTHORITY
      errorCode == 1004 || // REFRESH_TOKEN_NOT_EQUAL
      errorCode == 1006; // REFRESH_TOKEN_EXPIRED

  /// 이 응답을 무엇으로 볼지 정할 때 쓸 상태 코드.
  ///
  /// 서버의 범용 오류 핸들러는 `errorCode` 자리에 HTTP 상태값을 그대로 넣는다.
  /// 업무 에러 코드는 네 자리(1000 이상)라 세 자리 값과 섞이지 않는다. 그래서
  /// 세 자리면 상태 코드로 읽고, 아니면 응답의 상태 코드를 그대로 쓴다.
  int _effectiveStatusOf({required int status, required int? errorCode}) {
    if (errorCode == null) return status;
    if (errorCode < 100 || errorCode >= 600) return status;
    return errorCode;
  }

  String _safeResponseMessage({
    required int status,
    required int? errorCode,
    required String? rawMessage,
  }) {
    final statusFallback = _fallbackByStatus(status);
    if (errorCode != null) {
      return ErrorMessageMapper.sanitizeRawMessage(
        rawMessage,
        fallback:
            ErrorMessageMapper.byErrorCodeOrNull(errorCode) ?? statusFallback,
        allowRawMessage: true,
      );
    }

    return ErrorMessageMapper.sanitizeRawMessage(
      rawMessage,
      fallback: statusFallback,
      allowRawMessage: true,
    );
  }

  String _fallbackByStatus(int status) {
    if (status == 401 || status == 403) {
      return ErrorMessages.authRequired;
    }
    if (status >= 400 && status < 500) {
      return ErrorMessages.badRequest;
    }
    if (status >= 500) {
      return ErrorMessages.server;
    }
    return ErrorMessages.unknown;
  }
}
