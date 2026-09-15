import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_harness.dart';

/// 골든으로 뜨는 화면 크기와 글자 배율 한 벌.
///
/// [name] 은 골든 파일 이름 뒤에 붙는다. `achievement_screen_phone.png`
class GoldenSurface {
  const GoldenSurface(this.name, this.size, {this.textScale = 1.0});

  final String name;
  final Size size;
  final double textScale;

  /// 작은 폰. 글자가 넘치는지 볼 때.
  static const smallPhone = GoldenSurface('small_phone', OnoSurface.smallPhone);

  /// 아이폰 14 세로.
  static const phone = GoldenSurface('phone', OnoSurface.phone);

  /// 폰에서 글자를 1.6배로 키운 사람. 위젯 테스트의 `크기` 그룹과 같은 배율이다.
  static const phoneLargeText = GoldenSurface(
    'phone_text_1_6',
    OnoSurface.phone,
    textScale: 1.6,
  );

  /// 아이패드 세로. 600 이상이라 태블릿 레이아웃으로 분기한다.
  static const tablet = GoldenSurface('tablet', OnoSurface.tablet);

  /// 화면 골든의 기본 조합.
  static const all = [smallPhone, phone, phoneLargeText, tablet];
}

/// 한 화면을 [surfaces] 크기마다 골든으로 뜬다.
///
/// ```dart
/// screenGoldenTest(
///   '훈장 화면',
///   fileName: 'achievement_screen',
///   buildApp: () async => buildOnoApp(
///     const AchievementScreen(),
///     cosmeticProvider: await loadedCosmeticProvider(),
///     achievementProvider: provider,
///   ),
/// );
/// ```
///
/// 크기마다 alchemist 가 두 벌을 만든다.
///
/// - `goldens/ci/<fileName>_<surface>.png`: 글자를 네모로 가린 것. 커밋해서
///   CI 가 비교한다.
/// - `goldens/<os>/<fileName>_<surface>.png`: 진짜 폰트로 그린 것. 커밋하지 않고
///   로컬에서 눈으로 확인한다.
///
/// [buildApp] 은 [buildOnoApp] 으로 만든 트리를 돌려준다. 옷장처럼 가짜 서버에서
/// 받아 둬야 하는 프로바이더가 있어서 비동기로 받는다.
///
/// 동작 줄이기를 켜고 뜬다. 끝나지 않는 연출이 있으면 `pumpAndSettle` 이 끝나지
/// 않고, 연출 중간 프레임을 뜨면 매번 다른 이미지가 나오기 때문이다.
void screenGoldenTest(
  String description, {
  required String fileName,
  required Future<Widget> Function() buildApp,
  List<GoldenSurface> surfaces = GoldenSurface.all,
}) {
  for (final surface in surfaces) {
    final slot = _AppSlot();

    goldenTest(
      '$description (${surface.name})',
      fileName: '${fileName}_${surface.name}',
      constraints: BoxConstraints.tight(surface.size),
      textScaleFactor: surface.textScale,
      // alchemist 의 builder 는 동기라 여기서는 자리만 만들고, 트리는 아래
      // pumpWidget 에서 기다려 받은 뒤 채운다.
      builder: () => _GoldenApp(slot: slot, size: surface.size),
      pumpWidget: (tester, wrapper) async {
        disableAnimationsForTest(tester);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        slot.app = await buildApp();
        await withMockedNetworkImages(() => tester.pumpWidget(wrapper));
      },
      // 먼저 settle 하고 나서 그림을 미리 읽는다. 훈장 화면처럼 들어온 뒤에
      // 스스로 조회하는 화면은 settle 전에는 그림 위젯이 아직 없어서, 순서를
      // 바꾸면 그림이 빈 채로 찍힌다.
      pumpBeforeTest: (tester) => withMockedNetworkImages(() async {
        await tester.pumpAndSettle();
        await precacheImages(tester);
      }),
    );
  }
}

class _AppSlot {
  Widget? app;
}

/// alchemist 가 감싼 틀 안에 [buildOnoApp] 트리를 넣는다.
///
/// 안쪽 MaterialApp 은 화면 크기를 테스트 창에서 읽는데, alchemist 는 캡처 직전에야
/// 창 크기를 맞춘다. 그 전까지는 테스트 기본 창 크기라 폰 크기를 줘도 태블릿
/// 레이아웃으로 그려진다. 그래서 크기를 [MediaQuery] 로 직접 박는다.
class _GoldenApp extends StatelessWidget {
  const _GoldenApp({required this.slot, required this.size});

  final _AppSlot slot;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final app = slot.app;
    if (app == null) {
      throw StateError('screenGoldenTest 의 buildApp 이 끝나기 전에 그려졌다.');
    }
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: size,
        padding: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
      ),
      child: app,
    );
  }
}
