import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../Config/AppConfig.dart';
import '../../GlobalModule/Theme/SnackBarDialog.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<Map<String, dynamic>?> signInWithGoogle(BuildContext context) async {
    try {
      final googleSignInAccount = await _googleSignIn.signIn();
      if(googleSignInAccount != null){
        final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

        String? email = googleSignInAccount.email;
        String? name = googleSignInAccount.displayName;
        String? identifier = googleSignInAccount.id;

        final url = Uri.parse('${AppConfig.baseUrl}/api/auth/google');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'email': email,
            'name': name,
            'identifier': identifier
          }),
        );

        if (response.statusCode == 200) {
          log('Google sign-in Success!');
          FirebaseAnalytics.instance.logSignUp(signUpMethod: 'Google');
          FirebaseAnalytics.instance
              .logEvent(name: 'user_register_with_google');
          //SnackBarDialog.showSnackBar(context: context, message: "로그인에 성공했습니다.", backgroundColor: Colors.green);

          return jsonDecode(response.body);
        } else {
          throw Exception("Failed to Register user on server");
        }
      } else{
        return null;
      }
    } catch (error, stackTrace) {
      SnackBarDialog.showSnackBar(context: context, message: "로그인 과정에서 오류가 발생했습니다. 다시 시도해주세요.", backgroundColor: Colors.red);
      log(error.toString());
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
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
        log('Google sign-out Success!');
      } else {
        log('Failed to revoke Google token');
        throw new Exception('Failed to revoke Google token');
      }
    } catch (error, stackTrace) {
      log('Google sign-out error: $error');
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
    }
  }
}
