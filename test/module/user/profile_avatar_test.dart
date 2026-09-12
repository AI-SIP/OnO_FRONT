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

  group('치장 테두리', () {
    // 테두리는 원을 **바깥에서 감싼다.** 원 안쪽에 그리면 사진을 덮는다.
    // 에셋이 120 x 120 이고 가운데 96 x 96 이 비어 있어서, 사진이 그 96 자리를
    // 쓰고 테두리가 바깥 12px 을 두른다.
    const frame = 'assets/ProfileFrame/frame_leaf.svg';

    testWidgets('테두리를 둘러도 전체 지름이 그대로다', (tester) async {
      // 바깥으로 커지면 스터디룸 목록에서 줄이 밀린다.
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ProfileAvatar(
              size: 120,
              borderColor: Colors.black,
              frameUrl: frame,
            ),
          ),
        ),
      ));

      expect(tester.getSize(find.byType(ProfileAvatar)), const Size(120, 120));
    });

    testWidgets('테두리를 두르면 안쪽 사진이 그만큼 작아진다', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ProfileAvatar(
                size: 120,
                borderColor: Colors.black,
                frameUrl: frame,
              ),
              ProfileAvatar(size: 120, borderColor: Colors.black),
            ],
          ),
        ),
      ));

      final framed = tester.getSize(find.byType(FrogHeadAvatar).at(0));
      final bare = tester.getSize(find.byType(FrogHeadAvatar).at(1));

      expect(framed.width, lessThan(bare.width));
      // 120 의 96/120 = 96. 기본 테두리가 없어서 안쪽으로 들이지도 않는다.
      expect(framed.width, closeTo(96, 0.5));
    });

    testWidgets('테두리가 없으면 사진이 원을 꽉 채운다', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ProfileAvatar(size: 120, borderColor: Colors.black),
          ),
        ),
      ));

      expect(tester.getSize(find.byType(ProfileAvatar)), const Size(120, 120));
      // 기본 테두리 두께(1)만큼만 안쪽에 앉는다.
      expect(tester.getSize(find.byType(FrogHeadAvatar)).width, 118);
    });
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
