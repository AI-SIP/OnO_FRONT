import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:ono/Model/User/UserRegisterModel.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../Util/AppSnackBar.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserRegisterModel?> signInWithGoogle(BuildContext context) async {
    final googleSignInAccount = await _googleSignIn.signIn();
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
