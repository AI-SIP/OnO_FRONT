// ProfileAvatar 테스트.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Constants/ProfileImageDefaults.dart';
import 'package:ono/Module/User/ProfileAvatar.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  test('기본 프로필 이미지 에셋이 실제로 있다', () {
    // 이 파일은 원래 최초 진입 가이드의 마지막 장이었다. 가이드 화면을
    // 지우면서 같은 폴더의 GuideScreen1~4 를 함께 지웠는데, 5 만은 기본
    // 프로필 이미지로 계속 쓰이고 있어서 남겼다. 나중에 폴더를 정리하다가
    // 같이 지우면 프로필 사진을 올리지 않은 사용자의 아바타가 전부 깨진다.
    expect(
      File(ProfileImageDefaults.assetPath).existsSync(),
      isTrue,
      reason: '${ProfileImageDefaults.assetPath} 가 없다. 기본 프로필 이미지가 깨진다',
    );
  });

  testWidgets('이미지 주소가 없으면 기본 이미지를 그린다', (tester) async {
    await pumpOnoWidget(
      tester,
      const Scaffold(
        body: Center(
          child: ProfileAvatar(size: 48, borderColor: Colors.grey),
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('빈 문자열이 와도 기본 이미지로 떨어진다', (tester) async {
    await pumpOnoWidget(
      tester,
      const Scaffold(
        body: Center(
          child: ProfileAvatar(
            imageUrl: '   ',
            size: 48,
            borderColor: Colors.grey,
          ),
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
  });
}
