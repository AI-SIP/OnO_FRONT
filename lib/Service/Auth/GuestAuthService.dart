import 'dart:convert';
import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../Config/AppConfig.dart';

class GuestAuthService{
  final storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> signInWithGuest() async{

    try{
      final url = Uri.parse('${AppConfig.baseUrl}/api/auth/guest');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        log('Guest sign-in Success!');
        FirebaseAnalytics.instance.logSignUp(signUpMethod: 'Guest');
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to Register user on server");
      }
    } catch(error, stackTrace) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );

      return null;
    }
  }
}