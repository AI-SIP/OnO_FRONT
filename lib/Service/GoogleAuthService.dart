import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../Config/AppConfig.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<String?> signInWithGoogle() async {
    try {
      final googleSignInAccount = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;

      final String? accessToken =
          googleSignInAuthentication.accessToken; // 얘가 accessToken
      String? email = googleSignInAccount.email; // 유저의 이메일을 저장
      String? name = googleSignInAccount.displayName; // 유저의 이름을 저장
      String? identifier = googleSignInAccount.id;

      if (googleSignInAccount != null) {
        final platform = _getPlatform(); // 플랫폼 정보 확인

        final url = Uri.parse('${AppConfig.baseUrl}/api/auth/google');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'accessToken': accessToken,
            'platform': platform,
            'email': email,
            'name': name,
            'identifier': identifier
          }),
        );

        if (response.statusCode == 200) {
          print('Google sign-in Success!');
          final responseBody = jsonDecode(response.body);
          final jwtToken = responseBody['token'];
          return jwtToken;
        } else {
          throw Exception("Failed to Register user on server");
        }
      } else {
        throw Exception("Failed to get Google idToken");
      }
    } catch (error) {
      print('Google sign-in error: $error');
      return null;
    }
  }

  Future<void> logoutGoogleSignIn() async {

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
        print('Google sign-out Success!');
      } else {
        throw Exception('Failed to revoke Google token');
      }
    } catch (error) {
      print('Google sign-out error: $error');
    }
  }

  String _getPlatform() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else {
      return 'unknown';
    }
  }
}
