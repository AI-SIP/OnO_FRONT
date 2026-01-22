import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../Exception/ApiException.dart';
import '../../Provider/TokenProvider.dart';

class HttpService {
  final TokenProvider tokenProvider = TokenProvider();

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
  }) async {
    String? accessToken;

    if (requiredToken) {
      accessToken = await tokenProvider.getAccessToken();

      if (accessToken == null) {
        throw UnauthorizedException(message: 'Cannot find Authorization Token');
      }
    }

    Map<String, String> mergedHeaders = {
      if (requiredToken) 'Authorization': '$accessToken',
      'Content-Type': 'application/json; charset=UTF-8',
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
              ..fields
                  .addAll(body?.map((k, v) => MapEntry(k, v.toString())) ?? {})
              ..files.addAll(files);
            final streamed =
                await req.send().timeout(const Duration(seconds: 90));
            response = await http.Response.fromStream(streamed);
          } else {
            response = await http.post(
              uri,
              headers: mergedHeaders,
              body: json.encode(body),
            );
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
            response = await http
                .patch(uri, headers: mergedHeaders, body: json.encode(body))
                .timeout(const Duration(seconds: 30));
          }
          break;

        case 'DELETE':
          response = await http
              .delete(uri, headers: mergedHeaders)
              .timeout(const Duration(seconds: 30));
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

        default:
          throw ApiException(message: 'Not Supported HTTP Method: $method');
      }
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw TimeoutException();
    } on FormatException catch (e) {
      throw ParseException(message: 'JSON Parsing Failed: ${e.message}');
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
      throw ApiException(message: 'Unknown error: $error');
    }

    final status = response.statusCode;

    // 요청 로깅
    developer.log(
      '[$method] $uri',
      name: 'HttpService',
      error: 'Status: $status',
    );

    // 빈 응답이거나 응답 본문이 없는 경우 처리 (예: 204 No Content)
    if (response.body.isEmpty) {
      if (status >= 200 && status < 300) {
        return null; // 성공적인 빈 응답
      } else {
        throw ApiException(
          statusCode: status,
          message: response.reasonPhrase ?? '알 수 없는 오류',
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
        throw ParseException(
          message:
              'Failed to parse response as JSON: ${utf8.decode(response.bodyBytes)}',
        );
      }
    }

    final dynamic rawErrorCode =
        decodedBody is Map ? decodedBody['errorCode'] : null;
    final int? errorCode = rawErrorCode is int
        ? rawErrorCode
        : (rawErrorCode is String ? int.tryParse(rawErrorCode) : null);

    if (status < 200 || status >= 300) {
      final message = decodedBody['message'] as String? ??
          response.reasonPhrase ??
          '알 수 없는 오류';

      // 토큰 만료 시 재시도 (status 401 또는 errorCode 1005)
      // requiredToken이 true이고, 아직 재시도하지 않았다면 토큰 갱신 후 재시도
      if (requiredToken && !retry && (status == 401 || errorCode == 1005)) {
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
        );
      }

      // errorCode 기반으로 예외 타입 결정 (서버가 모든 에러를 400으로 통일)
      // errorCode가 있으면 우선적으로 errorCode로 판단
      if (errorCode != null) {
        // 인증 관련 에러 코드 (예: 1004, 1005)
        if (errorCode >= 1000 && errorCode < 2000) {
          throw UnauthorizedException(message: message);
        }
        // 기타 비즈니스 로직 에러는 BadRequestException으로 처리
        throw BadRequestException(
          statusCode: status,
          errorCode: errorCode,
          message: message,
        );
      }

      // errorCode가 없을 경우 상태 코드로 판단
      if (status == 401) {
        throw UnauthorizedException(message: message);
      } else if (status >= 400 && status < 500) {
        throw BadRequestException(
          statusCode: status,
          errorCode: errorCode,
          message: message,
        );
      } else if (status >= 500) {
        throw ServerException(
          statusCode: status,
          message: message,
        );
      } else {
        throw ApiException(
          statusCode: status,
          errorCode: errorCode,
          message: message,
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
}
