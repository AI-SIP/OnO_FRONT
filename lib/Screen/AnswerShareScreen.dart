import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../GlobalModule/Theme/DecorateText.dart';
import '../GlobalModule/Theme/GridPainter.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../GlobalModule/Theme/UnderlinedText.dart';
import '../Model/ProblemModel.dart';

class AnswerShareScreen extends StatefulWidget {
  final ProblemModel problem;
  final GlobalKey _globalKey = GlobalKey();

  AnswerShareScreen({super.key, required this.problem});

  @override
  _AnswerShareScreenState createState() => _AnswerShareScreenState();
}

class _AnswerShareScreenState extends State<AnswerShareScreen> {
  bool isImageLoaded = false; // 이미지 로드 상태
  bool hasShared = false; // 공유 함수 호출 여부
  Image? _image; // 이미지 위젯
  ImageStreamListener? _imageStreamListener; // 이미지 로드 감지 리스너

  @override
  void initState() {
    super.initState();
    if (widget.problem.answerImageUrl != null) {
      _image = Image.network(
        widget.problem.answerImageUrl!,
        fit: BoxFit.contain,
      );

      final ImageStream imageStream =
      _image!.image.resolve(const ImageConfiguration());
      _imageStreamListener = ImageStreamListener(
              (ImageInfo imageInfo, bool synchronousCall) {
            if (!isImageLoaded) {
              isImageLoaded = true;
              setState(() {});
            }
          });
      imageStream.addListener(_imageStreamListener!);
    } else {
      // 이미지가 없을 경우 바로 공유
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _shareProblemAsImage();
      });
    }
  }

  @override
  void dispose() {
    if (_imageStreamListener != null) {
      _image!.image
          .resolve(const ImageConfiguration())
          .removeListener(_imageStreamListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    bool isImageLoaded = this.isImageLoaded;

    // 이미지가 로드되었고, 공유하지 않았다면 공유 함수 호출
    if (isImageLoaded && !hasShared) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _shareProblemAsImage();
      });
      hasShared = true; // 한 번만 호출되도록 설정
    }

    return Scaffold(
      appBar: AppBar(
        title: DecorateText(
          text: '공유 화면 미리보기',
          fontSize: 24,
          color: themeProvider.primaryColor,
        ),
      ),
      body: RepaintBoundary(
        key: widget._globalKey,
        child: Container(
          color: themeProvider.primaryColor.withOpacity(0.03),
          child: Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: GridPainter(gridColor: themeProvider.primaryColor),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height,
                    maxWidth: MediaQuery.of(context).size.width,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.problem.reference != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              UnderlinedText(
                                text: widget.problem.reference!,
                                fontSize: 24,
                                color: themeProvider.primaryColor,
                              ),
                            ],
                          ),
                        const SizedBox(height: 30),
                        if (widget.problem.memo != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.edit,
                                      color: themeProvider.primaryColor),
                                  const SizedBox(width: 8),
                                  DecorateText(
                                    text: '메모',
                                    fontSize: 20,
                                    color: themeProvider.primaryColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              UnderlinedText(
                                text: widget.problem.memo!,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        const SizedBox(height: 30),
                        if (widget.problem.answerImageUrl != null)
                          Row(
                            children: [
                              Icon(Icons.camera_alt,
                                  color: themeProvider.primaryColor),
                              const SizedBox(width: 8),
                              DecorateText(
                                  text: '정답 이미지',
                                  fontSize: 20,
                                  color: themeProvider.primaryColor),
                            ],
                          ),
                        const SizedBox(height: 20),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_image != null)
                                  AspectRatio(
                                    aspectRatio: 3 / 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0),
                                      child: Stack(
                                        children: [
                                          _image!,
                                          if (!isImageLoaded)
                                            const Center(
                                              child:
                                              CircularProgressIndicator(),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 문제 캡처 후 이미지로 공유하는 로직
  Future<void> _shareProblemAsImage() async {
    try {
      // 프레임 완료 후 실행되도록 대기
      await WidgetsBinding.instance.endOfFrame;

      // RenderRepaintBoundary로부터 이미지를 캡처
      RenderRepaintBoundary boundary = widget._globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // boundary가 준비될 때까지 대기
      while (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 5));
        boundary = widget._globalKey.currentContext!
            .findRenderObject() as RenderRepaintBoundary;
      }

      // 이미지 캡처
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 임시 파일에 저장
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/problem_$timestamp.png';
      final file = await File(filePath).create();
      await file.writeAsBytes(pngBytes);

      // 이미지 공유
      final XFile xFile = XFile(file.path);

      final RenderBox box = context.findRenderObject() as RenderBox;
      final size = MediaQuery.of(context).size;

      Share.shareXFiles(
        [xFile],
        text: '내 오답노트야! 어때?',
        sharePositionOrigin: box.localToGlobal(Offset.zero) & size,
      );

      // 화면 닫기 (필요 시)
      // Navigator.pop(context, true);
    } catch (e, stackTrace) {
      log('이미지 공유 실패: $e');
      log('스택 트레이스: $stackTrace');
      // Navigator.pop(context, false);
    }
  }
}