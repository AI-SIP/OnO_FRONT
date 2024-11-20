import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../Provider/TokenProvider.dart';

class HttpService {
  final TokenProvider tokenProvider = TokenProvider();

  Future<http.Response> sendRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool isMultipart = false,
    List<http.MultipartFile>? files,
  }) async {
    final accessToken = await tokenProvider.getAccessToken();
    if (accessToken == null) {
      throw Exception('Access token is not available');
    }

    Map<String, String> mergedHeaders = {
      'Authorization': 'Bearer $accessToken',
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

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return await http
              .get(uri, headers: mergedHeaders)
              .timeout(const Duration(seconds: 90));
        case 'POST':
          if (isMultipart && files != null) {
            var request = http.MultipartRequest('POST', uri);
            request.headers.addAll(mergedHeaders);
            if (body != null) {
              request.fields.addAll(
                  body.map((key, value) => MapEntry(key, value.toString())));
            }
            request.files.addAll(files);
            final streamedResponse =
                await request.send().timeout(const Duration(seconds: 90));
            return await http.Response.fromStream(streamedResponse);
          } else {
            return await http.post(uri,
                headers: mergedHeaders, body: json.encode(body));
          }
        case 'PATCH':
          if (isMultipart && files != null) {
            var request = http.MultipartRequest('PATCH', uri);
            request.headers.addAll(mergedHeaders);
            if (body != null) {
              request.fields.addAll(
                  body.map((key, value) => MapEntry(key, value.toString())));
            }
            request.files.addAll(files);
            final streamedResponse =
                await request.send().timeout(const Duration(seconds: 90));
            return await http.Response.fromStream(streamedResponse);
          } else {
            return await http
                .patch(uri, headers: mergedHeaders, body: json.encode(body))
                .timeout(const Duration(seconds: 90));
          }
        case 'DELETE':
          return await http
              .delete(uri, headers: mergedHeaders)
              .timeout(const Duration(seconds: 90));
        default:
          throw Exception('Unsupported HTTP method');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException {
      throw Exception('Socket Exception!');
    } catch (error) {
      throw Exception('An error occurred: $error');
    }
  }
}
