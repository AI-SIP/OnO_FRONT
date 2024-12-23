import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../Config/AppConfig.dart';
import '../../GlobalModule/Dialog/SnackBarDialog.dart';

class GuestAuthService{
  final storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> signInWithGuest(BuildContext context) async{
    try{
      final url = Uri.parse('${AppConfig.baseUrl}/api/auth/login/guest');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        log('Guest sign-in Success!');

        await FirebaseAnalytics.instance
            .logEvent(name: 'user_register_with_guest');
        await FirebaseAnalytics.instance.logSignUp(signUpMethod: 'Guest');
        //SnackBarDialog.showSnackBar(context: context, message: "로그인에 성공했습니다.", backgroundColor: Colors.green);

        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to Register user on server");
      }
    } on TimeoutException catch (_) {
      SnackBarDialog.showSnackBar(
        context: context,
        message: "요청 시간이 초과되었습니다. 다시 시도해주세요.",
        backgroundColor: Colors.red,
      );
      return null;
    } catch(error, stackTrace) {
      //SnackBarDialog.showSnackBar(context: context, message: "로그인 과정에서 오류가 발생했습니다. 다시 시도해주세요.", backgroundColor: Colors.red);
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );

      return null;
    }
  }
}