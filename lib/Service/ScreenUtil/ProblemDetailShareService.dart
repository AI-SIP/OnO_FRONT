import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ProblemDetailShareService {
  // 문제를 이미지로 캡처하여 공유하는 메서드
  Future<void> shareProblemAsImage(GlobalKey repaintKey) async {
    try {
      // RepaintBoundary의 GlobalKey를 사용해 이미지 캡처
      RenderRepaintBoundary boundary =
      repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 임시 파일로 저장
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/problem.png').create();
      await file.writeAsBytes(pngBytes);

      // 공유를 위한 파일 생성 및 호출
      final XFile xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: '내 오답노트를 공유합니다!');
    } catch (e) {
      log(e.toString());
    }
  }
}