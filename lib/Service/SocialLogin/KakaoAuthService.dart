import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:ono/Model/User/UserRegisterModel.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class KakaoAuthService {
  Future<UserRegisterModel?> signInWithKakao(BuildContext context) async {
    if (await isKakaoTalkInstalled()) {
      try {
        await UserApi.instance.loginWithKakaoTalk();
        final user = await UserApi.instance.me();
        return await registerUser(user);
      } catch (error, stackTrace) {
        debugPrint('카카오톡으로 로그인 실패 $error');

        // 사용자가 직접 취소한 경우는 오류가 아니다. 카카오계정 로그인으로 넘어가지 않고
        // 그대로 로그인 취소로 처리한다. (Sentry FLUTTER-165/VJ 노이즈)
        if (isUserCancelled(error)) {
          return null;
        }

        await Sentry.captureException(error, stackTrace: stackTrace);
        // 카카오톡에 연결된 카카오계정이 없는 경우 등 → 카카오계정 로그인으로 재시도
        return await _signInWithKakaoAccount();
      }
    }

    return await _signInWithKakaoAccount();
  }

  Future<UserRegisterModel?> _signInWithKakaoAccount() async {
    try {
      await UserApi.instance.loginWithKakaoAccount();
      final user = await UserApi.instance.me();
      return await registerUser(user);
    } catch (error, stackTrace) {
      debugPrint('카카오계정으로 로그인 실패 $error');

      if (isUserCancelled(error)) {
        return null;
      }

      await Sentry.captureException(error, stackTrace: stackTrace);
      return null;
    }
  }

  /// 사용자가 로그인 창을 직접 닫거나 취소한 경우인지 판단한다.
  /// 카카오 SDK 는 취소를 PlatformException(CANCELED), KakaoAuthException
  /// (error_description 에 cancelled), ClientErrorCause.cancelled 등 여러 형태로 던진다.
  static bool isUserCancelled(Object error) {
    if (error is PlatformException && error.code == 'CANCELED') {
      return true;
    }
    return error.toString().toLowerCase().contains('cancel');
  }

  Future<UserRegisterModel?> registerUser(User user) async {
    try {
      final String? email = user.kakaoAccount?.email;
      final String? name = user.kakaoAccount?.profile?.nickname;
      final int identifier = user.id;

      return UserRegisterModel(
          email: email,
          name: name,
          identifier: identifier.toString(),
          platform: 'KAKAO');
    } catch (error, stackTrace) {
      debugPrint(error.toString());
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> logoutKakaoSignIn() async {
    await UserApi.instance.logout();
  }

  Future<void> revokeKakaoSignIn() async {
    await UserApi.instance.unlink();
  }
}
