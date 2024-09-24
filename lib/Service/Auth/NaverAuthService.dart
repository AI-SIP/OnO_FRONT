import 'dart:convert';
import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../Config/AppConfig.dart';

class NaverAuthService{
  Future<Map<String, dynamic>?> signInWithNaver() async{
    try{
      final NaverLoginResult result= await FlutterNaverLogin.logIn();

      if (result.status == NaverLoginStatus.loggedIn) {

        const String email = 'ono@naver.com';
        final String identifier = result.account.id;
        final String name = result.account.name;

        final url = Uri.parse('${AppConfig.baseUrl}/api/auth/naver');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(
              {'email': email, 'name': name, 'identifier': identifier}),
        );

        if (response.statusCode == 200) {
          log('naver sign-in Success!');
          FirebaseAnalytics.instance.logSignUp(signUpMethod: 'naver');
          return jsonDecode(response.body);
        } else {
          throw Exception("Failed to Register naver user on server");
        }
      } else{
        log('naver login error');
        throw new Exception("naver login error");
      }
    } catch(error, stackTrace) {
      log(error.toString());
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> logoutNaverSignIn() async{
    await FlutterNaverLogin.logOut();
  }

  Future<void> revokeNaverSignIn() async{
    await FlutterNaverLogin.logOutAndDeleteToken();
  }
}