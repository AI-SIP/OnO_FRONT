import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jose/jose.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
import '../Config/AppConfig.dart';

class AppleAuthService {
  final storage = const FlutterSecureStorage();

  Future<String> signInWithApple(BuildContext context) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? idToken = appleCredential.identityToken;
      final String? email = appleCredential.email;
      final String? firstName = appleCredential.givenName;
      final String? lastName = appleCredential.familyName;
      final String? name = (lastName ?? "") + (firstName ?? "");
      final String? identifier = appleCredential.userIdentifier;

      if (idToken != null) {
        final url = Uri.parse('${AppConfig.baseUrl}/api/auth/apple');
        final response = await http.post(
          url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String?>{
            'idToken': idToken,
            'email': email,
            'name': name,
            'identifier': identifier,
          }),
        );

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          final jwtToken = responseBody['token'];

          return jwtToken;
        } else {
          return "Failed to Register user on server";
        }
      } else {
        throw Exception("Failed to get Apple idToken");
      }
    } catch (error) {
      log('Apple sign-in error: $error');
    }

    return "Apple login error";
  }

  Future<void> revokeSignInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final String authCode = appleCredential.authorizationCode;

      final String privateKey = [
        dotenv.env['APPLE_PRIVATE_KEY_LINE1']!,
        dotenv.env['APPLE_PRIVATE_KEY_LINE2']!,
        dotenv.env['APPLE_PRIVATE_KEY_LINE3']!,
        dotenv.env['APPLE_PRIVATE_KEY_LINE4']!,
        dotenv.env['APPLE_PRIVATE_KEY_LINE5']!,
        dotenv.env['APPLE_PRIVATE_KEY_LINE6']!,
      ].join('\n');

      const String teamId = 'D44353AJ7W';
      const String clientId = 'com.aisip.OnO';
      const String keyId = 'WQ42A948V9';

      final String clientSecret = createJwt(
        teamId: teamId,
        clientId: clientId,
        keyId: keyId,
        privateKey: privateKey,
      );

      final accessToken = (await requestAppleTokens(
        authCode,
        clientSecret,
        clientId,
      ))['access_token'] as String;
      const String tokenTypeHint = 'access_token';

      await revokeAppleToken(
        clientId: clientId,
        clientSecret: clientSecret,
        token: accessToken,
        tokenTypeHint: tokenTypeHint,
      );
    } on Exception catch (e) {
      print('사용자 계정 삭제 중 오류 발생: $e');
    }
  }

  // JWT 생성 함수
  String createJwt({
    required String teamId,
    required String clientId,
    required String keyId,
    required String privateKey,
  }) {
    final claims = JsonWebTokenClaims.fromJson({
      'iss': teamId,
      'iat': (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
      'aud': 'https://appleid.apple.com',
      'sub': clientId,
    });

    final builder = JsonWebSignatureBuilder()
      ..jsonContent = claims.toJson()
      ..addRecipient(JsonWebKey.fromPem(privateKey, keyId: keyId),
          algorithm: 'ES256');

    return builder.build().toCompactSerialization();
  }

  // 사용자 토큰 취소 함수
  Future<void> revokeAppleToken({
    required String clientId,
    required String clientSecret,
    required String token,
    required String tokenTypeHint,
  }) async {
    final url = Uri.parse('https://appleid.apple.com/auth/revoke');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'token': token,
        'token_type_hint': tokenTypeHint,
      },
    );

    if (response.statusCode == 200) {
      // 토큰이 성공적으로 취소됨
      print('토큰이 성공적으로 취소되었습니다.');
    } else {
      print('토큰 취소 중 오류 발생: ${response.statusCode}');
      throw Exception('토큰 취소 중 오류 발생: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> requestAppleTokens(
    String authorizationCode,
    String clientSecret,
    String clientId,
  ) async {
    final response = await http.post(
      Uri.parse('https://appleid.apple.com/auth/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': authorizationCode,
        'grant_type': 'authorization_code',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('토큰 요청 실패: ${response.body}');
    }
  }
}
