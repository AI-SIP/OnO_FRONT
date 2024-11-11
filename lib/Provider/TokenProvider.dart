import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import '../Config/AppConfig.dart';

class TokenProvider {
  final storage = const FlutterSecureStorage();

  Future<void> setAccessToken(String accessToken) async {
    await storage.write(key: 'accessToken', value: accessToken);
  }

  Future<String?> getAccessToken() async {
    try {
      String? accessToken = await storage.read(key: 'accessToken');

      if (accessToken == null) {
        log('Access token is not available.');
        await refreshAccessToken();

        accessToken = await storage.read(key: 'accessToken');
      }

      final url = Uri.parse('${AppConfig.baseUrl}/api/auth/verifyAccessToken');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return accessToken;
      } else {
        log('Access token is invalid or expired, trying to refresh...');
        bool isRefreshAccessToken = await refreshAccessToken();
        if (isRefreshAccessToken) {
          accessToken = await storage.read(key: 'accessToken');
          return accessToken;
        } else {
          throw Exception("Can not refresh access token");
        }
      }
    } on SocketException catch(_){
      return null;
    } catch (error, stackTrace) {
      log('getAccessToken() error: $error');
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  Future<void> setRefreshToken(String refreshToken) async {
    await storage.write(key: 'refreshToken', value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return await storage.read(key: 'refreshToken');
  }

  Future<bool> refreshAccessToken() async {
    try {
      String? refreshToken = await storage.read(key: 'refreshToken');
      if (refreshToken == null) {
        log('No refresh token available.');
        return false;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        await setAccessToken(data['accessToken']);
        await setRefreshToken(data['refreshToken']);
        log('Access token refreshed.');
        return true;
      } else {
        throw Exception('Failed to refresh token. Logging out.');
      }
    } catch (error, stackTrace) {
      log('Error refreshing token: $error');
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> deleteToken() async{
    await storage.delete(key: 'accessToken');
    await storage.delete(key: 'refreshToken');
  }
}
