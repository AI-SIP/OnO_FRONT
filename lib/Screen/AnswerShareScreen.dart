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

class AnswerShareScreen extends StatelessWidget {
  final ProblemModel problem;
  final GlobalKey _globalKey = GlobalKey();

  AnswerShareScreen({required this.problem});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    bool isImageLoaded = false;

    return Scaffold(
      appBar: AppBar(
        title: DecorateText(
          text: '공유 화면 미리보기',
          fontSize: 28,
          color: themeProvider.primaryColor,
        ),
      ),
      body: RepaintBoundary(
          // 격자무늬를 포함하는 RepaintBoundary로 변경
          key: _globalKey,
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
                      maxHeight: MediaQuery.of(context).size.height, // 화면 높이 최대
                      maxWidth: MediaQuery.of(context).size.width,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.start, // 이미지 위에 푼 날짜 배치
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (problem.reference != null)
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center, // 날짜도 가운데 정렬
                                children: [
                                  UnderlinedText(
                                    text: problem.reference!,
                                    fontSize: 24,
                                    color: themeProvider.primaryColor,
                                  ),
                                ]),
                          const SizedBox(height: 30),
                          if (problem.memo != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start, // 메모를 왼쪽 정렬
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.edit, color: themeProvider.primaryColor),
                                    const SizedBox(width: 8),
                                    DecorateText(
                                      text: '메모',
                                      fontSize: 20,
                                      color: themeProvider.primaryColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8), // 라벨과 메모 텍스트 간의 간격 조정
                                UnderlinedText(
                                  text: problem.memo!,
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          const SizedBox(height: 30),
                          if (problem.answerImageUrl != null)
                            Row(children: [
                              Icon(Icons.camera_alt,
                                  color: themeProvider.primaryColor),
                              const SizedBox(width: 8),
                              DecorateText(
                                  text: '정답 이미지',
                                  fontSize: 20,
                                  color: themeProvider.primaryColor),
                            ]),
                          const SizedBox(height: 20),
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (problem.answerImageUrl != null)
                                    AspectRatio(
                                      aspectRatio: 3 / 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        child: Image.network(
                                          problem.processImageUrl!,
                                          fit: BoxFit.contain,
                                          loadingBuilder:
                                              (BuildContext context, Widget child,
                                              ImageChunkEvent?
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              if (!isImageLoaded) {
                                                isImageLoaded = true;
                                                SchedulerBinding.instance
                                                    .addPostFrameCallback((_) {
                                                  _shareProblemAsImage(context);
                                                });
                                              }
                                              return child;
                                            } else {
                                              return Center(
                                                child:
                                                CircularProgressIndicator(
                                                  value: loadingProgress
                                                      .expectedTotalBytes !=
                                                      null
                                                      ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                      (loadingProgress
                                                          .expectedTotalBytes ??
                                                          1)
                                                      : null,
                                                ),
                                              );
                                            }
                                          },
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
          )),
    );
  }

  // 문제 캡처 후 이미지로 공유하는 로직
  Future<void> _shareProblemAsImage(context) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      // RepaintBoundary로부터 이미지를 캡처
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 임시 파일에 저장
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/problem.png').create();
      await file.writeAsBytes(pngBytes);

      // XFile을 사용해 이미지 공유
      final XFile xFile = XFile(file.path);

      // RenderBox에서 위치 정보 가져오기
      final RenderBox box =
          _globalKey.currentContext!.findRenderObject() as RenderBox;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      final size = MediaQuery.of(context).size;

      if (rect.size.width > 0 && rect.size.height > 0) {
        Share.shareXFiles(
          [xFile],
          text: '내 오답노트야! 어때?',
          sharePositionOrigin: Rect.fromPoints(
            Offset.zero,
            Offset(size.width / 3 * 2, size.height),
          ),
        );
      } else {
        log('Invalid box size, defaulting to basic share...');
        Share.shareXFiles([xFile], text: '내 오답노트야! 어때?');
      }

      Navigator.pop(context, true);
    } catch (e) {
      log('이미지 공유 실패: $e');
      Navigator.pop(context, false);
    }
  }
}
