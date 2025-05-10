import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException {
      throw Exception('Socket Exception!');
    } catch (error) {
      throw Exception('An error occurred: $error');
    }

    // 4. Check for HTTP errors
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // 응답 본문을 JSON 으로 파싱
      String errorMessage;
      try {
        final errJson = jsonDecode(utf8.decode(response.bodyBytes));
        errorMessage = errJson['message'] as String? ?? 'Unknown error';
      } catch (_) {
        errorMessage = response.reasonPhrase ?? 'Unknown error';
      }
      throw Exception('HTTP ${response.statusCode}: $errorMessage');
    }

    // 5. Parse JSON and extract data
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }
}
