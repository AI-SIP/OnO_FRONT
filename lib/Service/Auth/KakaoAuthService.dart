import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:ono/Model/User/UserRegisterModel.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../Config/AppConfig.dart';
import '../../GlobalModule/Dialog/SnackBarDialog.dart';

class KakaoAuthService {
  Future<UserRegisterModel?> signInWithKakao(BuildContext context) async {

    UserRegisterModel? userRegisterModel;

    if (await isKakaoTalkInstalled()) {
      try {
        await UserApi.instance.loginWithKakaoTalk().then((_) async {
          User user = await UserApi.instance.me();

          userRegisterModel = await registerUser(context, user);
        });
      } catch (error, stackTrace) {
        log('카카오톡으로 로그인 실패 $error');
        await Sentry.captureException(
          error,
          stackTrace: stackTrace,
        );

        // 사용자가 카카오톡 설치 후 디바이스 권한 요청 화면에서 로그인을 취소한 경우,
        // 의도적인 로그인 취소로 보고 카카오계정으로 로그인 시도 없이 로그인 취소로 처리 (예: 뒤로 가기)
        if (error is PlatformException && error.code == 'CANCELED') {
          userRegisterModel = null;
        }

        // 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인
        try {
          await UserApi.instance.loginWithKakaoAccount().then((_) async {
            await UserApi.instance.loginWithKakaoAccount();
            User user = await UserApi.instance.me();

            userRegisterModel = await registerUser(context, user);
          });
        }
        catch (error, stackTrace) {
          log('카카오계정으로 로그인 실패 $error');
          await Sentry.captureException(
            error,
            stackTrace: stackTrace,
          );

          //SnackBarDialog.showSnackBar(context: context, message: "로그인 과정에서 오류가 발생했습니다. 다시 시도해주세요.", backgroundColor: Colors.red);
          userRegisterModel = null;
        }
      }
    } else {
      try {
        await UserApi.instance.loginWithKakaoAccount().then((_) async {
          await UserApi.instance.loginWithKakaoAccount();
          User user = await UserApi.instance.me();

          userRegisterModel = await registerUser(context, user);
        });
      } catch (error, stackTrace) {
        if (error is PlatformException && error.code == 'CANCELED') {
          userRegisterModel = null;
        }

        //SnackBarDialog.showSnackBar(context: context, message: "로그인 과정에서 오류가 발생했습니다. 다시 시도해주세요.", backgroundColor: Colors.red);
        log('카카오계정으로 로그인 실패 $error');
        await Sentry.captureException(
          error,
          stackTrace: stackTrace,
        );
      }
    }

    return userRegisterModel;
  }

  Future<UserRegisterModel?> registerUser(BuildContext context, User user) async {
    try{
      final String? email = user.kakaoAccount?.email;
      final String? name = user.kakaoAccount?.profile?.nickname;
      final int identifier = user.id;

      return UserRegisterModel(
          email: email,
          name: name,
          identifier: identifier.toString(),
          platform: 'KAKAO'
      );
    } catch (error, stackTrace) {
      log(error.toString());
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> logoutKakaoSignIn() async{
    await UserApi.instance.logout();
  }

  Future<void> revokeKakaoSignIn() async {
    await UserApi.instance.unlink();
  }
}
