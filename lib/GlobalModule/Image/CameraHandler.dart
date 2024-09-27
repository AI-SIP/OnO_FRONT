import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/HandWriteText.dart';
import 'package:provider/provider.dart';

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
      log("No cameras available.");
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
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      appBar: AppBar(
        title: HandWriteText(
          text: '이미지를 촬영해주세요!',
          color: themeProvider.primaryColor,
          fontSize: 24,
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
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
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(
                  bottom: 50.0), // Increase bottom padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child: const HandWriteText(
                        text: '취소',
                        color: Colors.black,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: () async {
                      try {
                        await _initializeControllerFuture;
                        final image = await _controller.takePicture();
                        Navigator.of(context).pop(image);
                      } catch (e) {
                        log(e.toString());
                      }
                    },
                    child: const Icon(Icons.camera_alt),
                  ),
                  const SizedBox(width: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
