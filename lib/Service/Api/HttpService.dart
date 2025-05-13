import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

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
        throw Exception('Access token is not available');
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
          break;

        default:
          throw Exception('Unsupported HTTP method: $method');
      }
    } catch (error) {
      throw Exception('An error occurred: $error');
    }

    final status = response.statusCode;
    final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));

    final dynamic rawErrorCode = decodedBody['errorCode'];
    final int? errorCode = rawErrorCode is int
        ? rawErrorCode
        : (rawErrorCode is String ? int.tryParse(rawErrorCode) : null);

    if (status < 200 || status >= 300) {
      final message =
          decodedBody['message'] as String? ?? response.reasonPhrase;

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

      throw Exception('HTTP $status: $message (code=$errorCode)');
    }

    // 5. Parse JSON and extract data
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }
}
