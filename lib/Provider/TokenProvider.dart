import 'dart:convert';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../Config/AppConfig.dart';
import '../Exception/ApiException.dart';

class TokenProvider {
  final storage = const FlutterSecureStorage();

  Future<void> setAccessToken(String accessToken) async {
    await storage.write(key: 'accessToken', value: accessToken);
  }

  Future<String?> getAccessToken() async {
    String? accessToken = await storage.read(key: 'accessToken');

    if (accessToken != null) {
      return accessToken;
    }

    log('Access token is not available.');
    await refreshAccessToken();

    accessToken = await storage.read(key: 'accessToken');
    return accessToken;
  }

  Future<void> setRefreshToken(String refreshToken) async {
    await storage.write(key: 'refreshToken', value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return await storage.read(key: 'refreshToken');
  }

  Future<void> refreshAccessToken() async {
    String? refreshToken = await storage.read(key: 'refreshToken');
    if (refreshToken == null) {
      log('No refresh token available.');
      throw UnauthorizedException(message: '로그인이 필요합니다. 다시 로그인해주세요.');
    }

    final response = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}/api/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // 응답 본문을 JSON 으로 파싱
      String errorMessage;
      try {
        final errJson = jsonDecode(utf8.decode(response.bodyBytes));
        errorMessage = errJson['message'] as String? ?? 'Unknown error';
      } catch (_) {
        errorMessage = response.reasonPhrase ?? 'Unknown error';
      }

      await deleteToken();
      if (response.statusCode == 401) {
        throw UnauthorizedException(message: errorMessage);
      }
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMessage,
      );
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw ParseException(message: '토큰 갱신 응답 형식이 올바르지 않습니다.');
    }

    final newAccessToken = data['accessToken'] as String?;
    final newRefreshToken = data['refreshToken'] as String?;

    if (newAccessToken == null || newRefreshToken == null) {
      throw ParseException(message: '토큰 갱신 응답에 필수 토큰이 없습니다.');
    }

    await setAccessToken(newAccessToken);
    await setRefreshToken(newRefreshToken);
    log('Access token refreshed.');
  }

  Future<void> deleteToken() async {
    await storage.delete(key: 'accessToken');
    await storage.delete(key: 'refreshToken');
  }
}
