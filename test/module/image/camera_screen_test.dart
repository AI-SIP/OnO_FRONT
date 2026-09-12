import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Image/CameraScreen.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../helpers/helpers.dart';

/// 카메라 플러그인을 플랫폼 채널 아래에서 통째로 갈아 끼운다.
///
/// [CameraController] 는 [CameraPlatform.instance] 를 통해서만 네이티브와
/// 이야기하므로, 여기에 가짜를 꽂으면 화면 코드를 하나도 건드리지 않고 초기화
/// 성공과 실패, 촬영, 플래시, 초점을 모두 시험할 수 있다.
class FakeCameraPlatform extends CameraPlatform
    with MockPlatformInterfaceMixin {
  FakeCameraPlatform({this.createError, this.gate});

  /// 넘기면 `createCameraWithSettings` 가 이걸 던진다. 권한 거부와 카메라
  /// 점유를 흉내 내는 데 쓴다.
  final Object? createError;

  /// 넘기면 초기화가 여기서 멈춘다. 여는 중 화면을 보려고 둔 것이다.
  final Completer<void>? gate;

  /// 촬영이 돌려줄 파일. 확인 단계가 `Image.file` 로 실제로 읽으므로 진짜
  /// 파일이어야 한다.
  late final String picturePath;

  int _nextCameraId = 1;
  final Map<int, StreamController<CameraInitializedEvent>> _initialized = {};

  int createCameraCallCount = 0;
  int disposeCallCount = 0;
  int takePictureCallCount = 0;
  final List<FlashMode> flashModes = [];
  final List<Point<double>?> focusPoints = [];
  final List<Point<double>?> exposurePoints = [];
  final List<double> zoomLevels = [];
  CameraDescription? lastCreatedDescription;

  void prepare() {
    final dir = Directory.systemTemp.createTempSync('ono_camera_test');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    final file = File('${dir.path}/shot.png')
      ..writeAsBytesSync(kTransparentPngBytes);
    picturePath = file.path;
  }

  @override
  Future<int> createCameraWithSettings(
    CameraDescription description,
    MediaSettings mediaSettings,
  ) async {
    createCameraCallCount++;
    lastCreatedDescription = description;
    if (gate != null) await gate!.future;
    if (createError != null) throw createError!;
    return _nextCameraId++;
  }

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {
    // 실제 기기는 미리보기 크기를 가로 기준으로 알려 준다. 화면이 이걸
    // 뒤집어 세로 비율을 만들므로 여기서도 가로로 준다.
    _controllerFor(cameraId).add(
      const CameraInitializedEvent(
        1,
        1920,
        1080,
        ExposureMode.auto,
        true,
        FocusMode.auto,
        true,
      ),
    );
  }

  StreamController<CameraInitializedEvent> _controllerFor(int cameraId) {
    return _initialized.putIfAbsent(
      cameraId,
      () => StreamController<CameraInitializedEvent>.broadcast(),
    );
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      _controllerFor(cameraId).stream;

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream<DeviceOrientationChangedEvent>.empty();

  @override
  Widget buildPreview(int cameraId) =>
      const ColoredBox(color: Color(0xFF303030));

  @override
  Future<XFile> takePicture(int cameraId) async {
    takePictureCallCount++;
    return XFile(picturePath);
  }

  @override
  Future<void> setFlashMode(int cameraId, FlashMode mode) async {
    flashModes.add(mode);
  }

  @override
  Future<void> setFocusMode(int cameraId, FocusMode mode) async {}

  @override
  Future<void> setFocusPoint(int cameraId, Point<double>? point) async {
    focusPoints.add(point);
  }

  @override
  Future<void> setExposurePoint(int cameraId, Point<double>? point) async {
    exposurePoints.add(point);
  }

  @override
  Future<double> getMinZoomLevel(int cameraId) async => 1.0;

  @override
  Future<double> getMaxZoomLevel(int cameraId) async => 4.0;

  @override
  Future<void> setZoomLevel(int cameraId, double zoom) async {
    zoomLevels.add(zoom);
  }

  @override
  Future<void> dispose(int cameraId) async {
    disposeCallCount++;
    await _initialized.remove(cameraId)?.close();
  }
}

const backCamera = CameraDescription(
  name: 'back',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);

const frontCamera = CameraDescription(
  name: 'front',
  lensDirection: CameraLensDirection.front,
  sensorOrientation: 270,
);

void main() {
  setUpOnoWidgetTest();

  /// 카메라 화면을 띄우고, 닫힐 때 돌려준 값을 [result] 에 담는다.
  ///
  /// 실제로도 `CameraHandler` 가 `Navigator.push` 로 띄우므로 같은 모양으로
  /// 감싼다. 그래야 이걸로 쓰기가 무엇을 들고 나가는지 볼 수 있다.
  Future<List<XFile?>> pumpCameraScreen(
    WidgetTester tester, {
    List<CameraDescription> cameras = const [backCamera, frontCamera],
    Size surfaceSize = OnoSurface.phone,
    double textScale = 1.0,
    bool settleAfterPush = true,
  }) async {
    final result = <XFile?>[];

    // 화면을 Navigator 로 띄우므로 MediaQuery 를 home 안에서 감싸면 안 닿는다.
    // 기기 설정을 바꾸듯 뷰 쪽에서 글자 배율을 올린다.
    if (textScale != 1.0) {
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (inner) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                result.add(
                  await Navigator.of(inner).push<XFile>(
                    MaterialPageRoute<XFile>(
                      builder: (_) => CameraScreen(cameras: cameras),
                    ),
                  ),
                );
              },
              child: const Text('카메라 열기'),
            ),
          ),
        ),
      ),
      surfaceSize: surfaceSize,
      settle: false,
    );
    await tester.pump();
    await tester.tap(find.text('카메라 열기'));

    if (settleAfterPush) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return result;
  }

  FakeCameraPlatform installFake({
    Object? createError,
    Completer<void>? gate,
  }) {
    final fake = FakeCameraPlatform(createError: createError, gate: gate)
      ..prepare();
    CameraPlatform.instance = fake;
    return fake;
  }

  group('CameraScreen', () {
    testWidgets('초기화가 끝나기 전에는 여는 중이라고 알린다', (tester) async {
      final gate = Completer<void>();
      installFake(gate: gate);

      await pumpCameraScreen(tester, settleAfterPush: false);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('카메라를 여는 중이에요'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_rounded), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('미리보기가 뜨면 상단과 하단 컨트롤이 모두 보인다', (tester) async {
      installFake();

      await pumpCameraScreen(tester);

      expect(find.byType(CameraPreview), findsOneWidget);
      // 상단: 닫기, 플래시, 전후면 전환
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.flash_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.flip_camera_ios_rounded), findsOneWidget);
      // 하단: 갤러리에서 고르기, 셔터
      expect(find.byIcon(Icons.photo_library_rounded), findsOneWidget);
      expect(find.bySemanticsLabel('촬영'), findsOneWidget);
    });

    testWidgets('후면 카메라뿐이면 전후면 전환 버튼을 두지 않는다', (tester) async {
      installFake();

      await pumpCameraScreen(tester, cameras: const [backCamera]);

      expect(find.byIcon(Icons.flip_camera_ios_rounded), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('플래시는 끔 자동 켬 순으로 돌고 그때마다 카메라에 전달된다', (tester) async {
      final fake = installFake();

      await pumpCameraScreen(tester);
      // 초기화하면서 한 번 넣는다. 그다음부터가 사용자가 누른 것이다.
      final beforeTaps = fake.flashModes.length;

      await tester.tap(find.byIcon(Icons.flash_off_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.flash_auto_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.flash_auto_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.flash_on_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.flash_on_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.flash_off_rounded), findsOneWidget);

      expect(
        fake.flashModes.sublist(beforeTaps),
        [FlashMode.auto, FlashMode.always, FlashMode.off],
      );
    });

    testWidgets('전면으로 바꾸면 플래시 버튼이 사라진다', (tester) async {
      final fake = installFake();

      await pumpCameraScreen(tester);
      expect(find.byIcon(Icons.flash_off_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.flip_camera_ios_rounded));
      await tester.pumpAndSettle();

      expect(fake.lastCreatedDescription, frontCamera);
      expect(
        find.byIcon(Icons.flash_off_rounded),
        findsNothing,
        reason: '전면 카메라에는 플래시가 없다',
      );
      expect(find.byIcon(Icons.flip_camera_ios_rounded), findsOneWidget);
    });

    testWidgets('셔터를 누르면 바로 나가지 않고 확인 단계를 보여 준다', (tester) async {
      final fake = installFake();

      final result = await pumpCameraScreen(tester);

      await tester.tap(find.bySemanticsLabel('촬영'));
      await tester.pumpAndSettle();

      expect(fake.takePictureCallCount, 1);
      expect(find.text('다시 찍기'), findsOneWidget);
      expect(find.text('이걸로 쓰기'), findsOneWidget);
      expect(
        result,
        isEmpty,
        reason: '확인하기 전에 이전 화면으로 돌아가면 안 된다',
      );
      // 확인 중에는 촬영 컨트롤이 보이지 않는다.
      expect(find.bySemanticsLabel('촬영'), findsNothing);
    });

    testWidgets('다시 찍기를 누르면 촬영 화면으로 돌아오고 방금 찍은 것이 남는다', (tester) async {
      installFake();

      final result = await pumpCameraScreen(tester);

      await tester.tap(find.bySemanticsLabel('촬영'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다시 찍기'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('촬영'), findsOneWidget);
      expect(find.text('이걸로 쓰기'), findsNothing);
      expect(
        find.bySemanticsLabel('방금 찍은 사진 다시 보기'),
        findsOneWidget,
        reason: '다시 찍기를 눌러도 앞서 찍은 것으로 되돌아갈 수 있어야 한다',
      );
      expect(result, isEmpty);
    });

    testWidgets('이걸로 쓰기를 누르면 찍은 파일을 들고 화면이 닫힌다', (tester) async {
      final fake = installFake();

      final result = await pumpCameraScreen(tester);

      await tester.tap(find.bySemanticsLabel('촬영'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('이걸로 쓰기'));
      await tester.pumpAndSettle();

      expect(result, hasLength(1));
      expect(result.single?.path, fake.picturePath);
      expect(find.byType(CameraScreen), findsNothing);
    });

    testWidgets('미리보기를 탭하면 그 자리로 초점과 노출을 맞춘다', (tester) async {
      final fake = installFake();

      await pumpCameraScreen(tester);

      final preview = tester.getRect(find.byType(CameraPreview));
      await tester.tapAt(preview.center);
      await tester.pumpAndSettle();

      expect(fake.focusPoints, hasLength(1));
      expect(fake.exposurePoints, hasLength(1));
      expect(fake.focusPoints.single!.x, closeTo(0.5, 0.01));
      expect(fake.focusPoints.single!.y, closeTo(0.5, 0.01));
    });

    testWidgets('카메라를 못 열면 다시 시도와 닫기를 보여 준다', (tester) async {
      installFake(
        createError: CameraException('CameraAccessRestricted', '다른 앱이 쓰는 중'),
      );

      await pumpCameraScreen(tester);

      expect(find.text('카메라를 열 수 없어요'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
      expect(find.text('닫기'), findsOneWidget);
      expect(find.text('설정 열기'), findsNothing);
      expect(find.byType(CameraPreview), findsNothing);
    });

    testWidgets('권한이 거부된 것이면 설정 열기를 보여 준다', (tester) async {
      installFake(
        createError: CameraException('CameraAccessDenied', '권한 없음'),
      );

      await pumpCameraScreen(tester);

      expect(find.text('카메라 권한이 꺼져 있어요'), findsOneWidget);
      expect(find.text('설정 열기'), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);
    });

    for (final size in [OnoSurface.smallPhone, OnoSurface.tablet]) {
      testWidgets('${size.width.toInt()}dp 글자 1.6배에서 넘치지 않는다', (tester) async {
        disableAnimationsForTest(tester);
        installFake();

        await pumpCameraScreen(
          tester,
          surfaceSize: size,
          textScale: 1.6,
        );

        expect(
          tester.takeException(),
          isNull,
          reason: '${size.width.toInt()}dp 글자 1.6배 촬영 화면에서 넘쳤다',
        );

        // 확인 단계도 같은 조건에서 본다. 버튼 둘이 한 줄을 나눠 쓰는 자리라
        // 촬영 화면보다 이쪽이 먼저 넘친다.
        await tester.tap(find.bySemanticsLabel('촬영'));
        await tester.pumpAndSettle();

        expect(find.text('이걸로 쓰기'), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: '${size.width.toInt()}dp 글자 1.6배 확인 단계에서 넘쳤다',
        );
      });
    }

    testWidgets('안내 화면도 작은 폰에서 글자를 키우면 넘치지 않는다', (tester) async {
      disableAnimationsForTest(tester);
      installFake(
        createError: CameraException('CameraAccessDenied', '권한 없음'),
      );

      await pumpCameraScreen(
        tester,
        surfaceSize: OnoSurface.smallPhone,
        textScale: 1.6,
      );

      expect(find.text('설정 열기'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
