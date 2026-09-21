import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:ono/Model/User/UserRegisterModel.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../Util/AppSnackBar.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserRegisterModel?> signInWithGoogle(BuildContext context) async {
    final GoogleSignInAccount? googleSignInAccount;
    try {
      googleSignInAccount = await _googleSignIn.signIn();
    } on PlatformException catch (error) {
      // 12501 은 사용자가 창을 닫은 것이고 12502 는 이미 다른 로그인 창이 떠
      // 있는 것이다. 둘 다 결함이 아니라서 취소로 돌려 조용히 끝낸다.
      if (_isCanceled(error)) return null;
      rethrow;
    }
    if (googleSignInAccount != null) {
      String? email = googleSignInAccount.email;
      String? name = googleSignInAccount.displayName;
      String? identifier = googleSignInAccount.id;

      return UserRegisterModel(
          email: email, name: name, identifier: identifier, platform: 'GOOGLE');
    } else {
      return null;
    }
  }

  static bool _isCanceled(PlatformException error) {
    if (error.code == GoogleSignIn.kSignInCanceledError) return true;
    final message = error.message ?? '';
    return message.contains('12501') || message.contains('12502');
  }

  Future<void> logoutGoogleSignIn() async {
    _googleSignIn.signOut();
  }

  Future<void> revokeGoogleSignIn() async {
    try {
      final googleSignInAccount = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;

      final String? accessToken = googleSignInAuthentication.accessToken;

      final url = Uri.parse('https://oauth2.googleapis.com/revoke');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'token': accessToken,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Google sign-out Success!');
      } else {
        debugPrint('Failed to revoke Google token');
        throw Exception('Failed to revoke Google token');
      }
    } catch (error, stackTrace) {
      debugPrint('Google sign-out error: $error');
      AppSnackBar.showError('구글 계정 연동 해제에 실패했습니다.');
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
    }
  }
}
