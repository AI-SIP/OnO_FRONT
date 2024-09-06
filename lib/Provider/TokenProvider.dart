import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../Config/AppConfig.dart';

class TokenProvider {
  final storage = const FlutterSecureStorage();

  Future<void> setAccessToken(String accessToken) async {
    await storage.write(key: 'accessToken', value: accessToken);
  }

  Future<String?> getAccessToken() async {
    String? accessToken = await storage.read(key: 'accessToken');

    if (accessToken == null) {
      log('Access token is not available.');
      return null;
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/auth/verifyAccessToken');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      return accessToken;
    } else {
      log('Access token is invalid or expired, trying to refresh...');
      bool isRefreshAccessToken = await refreshAccessToken();
      if (isRefreshAccessToken) {
        accessToken = await storage.read(key: 'accessToken');
        return accessToken;
      } else {
        return null;
      }
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
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        await setAccessToken(data['accessToken']);
        log('Access token refreshed.');
        return true;
      } else {
        log('Failed to refresh token. Logging out.');
        return false;
      }
    } catch (e) {
      log('Error refreshing token: $e');
      return false;
    }
  }
}
