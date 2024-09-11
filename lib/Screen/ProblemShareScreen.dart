import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:ono/GlobalModule/Theme/DecorateText.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../GlobalModule/Theme/GridPainter.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../GlobalModule/Theme/UnderlinedText.dart';
import '../Model/ProblemModel.dart';

class ProblemShareScreen extends StatelessWidget {
  final ProblemModel problem;
  final GlobalKey _globalKey = GlobalKey();

  ProblemShareScreen({required this.problem});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final formattedDate = DateFormat('yyyy년 M월 d일').format(problem.solvedAt!);

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _shareProblemAsImage(context); // 바로 공유 창 실행
    });

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
        child:Container(
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
                        if (problem.solvedAt != null)
                          Row(children: [
                            Icon(Icons.calendar_today,
                                color: themeProvider.primaryColor),
                            const SizedBox(width: 8),
                            DecorateText(
                                text: '푼 날짜',
                                fontSize: 20,
                                color: themeProvider.primaryColor),
                            const Spacer(),
                            UnderlinedText(text: formattedDate, fontSize: 20),
                          ]),
                        const SizedBox(height: 30),
                        if (problem.problemImageUrl != null)
                          Row(children: [
                            Icon(Icons.camera_alt,
                                color: themeProvider.primaryColor),
                            const SizedBox(width: 8),
                            DecorateText(
                                text: '문제 이미지',
                                fontSize: 20,
                                color: themeProvider.primaryColor),
                          ]),
                        const SizedBox(height: 20),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (problem.problemImageUrl != null)
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight:
                                      MediaQuery.of(context).size.height *
                                          0.7, // 최대 높이 제한
                                    ),
                                    child: Image.network(
                                      problem.problemImageUrl!,
                                      fit: BoxFit.contain,
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
        )
      ),
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