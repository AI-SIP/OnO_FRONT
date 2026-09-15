import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Util/AppClock.dart';

import 'widget_harness.dart';

/// 골든 테스트가 보는 지금 시각. 2026년 9월 10일 목요일 오후 3시.
///
/// 픽스처의 날짜는 이 시각을 기준으로 적는다. 보상 기록 위젯 테스트가 쓰는
/// 시각과 같다.
final goldenNow = DateTime(2026, 9, 10, 15, 0);

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

  /// 폰과 태블릿 레이아웃만. 넘치는지는 위젯 테스트의 `크기` 그룹이 이미 보고
  /// 있어서, 생김새만 잠그면 되는 화면은 이 둘로 충분하다. 이미지 수가 절반이 된다.
  static const layouts = [phone, tablet];
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
/// 탭을 옮기는 것처럼 화면이 뜬 뒤에 손을 대야 보이는 모습은 [prepare] 에서
/// 만든다. 화면이 자리 잡은 뒤, 그림을 미리 읽기 전에 불린다.
///
/// 동작 줄이기를 켜고 뜬다. 끝나지 않는 연출이 있으면 `pumpAndSettle` 이 끝나지
/// 않고, 연출 중간 프레임을 뜨면 매번 다른 이미지가 나오기 때문이다.
///
/// 펌프는 [runWith] 안에서 돈다. 기본은 네트워크 이미지를 투명 PNG 로 막는
/// [withMockedNetworkImages] 다. 태그 화면처럼 서비스를 주입할 수 없어 HTTP 를
/// 통째로 가로채야 하는 화면은 그 가짜로 바꿔 넘긴다. 둘 다 `HttpOverrides` 라
/// 겹쳐 쓰면 안쪽 것만 먹는다.
void screenGoldenTest(
  String description, {
  required String fileName,
  required Future<Widget> Function() buildApp,
  List<GoldenSurface> surfaces = GoldenSurface.all,
  Future<void> Function(Future<void> Function() body) runWith =
      withMockedNetworkImages,
  Future<void> Function(WidgetTester tester)? prepare,
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
        // 입력칸에 포커스가 가는 화면은 커서가 깜빡인다. 찍히는 순간 커서가
        // 켜져 있는지가 타이머에 달려 있으면 이미지가 흔들리므로 늘 켜 둔다.
        EditableText.debugDeterministicCursor = true;
        addTearDown(() => EditableText.debugDeterministicCursor = false);
        // `N일 전` 이나 이번 달 달력처럼 지금 시각에 매인 문구가 날마다 바뀌지
        // 않게 시계를 멈춘다. 화면이 AppClock 을 읽어야 먹힌다.
        AppClock.setForTest(() => goldenNow);
        addTearDown(AppClock.resetForTest);
        slot.app = await buildApp();
        await runWith(() => tester.pumpWidget(wrapper));
      },
      // 먼저 settle 하고 나서 그림을 미리 읽는다. 훈장 화면처럼 들어온 뒤에
      // 스스로 조회하는 화면은 settle 전에는 그림 위젯이 아직 없어서, 순서를
      // 바꾸면 그림이 빈 채로 찍힌다.
      pumpBeforeTest: (tester) => runWith(() async {
        await tester.pumpAndSettle();
        if (prepare != null) {
          await prepare(tester);
          await tester.pumpAndSettle();
        }
        await _precacheLocalImages(tester);
      }),
    );
  }
}

/// 에셋과 메모리 그림만 미리 읽는다.
///
/// 그림 디코딩은 진짜 비동기라 `runAsync` 안에서만 끝난다. 그런데 `runAsync` 가
/// 도는 동안에는 화면에 걸려 있던 다른 비동기도 같이 흘러간다. 책장 화면의
/// `CachedNetworkImage` 는 그 틈에 캐시 폴더(path_provider)를 찾다가
/// `MissingPluginException` 으로 테스트를 깨뜨렸고, alchemist 의 `precacheImages`
/// 로 네트워크 그림까지 기다리게 했을 때는 10분 시간 초과로 죽었다.
///
/// 그래서 네트워크 그림은 기다리지 않고(어차피 투명 PNG 로 막힌다), 미리 읽을
/// 로컬 그림이 없으면 `runAsync` 에 아예 들어가지 않는다.
Future<void> _precacheLocalImages(WidgetTester tester) async {
  bool isLocal(ImageProvider provider) {
    if (provider is ResizeImage) return isLocal(provider.imageProvider);
    return provider is AssetBundleImageProvider || provider is MemoryImage;
  }

  final locals = [
    for (final element in find.byType(Image).evaluate())
      if (isLocal((element.widget as Image).image)) element,
  ];
  if (locals.isEmpty) return;

  await tester.runAsync(() async {
    await Future.wait([
      for (final element in locals)
        precacheImage((element.widget as Image).image, element),
    ]);
  });
  await tester.pumpAndSettle();
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
