// ProfileAvatar 테스트.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Constants/ProfileImageDefaults.dart';
import 'package:ono/Module/User/ProfileAvatar.dart';
import 'package:ono/Screen/Cosmetic/Mock/CosmeticMockData.dart';
import 'package:ono/Screen/User/Widget/FrogCharacter.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  test('기본 프로필 이미지 에셋이 실제로 있다', () {
    // 사진을 안 올린 사람 자리에는 맨 개구리가 선다. 이 그림이 없어지면
    // 프로필 사진을 올리지 않은 사용자의 아바타가 전부 깨진다.
    expect(
      File(ProfileImageDefaults.assetPath).existsSync(),
      isTrue,
      reason: '${ProfileImageDefaults.assetPath} 가 없다. 기본 프로필 이미지가 깨진다',
    );
  });

  testWidgets('이미지 주소가 없으면 맨 개구리를 그린다', (tester) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const Scaffold(
          body: Center(
            child: ProfileAvatar(size: 48, borderColor: Colors.grey),
          ),
        ),
      );
    });

    expect(find.byType(FrogHeadAvatar), findsOneWidget);
  });

  testWidgets('빈 문자열이 와도 맨 개구리로 떨어진다', (tester) async {
    await withMockedNetworkImages(() async {
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
    });

    expect(find.byType(FrogHeadAvatar), findsOneWidget);
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
      final frog = tester.widget<FrogHeadAvatar>(find.byType(FrogHeadAvatar));
      expect(frog.layers.length, greaterThan(1));
    });

    testWidgets('안 넘기면 아무것도 안 걸친 맨 개구리다', (tester) async {
      // 스터디룸에서 보는 남의 프로필이 이 경우다. 그 사람이 무엇을 입었는지
      // 서버가 내려주지 않으므로 내가 꾸민 개구리를 세우면 거짓말이 된다.
      // 개구리인 것까지는 맞으니 맨 개구리로 세운다.
      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          const Scaffold(
            body: Center(
              child: ProfileAvatar(size: 48, borderColor: Colors.grey),
            ),
          ),
        );
      });

      final frog = tester.widget<FrogHeadAvatar>(find.byType(FrogHeadAvatar));
      expect(frog.layers, hasLength(1));
      expect(frog.layers.single.imageUrl, ProfileImageDefaults.assetPath);
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
