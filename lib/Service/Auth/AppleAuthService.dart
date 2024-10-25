import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jose/jose.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
import '../../Config/AppConfig.dart';
import '../../GlobalModule/Theme/SnackBarDialog.dart';

class AppleAuthService {
  final storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> signInWithApple(BuildContext context) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      //final String? idToken = appleCredential.identityToken;
      final String? email = appleCredential.email;
      final String? firstName = appleCredential.givenName;
      final String? lastName = appleCredential.familyName;
      final String? name = (lastName ?? "") + (firstName ?? "");
      final String? identifier = appleCredential.userIdentifier;

      final url = Uri.parse('${AppConfig.baseUrl}/api/auth/apple');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'email': email,
          'name': name,
          'identifier': identifier,
        }),
      );

      if (response.statusCode == 200) {
        log('Apple sign-in Success!');
        FirebaseAnalytics.instance.logSignUp(signUpMethod: 'Apple');
        FirebaseAnalytics.instance
            .logEvent(name: 'user_register_with_apple');
        //SnackBarDialog.showSnackBar(context: context, message: "로그인에 성공했습니다.", backgroundColor: Colors.green);

        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to Register user on server");
      }
    } catch (error, stackTrace) {
      if(error == AuthorizationErrorCode.canceled){
        return null;
      }
      if(error == AuthorizationErrorCode.unknown){
        return null;
      }

      log('Apple sign-in error: $error');
      SnackBarDialog.showSnackBar(context: context, message: "로그인 과정에서 오류가 발생했습니다. 다시 시도해주세요.", backgroundColor: Colors.red);
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
      return null;
    }
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
    } on Exception catch (e, stackTrace) {
      log('사용자 계정 삭제 중 오류 발생: $e');
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
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
      log('토큰이 성공적으로 취소되었습니다.');
    } else {
      log('토큰 취소 중 오류 발생: ${response.statusCode}');
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
