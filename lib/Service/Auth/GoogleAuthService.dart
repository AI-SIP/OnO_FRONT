import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../Config/AppConfig.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final googleSignInAccount = await _googleSignIn.signIn();
      if(googleSignInAccount != null){
        final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount!.authentication;

        final String? accessToken =
            googleSignInAuthentication.accessToken;
        String? email = googleSignInAccount.email;
        String? name = googleSignInAccount.displayName;
        String? identifier = googleSignInAccount.id;

        if (googleSignInAccount != null) {
          final platform = _getPlatform();

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
            log('Google sign-in Success!');
            return jsonDecode(response.body);
          } else {
            throw Exception("Failed to Register user on server");
          }
        } else {
          throw Exception("Failed to get Google idToken");
        }
      } else{
        throw Exception("googleSignInAccount is null!");
      }
    } catch (error) {
      log(error.toString());
    }

    throw Exception("Failed to Google sign-in");
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
      }
    } catch (error) {
      log('Google sign-out error: $error');
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
