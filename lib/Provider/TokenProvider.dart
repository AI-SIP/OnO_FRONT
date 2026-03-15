import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../Config/AppConfig.dart';
import '../Exception/ApiException.dart';

class TokenProvider {
  final storage = const FlutterSecureStorage();
  static Future<void>? _refreshInFlight;

  Future<void> setAccessToken(String accessToken) async {
    await storage.write(key: 'accessToken', value: accessToken);
  }

  Future<String?> getAccessToken() async {
    String? accessToken = await storage.read(key: 'accessToken');

    // access token이 충분히 유효하면 그대로 사용
    if (accessToken != null &&
        !_isTokenExpiringSoon(accessToken, const Duration(minutes: 3))) {
      return accessToken;
    }

    // access token이 존재하면, 선갱신 실패 시에도 기존 토큰으로 요청을 진행시켜
    // "토큰 갱신 실패 때문에 요청 자체가 취소"되는 상황을 줄인다.
    if (accessToken != null) {
      try {
        await refreshAccessToken();
        return await storage.read(key: 'accessToken') ?? accessToken;
      } catch (e) {
        log('Pre-refresh failed, fallback to existing access token: $e');
        return accessToken;
      }
    }

    log('Access token is missing. Try refresh.');
    await refreshAccessToken();

    return await storage.read(key: 'accessToken');
  }

  Future<void> setRefreshToken(String refreshToken) async {
    await storage.write(key: 'refreshToken', value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return await storage.read(key: 'refreshToken');
  }

  Future<void> refreshAccessTokenIfNeeded({
    Duration threshold = const Duration(minutes: 5),
  }) async {
    final accessToken = await storage.read(key: 'accessToken');
    if (accessToken != null && !_isTokenExpiringSoon(accessToken, threshold)) {
      return;
    }

    await refreshAccessToken();
  }

  Future<void> refreshAccessToken() async {
    if (_refreshInFlight != null) {
      await _refreshInFlight;
      return;
    }

    _refreshInFlight = _refreshAccessTokenInternal();
    try {
      await _refreshInFlight;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<void> _refreshAccessTokenInternal() async {
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
      String errorMessage;
      try {
        final errJson = jsonDecode(utf8.decode(response.bodyBytes));
        errorMessage = errJson['message'] as String? ?? 'Unknown error';
      } catch (_) {
        errorMessage = response.reasonPhrase ?? 'Unknown error';
      }
      if (response.statusCode == 401) {
        await deleteToken();
        throw UnauthorizedException(message: errorMessage);
      }
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMessage,
      );
    }

    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
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

  bool _isTokenExpiringSoon(String token, Duration threshold) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) {
        return false;
      }

      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = payloadMap['exp'];
      if (exp is! num) return false;

      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return nowSec >= (exp.toInt() - threshold.inSeconds);
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteToken() async {
    await storage.delete(key: 'accessToken');
    await storage.delete(key: 'refreshToken');
  }
}
