import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Google 로그인 함수
  Future<void> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if(account != null) {
        print('Google User: ${account.displayName}');
        print('Email: ${account.email}');
        print('ID: ${account.id}');
        print('Photo URL: ${account.photoUrl}');
        print('Server Auth Code: ${account.serverAuthCode}');
      }
      await _googleSignIn.signIn();
    } catch (error) {
      print('Google sign-in error: $error');
    }
  }

  // Apple 로그인 함수
  Future<void> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      if(credential != null) {
        print('Apple User: ${credential.givenName} ${credential.familyName}');
        print('Email: ${credential.email}');
      }
    } catch (error) {
      print('Apple sign-in error: $error');
    }
  }
}