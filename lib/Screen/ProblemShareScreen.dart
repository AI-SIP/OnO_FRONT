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

import '../GlobalModule/Theme/ThemeHandler.dart';
import '../Model/ProblemModel.dart';

class ProblemShareScreen extends StatelessWidget {
  final ProblemModel problem;
  final GlobalKey _globalKey = GlobalKey();

  ProblemShareScreen({required this.problem});

  @override
  Widget build(BuildContext context) {

    final themeProvider = Provider.of<ThemeHandler>(context);

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 1)); // 렌더링 완료 대기
      await _shareProblemAsImage(context); // 바로 공유 창 실행
    });

    return Scaffold(
      appBar: AppBar(
        title: DecorateText(text: '공유 화면 미리보기', fontSize: 28, color: themeProvider.primaryColor),
      ),
      body: RepaintBoundary(
        key: _globalKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(problem.reference ?? '문제 제목 없음',
                  style: TextStyle(fontSize: 24)),
              SizedBox(height: 10),
              if (problem.problemImageUrl != null)
                Image.network(problem.problemImageUrl!),
              SizedBox(height: 10),
              if (problem.solvedAt != null)
                Text(
                    '푼 날짜: ${DateFormat('yyyy-MM-dd').format(problem.solvedAt!)}'),
              SizedBox(height: 10),
              if (problem.memo != null) Text('메모: ${problem.memo}'),
            ],
          ),
        ),
      ),
    );
  }

  // 문제 캡처 후 이미지로 공유하는 로직
  Future<void> _shareProblemAsImage(context) async {
    try {
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
          text: '제가 푼 문제를 확인해보세요!',
          sharePositionOrigin: Rect.fromPoints(
            Offset.zero,
            Offset(size.width / 3 * 2, size.height),
          ),
        );
      } else {
        log('Invalid box size, defaulting to basic share...');
        Share.shareXFiles([xFile], text: '제가 푼 문제를 확인해보세요!');
      }
    } catch (e) {
      log('이미지 공유 실패: $e');
    }
  }
}
