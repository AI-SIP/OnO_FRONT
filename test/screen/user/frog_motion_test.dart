// 개구리 애니메이션 테스트.
//
// 여섯 벌의 값은 `assets/Animation/*.json` 이 원본이고, 앱은 그것을
// `FrogMotion` 에 옮겨 적어 들고 있다. 둘이 갈라지면 화면에서는 아무 일도
// 없는 것처럼 보이면서 개구리만 조금씩 다르게 움직인다. 여기서 잠근다.
//
// 반복 모션(대기, 눈 깜빡임)은 `setUpOnoWidgetTest()` 가 꺼 둔다. 이 파일만
// 필요한 자리에서 다시 켜고, 켠 뒤에는 `pumpAndSettle` 을 쓰지 않는다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Cosmetic/CosmeticLoadoutModel.dart';
import 'package:ono/Screen/User/Widget/FrogCharacter.dart';
import 'package:ono/Screen/User/Widget/FrogMotion.dart';

import '../../helpers/helpers.dart';

/// manifest 한 벌을 읽는다.
Map<String, Object?> manifestOf(String name) {
  final file = File('assets/Animation/$name.json');
  expect(file.existsSync(), isTrue, reason: '$name.json 이 없다');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

/// 화면에 그려진 에셋 경로를 뒤에서 앞 순서로 모은다.
List<String> drawnAssets(WidgetTester tester) => [
      for (final image in tester.widgetList<Image>(find.byType(Image)))
        if (image.image case final AssetImage asset) asset.assetName,
    ];

void main() {
  setUpOnoWidgetTest();

  group('manifest 와 옮겨 적은 값', () {
    final clips = <FrogMotionClip>[
      FrogMotion.levelUp,
      FrogMotion.missionComplete,
      FrogMotion.equipEffect,
      FrogMotion.blink,
      FrogMotion.idle,
      FrogMotion.happyBounce,
    ];

    for (final clip in clips) {
      test('${clip.name} 의 이름·길이·반복 여부가 manifest 와 같다', () {
        final manifest = manifestOf(clip.name);

        expect(manifest['name'], clip.name);
        expect(manifest['durationMs'], clip.duration.inMilliseconds);
        expect(manifest['loop'], clip.loop);

        final canvas = manifest['canvas'] as Map<String, Object?>;
        expect(canvas['width'], FrogMotion.canvasSide);
        expect(canvas['height'], FrogMotion.canvasSide);
      });
    }

    test('겹쳐 그리는 효과는 실제로 있는 webp 를 가리킨다', () {
      for (final clip in [
        FrogMotion.levelUp,
        FrogMotion.missionComplete,
        FrogMotion.equipEffect,
        FrogMotion.blink,
      ]) {
        final manifest = manifestOf(clip.name);
        expect(
          manifest['layerUsage'],
          anyOf('transparent-effect-overlay', 'base-replacement'),
          reason: '${clip.name} 은 그림을 그대로 쓰는 갈래여야 한다',
        );
        expect(manifest['animatedWebp'], isNotNull);

        final path = clip.webp;
        expect(path, isNotNull, reason: '${clip.name} 은 webp 를 써야 한다');
        expect(
          File(path!).existsSync(),
          isTrue,
          reason: '$path 가 레포에 없다',
        );
      }
    });

    test('통째로 움직이는 것은 webp 를 쓰지 않는다', () {
      // 원본에 있는 webp 는 `animatedWebpPreview`, 즉 확인용이다. 그대로
      // 재생하면 개구리 본체만 움직이고 입고 있는 치장은 제자리에 남는다.
      for (final clip in [FrogMotion.idle, FrogMotion.happyBounce]) {
        final manifest = manifestOf(clip.name);
        expect(manifest['layerUsage'], 'whole-cosmetic-stack-transform');
        expect(manifest['animatedWebp'], isNull);
        expect(manifest['animatedWebpPreview'], isNotNull);
        expect(clip.webp, isNull, reason: '${clip.name} 은 webp 를 쓰면 안 된다');
      }
    });

    test('변환 기준점이 manifest 와 같다', () {
      for (final clip in [FrogMotion.idle, FrogMotion.happyBounce]) {
        final origin =
            (manifestOf(clip.name)['transformOriginAlignment'] as List)
                .cast<num>();
        expect(origin, hasLength(2));
        expect(origin[0].toDouble(), FrogMotion.origin.x);
        expect(origin[1].toDouble(), FrogMotion.origin.y);
      }
    });

    for (final clip in [FrogMotion.idle, FrogMotion.happyBounce]) {
      test('${clip.name} 의 키프레임이 manifest 와 한 칸씩 같다', () {
        final frames = (manifestOf(clip.name)['keyframes'] as List)
            .cast<Map<String, Object?>>();

        expect(clip.keyframes, hasLength(frames.length));
        for (var i = 0; i < frames.length; i++) {
          final expected = frames[i];
          final actual = clip.keyframes[i];
          final where = '${clip.name}[$i]';

          expect((expected['t'] as num).toDouble(), actual.t, reason: where);
          expect((expected['translateY'] as num).toDouble(), actual.translateY,
              reason: where);
          expect((expected['scaleX'] as num).toDouble(), actual.scaleX,
              reason: where);
          expect((expected['scaleY'] as num).toDouble(), actual.scaleY,
              reason: where);
        }
      });
    }
  });

  group('키프레임 읽기', () {
    test('시작과 끝은 원래 자세다. 정지 상태에서 개구리가 튀면 안 된다', () {
      for (final clip in [FrogMotion.idle, FrogMotion.happyBounce]) {
        for (final t in [0.0, 1.0]) {
          final frame = clip.sampleAt(t);
          expect(frame.translateY, 0, reason: '${clip.name} @ $t');
          expect(frame.scaleX, 1, reason: '${clip.name} @ $t');
          expect(frame.scaleY, 1, reason: '${clip.name} @ $t');
        }
      }
    });

    test('키프레임 사이는 직선으로 잇는다', () {
      // idle 의 0.000(0) 과 0.143(-1) 사이 한가운데.
      final frame = FrogMotion.idle.sampleAt(0.0715);
      expect(frame.translateY, closeTo(-0.5, 0.001));
    });

    test('범위를 벗어난 값은 양 끝으로 눌린다', () {
      expect(FrogMotion.idle.sampleAt(-1).translateY, 0);
      expect(FrogMotion.idle.sampleAt(2).translateY, 0);
    });
  });

  group('통째로 움직이기', () {
    Future<void> pumpMotion(
      WidgetTester tester, {
      required FrogMotionClip clip,
      required double size,
      int tick = 1,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: FrogStackMotion(
              clip: clip,
              size: size,
              tick: tick,
              child:
                  SizedBox.square(dimension: size, child: const Placeholder()),
            ),
          ),
        ),
      );
    }

    /// 지금 층 전체를 얼마나 밀어 올렸는지. 위로 갈수록 음수다.
    ///
    /// 늘이는 것과 옮기는 것을 나눠 걸어 두어서, 바깥쪽 [Transform] 이 옮긴
    /// 거리만 들고 있다. 화면 좌표를 재면 늘어난 몫이 섞인다.
    double translateYOf(WidgetTester tester) {
      final transform = tester.widget<Transform>(
        find
            .descendant(
              of: find.byType(FrogStackMotion),
              matching: find.byType(Transform),
            )
            .first,
      );
      return transform.transform.getTranslation().y;
    }

    testWidgets('첫 프레임은 제자리다', (tester) async {
      await pumpMotion(tester, clip: FrogMotion.happyBounce, size: 256);
      expect(translateYOf(tester), 0);

      await tester.pump();
      expect(translateYOf(tester), 0);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('이동 거리는 그려지는 크기에 비례해 줄어든다', (tester) async {
      // happy_bounce 는 t=0.348 에서 512 기준 -25px 까지 올라간다.
      const clip = FrogMotion.happyBounce;
      final peak = clip.duration * 0.348;

      await pumpMotion(tester, clip: clip, size: 512);
      await tester.pump(peak);
      expect(translateYOf(tester), closeTo(-25, 0.3));
      await tester.pumpWidget(const SizedBox());

      // 256 으로 그리면 그 절반만 움직여야 한다. 안 줄이면 작게 그릴수록
      // 과하게 움직인다.
      await pumpMotion(tester, clip: clip, size: 256);
      await tester.pump(peak);
      expect(translateYOf(tester), closeTo(-12.5, 0.15));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('동작 줄이기를 켜면 아예 움직이지 않는다', (tester) async {
      disableAnimationsForTest(tester);

      await pumpMotion(tester, clip: FrogMotion.happyBounce, size: 512);
      final resting = tester.getTopLeft(find.byType(Placeholder));
      await tester.pump(FrogMotion.happyBounce.duration * 0.348);

      expect(tester.getTopLeft(find.byType(Placeholder)), resting);
      // 변환 자체를 걸지 않는다.
      expect(
        find.descendant(
          of: find.byType(FrogStackMotion),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('반복을 끄면 대기 모션이 프레임을 예약하지 않는다', (tester) async {
      // 이 스위치가 없으면 개구리를 그리는 화면의 pumpAndSettle 이 전부
      // 영영 끝나지 않는다.
      expect(FrogMotion.loopsEnabled, isFalse);

      await pumpMotion(tester, clip: FrogMotion.idle, size: 512, tick: 0);
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('반복을 켜면 대기 모션이 돈다', (tester) async {
      FrogMotion.loopsEnabled = true;

      await pumpMotion(tester, clip: FrogMotion.idle, size: 512, tick: 0);
      expect(translateYOf(tester), 0);
      // idle 은 t=0.429 에서 512 기준 -3px 까지 올라간다.
      await tester.pump(FrogMotion.idle.duration * 0.429);
      expect(translateYOf(tester), closeTo(-3, 0.05));

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('눈 깜빡임', () {
    const base = CosmeticLayerModel(
      imageUrl: CosmeticLoadoutModel.defaultBaseImageUrl,
      layerOrder: 0,
    );
    const head = CosmeticLayerModel(
      imageUrl: CosmeticLoadoutModel.defaultBaseHeadImageUrl,
      layerOrder: 0,
    );
    const hat = CosmeticLayerModel(
      imageUrl: 'assets/Cosmetic/HAT_CROWN.png',
      layerOrder: 5,
      slot: 'HEAD',
      itemKey: 'HAT_CROWN',
    );

    Future<void> pumpStack(
      WidgetTester tester, {
      required List<CosmeticLayerModel> layers,
      required bool blinking,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: FrogLayerStack(layers: layers, blinking: blinking),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('켜면 BASE 자리만 바뀌고 치장은 그대로다', (tester) async {
      FrogMotion.loopsEnabled = true;

      await pumpStack(tester, layers: const [base, hat], blinking: true);

      expect(drawnAssets(tester), [
        FrogMotion.blink.webp,
        hat.imageUrl,
      ]);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('안 켜면 원래 BASE 그대로다', (tester) async {
      FrogMotion.loopsEnabled = true;

      await pumpStack(tester, layers: const [base, hat], blinking: false);

      expect(drawnAssets(tester), [base.imageUrl, hat.imageUrl]);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('전신 옷을 입어 BASE_HEAD 로 갈렸으면 바꾸지 않는다', (tester) async {
      // 깜빡이는 그림은 전신 개구리에서 떠 온 것이다. 머리만 있는 그림 자리에
      // 끼우면 옷 밖으로 팔다리가 도로 나온다.
      FrogMotion.loopsEnabled = true;

      await pumpStack(tester, layers: const [head, hat], blinking: true);

      expect(drawnAssets(tester), [head.imageUrl, hat.imageUrl]);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('동작 줄이기를 켜면 깜빡이지 않는다', (tester) async {
      FrogMotion.loopsEnabled = true;
      disableAnimationsForTest(tester);

      await pumpStack(tester, layers: const [base], blinking: true);

      expect(drawnAssets(tester), [base.imageUrl]);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('겹쳐 그리는 효과', () {
    Future<void> pumpEffect(
      WidgetTester tester, {
      required int tick,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: FrogEffectOverlay(
              clip: FrogMotion.equipEffect,
              tick: tick,
              size: 180,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('신호가 0 이면 아무것도 그리지 않는다', (tester) async {
      await pumpEffect(tester, tick: 0);
      expect(find.byType(Image), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('길이만큼 재생하고 스스로 사라진다', (tester) async {
      await pumpEffect(tester, tick: 1);
      // 캐시를 비우는 한 박자가 있어서 한 프레임 뒤에 뜬다.
      await tester.pump();
      expect(drawnAssets(tester), [FrogMotion.equipEffect.webp]);

      await tester.pump(FrogMotion.equipEffect.duration);
      await tester.pump();
      expect(find.byType(Image), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('동작 줄이기를 켜면 띄우지 않는다', (tester) async {
      disableAnimationsForTest(tester);

      await pumpEffect(tester, tick: 1);
      await tester.pump();
      expect(find.byType(Image), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
