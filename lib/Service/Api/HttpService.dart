import 'dart:async' as async_lib;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import '../../Constants/ErrorMessages.dart';
import '../../Exception/ApiException.dart';
import '../../Provider/TokenProvider.dart';
import '../../Util/AppSnackBar.dart';
import '../../Util/ErrorMessageMapper.dart';

class HttpService {
  final TokenProvider tokenProvider = TokenProvider();

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
    List<http.MultipartFile>? files,
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

    Map<String, String> mergedHeaders = {
      if (requiredToken) 'Authorization': '$accessToken',
      if (!isMultipart) 'Content-Type': 'application/json; charset=UTF-8',
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
          response = await http
              .get(uri, headers: mergedHeaders)
              .timeout(const Duration(seconds: 30));
          break;

        case 'POST':
          if (isMultipart && files != null) {
            final req = http.MultipartRequest('POST', uri)
              ..headers.addAll(mergedHeaders)
              ..files.addAll(files);

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
                await req.send().timeout(const Duration(seconds: 90));
            response = await http.Response.fromStream(streamed);
          } else {
            response = body != null
                ? await http
                    .post(
                      uri,
                      headers: mergedHeaders,
                      body: json.encode(body),
                    )
                    .timeout(const Duration(seconds: 30))
                : await http
                    .post(uri, headers: mergedHeaders)
                    .timeout(const Duration(seconds: 30));
          }
          break;

        case 'PATCH':
          if (isMultipart && files != null) {
            final req = http.MultipartRequest('PATCH', uri)
              ..headers.addAll(mergedHeaders)
              ..fields
                  .addAll(body?.map((k, v) => MapEntry(k, v.toString())) ?? {})
              ..files.addAll(files);
            final streamed =
                await req.send().timeout(const Duration(seconds: 30));
            response = await http.Response.fromStream(streamed);
          } else {
            response = body != null
                ? await http
                    .patch(uri, headers: mergedHeaders, body: json.encode(body))
                    .timeout(const Duration(seconds: 30))
                : await http
                    .patch(uri, headers: mergedHeaders)
                    .timeout(const Duration(seconds: 30));
          }
          break;

        case 'PUT':
          response = body != null
              ? await http
                  .put(uri, headers: mergedHeaders, body: json.encode(body))
                  .timeout(const Duration(seconds: 30))
              : await http
                  .put(uri, headers: mergedHeaders)
                  .timeout(const Duration(seconds: 30));
          break;

        case 'DELETE':
          if (body != null) {
            response = await http
                .delete(
                  uri,
                  headers: mergedHeaders,
                  body: json.encode(body),
                )
                .timeout(const Duration(seconds: 30));
          } else {
            response = await http
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

      // 토큰 만료 시 재시도 (ACCESS_TOKEN_EXPIRED 또는 코드 없는 401)
      // requiredToken이 true이고, 아직 재시도하지 않았다면 토큰 갱신 후 재시도
      final shouldRefreshToken =
          errorCode == 1005 || (errorCode == null && status == 401);
      if (requiredToken && !retry && shouldRefreshToken) {
        await tokenProvider.refreshAccessToken();
        return sendRequest(
          method: method,
          url: url,
          headers: headers,
          body: body,
          queryParams: queryParams,
          isMultipart: isMultipart,
          files: files,
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
