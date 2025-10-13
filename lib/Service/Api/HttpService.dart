import 'dart:async';
import 'dart:convert';
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
        throw UnauthorizedException(message: '인증 토큰을 찾을 수 없습니다. 다시 로그인해주세요.');
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
          throw ApiException(message: '지원하지 않는 HTTP 메서드입니다: $method');
      }
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw TimeoutException();
    } on FormatException catch (e) {
      throw ParseException(message: 'JSON 파싱 실패: ${e.message}');
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
      throw ApiException(message: '알 수 없는 오류가 발생했습니다: $error');
    }

    final status = response.statusCode;
    final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));

    final dynamic rawErrorCode = decodedBody['errorCode'];
    final int? errorCode = rawErrorCode is int
        ? rawErrorCode
        : (rawErrorCode is String ? int.tryParse(rawErrorCode) : null);

    if (status < 200 || status >= 300) {
      final message = decodedBody['message'] as String? ??
          response.reasonPhrase ??
          '알 수 없는 오류';

      // 토큰 만료(가정: errorCode == 1005) 이고, 아직 재시도 전이라면
      if (requiredToken && !retry && errorCode == 1005) {
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

    // 5. Parse JSON and extract data
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }
}
