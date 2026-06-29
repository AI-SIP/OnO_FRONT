import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../Config/AppConfig.dart';
import '../Exception/ApiException.dart';

class TokenProvider {
  final storage = const FlutterSecureStorage();
  static Future<void>? _refreshInFlight;
  static Future<void> Function()? _onAuthFailure;

  static void registerAuthFailureHandler(Future<void> Function() handler) {
    _onAuthFailure = handler;
  }

  Future<void> _notifyAuthFailure() async {
    if (_onAuthFailure == null) return;
    await _onAuthFailure!();
  }

  Future<void> notifyAuthFailure() async {
    await _notifyAuthFailure();
  }

  Future<String?> _safeRead(String key) async {
    try {
      return await storage.read(key: key);
    } on PlatformException catch (e) {
      debugPrint('SecureStorage read failed (key=$key): $e');
      await storage.deleteAll();
      await _notifyAuthFailure();
      throw UnauthorizedException(message: '보안 저장소가 손상되어 로그아웃되었습니다. 다시 로그인해주세요.');
    }
  }

  Future<void> setAccessToken(String accessToken) async {
    await storage.write(key: 'accessToken', value: accessToken);
  }

  Future<String?> getAccessToken() async {
    String? accessToken = await _safeRead('accessToken');

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
        return await _safeRead('accessToken') ?? accessToken;
      } catch (e) {
        if (e is UnauthorizedException) {
          rethrow;
        }
        debugPrint('Pre-refresh failed, fallback to existing access token: $e');
        return accessToken;
      }
    }

    debugPrint('Access token is missing. Try refresh.');
    await refreshAccessToken();

    return await _safeRead('accessToken');
  }

  Future<void> setRefreshToken(String refreshToken) async {
    await storage.write(key: 'refreshToken', value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return await _safeRead('refreshToken');
  }

  Future<void> refreshAccessTokenIfNeeded({
    Duration threshold = const Duration(minutes: 5),
  }) async {
    final accessToken = await _safeRead('accessToken');
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
    String? refreshToken = await _safeRead('refreshToken');
    if (refreshToken == null) {
      debugPrint('No refresh token available.');
      await _notifyAuthFailure();
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
      int? errorCode;
      try {
        final errJson = jsonDecode(utf8.decode(response.bodyBytes));
        if (errJson is Map<String, dynamic>) {
          final rawErrorCode = errJson['errorCode'];
          if (rawErrorCode is int) {
            errorCode = rawErrorCode;
          } else if (rawErrorCode is String) {
            errorCode = int.tryParse(rawErrorCode);
          }
        }
        errorMessage = errJson['message'] as String? ?? 'Unknown error';
      } catch (_) {
        errorMessage = response.reasonPhrase ?? 'Unknown error';
      }
      final isRefreshTokenInvalid = _isRefreshTokenInvalidResponse(
        statusCode: response.statusCode,
        errorCode: errorCode,
        message: errorMessage,
      );
      if (response.statusCode == 401 || isRefreshTokenInvalid) {
        await deleteToken();
        await _notifyAuthFailure();
        throw UnauthorizedException(
          errorCode: errorCode,
          message: errorMessage,
        );
      }
      throw ApiException(
        statusCode: response.statusCode,
        errorCode: errorCode,
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
    debugPrint('Access token refreshed.');
  }

  bool _isRefreshTokenInvalidResponse({
    required int statusCode,
    required int? errorCode,
    required String message,
  }) {
    final normalizedMessage = message.toLowerCase();
    final isRefreshTokenMessage = normalizedMessage.contains('리프레시 토큰') ||
        normalizedMessage.contains('리프레시토큰') ||
        normalizedMessage.contains('refresh token');
    // 서버 구현에 따라 400 + 리프레시 토큰 메시지로 내려오는 케이스를 인증 만료로 처리
    return (statusCode == 400 || statusCode == 403) &&
        (isRefreshTokenMessage ||
            errorCode == 1001 ||
            errorCode == 1002 ||
            errorCode == 1003 ||
            errorCode == 1004 ||
            errorCode == 1006);
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
