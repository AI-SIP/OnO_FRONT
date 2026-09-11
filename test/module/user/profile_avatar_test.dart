// ProfileAvatar 테스트.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Constants/ProfileImageDefaults.dart';
import 'package:ono/Module/User/ProfileAvatar.dart';
import 'package:ono/Screen/Cosmetic/Mock/CosmeticMockData.dart';
import 'package:ono/Screen/User/Widget/FrogCharacter.dart';

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

  group('개구리 프로필', () {
    testWidgets('개구리를 넘기면 기본 이미지 대신 개구리 얼굴이 선다', (tester) async {
      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          Scaffold(
            body: Center(
              child: ProfileAvatar(
                size: 48,
                borderColor: Colors.grey,
                frogLayers: CosmeticMockData.graduateLayers,
              ),
            ),
          ),
        );
      });

      expect(find.byType(FrogHeadAvatar), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('안 넘기면 예전 그대로 기본 이미지다', (tester) async {
      // 스터디룸에서 보는 남의 프로필이 이 경우다. 그 사람이 무엇을 입었는지
      // 서버가 내려주지 않으므로 내 개구리를 세우면 거짓말이 된다.
      await pumpOnoWidget(
        tester,
        const Scaffold(
          body: Center(
            child: ProfileAvatar(size: 48, borderColor: Colors.grey),
          ),
        ),
      );

      expect(find.byType(FrogHeadAvatar), findsNothing);
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('사진을 올렸으면 개구리를 넘겨도 사진이 이긴다', (tester) async {
      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          Scaffold(
            body: Center(
              child: ProfileAvatar(
                imageUrl: 'https://example.com/me.png',
                size: 48,
                borderColor: Colors.grey,
                frogLayers: CosmeticMockData.graduateLayers,
              ),
            ),
          ),
        );
      });

      expect(find.byType(Image), findsWidgets);
    });
  });
}
