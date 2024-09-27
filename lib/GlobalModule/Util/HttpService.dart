import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../Provider/TokenProvider.dart';

class HttpService {
  final TokenProvider tokenProvider = TokenProvider();

  Future<http.Response> sendRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
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

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(Uri.parse(url), headers: mergedHeaders);
      case 'POST':
        if (isMultipart && files != null) {
          var request = http.MultipartRequest('POST', Uri.parse(url));
          request.headers.addAll(mergedHeaders);
          if (body != null) {
            request.fields.addAll(body.map((key, value) => MapEntry(key, value.toString())));
          }
          request.files.addAll(files);
          final streamedResponse = await request.send();
          return await http.Response.fromStream(streamedResponse);
        } else {
          return await http.post(Uri.parse(url), headers: mergedHeaders, body: json.encode(body));
        }
      case 'PATCH':
        if (isMultipart && files != null) {
          var request = http.MultipartRequest('PATCH', Uri.parse(url));
          request.headers.addAll(mergedHeaders);
          if (body != null) {
            request.fields.addAll(body.map((key, value) => MapEntry(key, value.toString())));
          }
          request.files.addAll(files);
          final streamedResponse = await request.send();
          return await http.Response.fromStream(streamedResponse);
        }
        else{
          return await http.patch(Uri.parse(url), headers: mergedHeaders, body: json.encode(body));
        }
      case 'DELETE':
        return await http.delete(Uri.parse(url), headers: mergedHeaders);
      default:
        throw Exception('Unsupported HTTP method');
    }
  }
}