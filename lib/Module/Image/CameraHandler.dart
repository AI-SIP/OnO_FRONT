import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../Motion/TossPageRoute.dart';
import 'CameraCapture.dart';
import 'CameraScreen.dart';

export 'CameraCapture.dart';

/// 촬영 화면을 띄우고 찍힌 사진을 돌려주는 것까지만 한다.
///
/// 화면 자체는 [CameraScreen] 에 있다. 예전에는 둘이 한 파일에 있었는데,
/// 화면이 커지면서 핸들러가 어디 있는지 찾기 어려워져 나눴다.
class CameraHandler {
  CameraController? _controller;
  List<CameraDescription>? _availableCameras;

  CameraHandler();

  // Initialize available cameras
  Future<void> init() async {
    _availableCameras = await availableCameras();
  }

  // Launch the camera screen and return the captured image
  //
  // [multiple] 이면 여러 장 모드로 연다. 담아 두고 계속 찍다가 완료를 눌러야
  // 나온다. [maxShots] 는 그때 담을 수 있는 최대 장수다.
  Future<CameraCapture?> takePicture(
    BuildContext context, {
    bool multiple = false,
    int maxShots = 1,
  }) async {
    final cameras = _availableCameras;
    if (cameras == null || cameras.isEmpty) {
      debugPrint("No cameras available.");
      return null;
    }

    // 전후면 전환을 화면 안에서 하므로 목록을 통째로 넘긴다. 어느 것으로
    // 시작할지는 화면이 정한다.
    return Navigator.of(context).push(
      TossPageRoute(
        builder: (context) => CameraScreen(
          cameras: cameras,
          multiple: multiple,
          maxShots: maxShots,
        ),
      ),
    );
  }

  // Dispose camera controller
  void dispose() {
    _controller?.dispose();
  }
}
