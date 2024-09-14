import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

class KakaoAuthService {

  Future<void> signInWithKakao() async {

    final UserApi api = UserApi.instance;
    if (await isKakaoTalkInstalled()) {
      try {
        api.loginWithKakaoTalk().then((_) async {
          User user = await UserApi.instance.me();
          log('nickname : ${user.kakaoAccount?.profile?.nickname}');
          log('user id : ${user.id}');
          return;
        });
      } catch (error) {
        log('카카오톡으로 로그인 실패 $error');

        // 사용자가 카카오톡 설치 후 디바이스 권한 요청 화면에서 로그인을 취소한 경우,
        // 의도적인 로그인 취소로 보고 카카오계정으로 로그인 시도 없이 로그인 취소로 처리 (예: 뒤로 가기)
        if (error is PlatformException && error.code == 'CANCELED') {
          return;
        }
        // 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인
        try {
          await UserApi.instance.loginWithKakaoAccount();
          return;
        } catch (error) {
          print('카카오계정으로 로그인 실패 $error');
        }
      }
    } else {
      try {
        await UserApi.instance.loginWithKakaoAccount();
        User user = await UserApi.instance.me();
        log('nickname : ${user.kakaoAccount?.profile?.nickname}');
        log('user id : ${user.id}');
        return;
      } catch (error) {
        print('카카오계정으로 로그인 실패 $error');
      }
    }
  }
}
