import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../Text/StandardText.dart';
import '../Theme/ThemeHandler.dart';

class CameraHandler {
  CameraController? _controller;
  List<CameraDescription>? _availableCameras;

  CameraHandler();

  // Initialize available cameras
  Future<void> init() async {
    _availableCameras = await availableCameras();
  }

  // Launch the camera screen and return the captured image
  Future<XFile?> takePicture(BuildContext context) async {
    if (_availableCameras == null || _availableCameras!.isEmpty) {
      debugPrint("No cameras available.");
      return null;
    }

    final camera = _availableCameras!.first;
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraScreen(camera: camera),
      ),
    );
  }

  // Dispose camera controller
  void dispose() {
    _controller?.dispose();
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({super.key, required this.camera});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    // 화면 방향을 세로로 고정
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              // ConnectionState.done 은 future 가 에러로 끝난 경우에도 done 이다.
              // 권한 거부나 다른 앱의 카메라 점유로 initialize() 가 실패하면
              // previewSize 가 null 이라 aspectRatio 접근에서 크래시가 난다.
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || !_controller.value.isInitialized) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: StandardText(
                      text: '카메라를 열 수 없습니다.\n카메라 권한을 확인하거나 다른 앱을 종료한 뒤 다시 시도해주세요.',
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: OverflowBox(
                    maxHeight: MediaQuery.of(context).size.height,
                    maxWidth: MediaQuery.of(context).size.width,
                    child: CameraPreview(_controller),
                  ),
                ),
              );
            },
          ),

          // 상단 안내 영역
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.black87,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.93),
                            themeProvider.primaryColor.withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            color: themeProvider.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: StandardText(
                              text: '이미지를 촬영해주세요!',
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 중앙 촬영 버튼
          Positioned(
            left: 0,
            right: 0,
            bottom: safeBottom + 24,
            child: Center(
              child: InkWell(
                onTap: () async {
                  try {
                    await _initializeControllerFuture;
                    final image = await _controller.takePicture();
                    if (!context.mounted) return;
                    Navigator.pop(context, image);
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                },
                borderRadius: BorderRadius.circular(42),
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.95),
                      width: 3,
                    ),
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                  child: Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeProvider.primaryColor,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
