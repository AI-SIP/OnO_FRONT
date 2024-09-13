import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../GlobalModule/Theme/GridPainter.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../GlobalModule/Theme/DecorateText.dart';
import '../GlobalModule/Theme/UnderlinedText.dart';
import '../Model/ProblemModel.dart';

class ProblemShareScreen extends StatefulWidget {
  final ProblemModel problem;
  final GlobalKey _globalKey = GlobalKey();

  ProblemShareScreen({super.key, required this.problem});

  @override
  _ProblemShareScreenState createState() => _ProblemShareScreenState();
}

class _ProblemShareScreenState extends State<ProblemShareScreen> {
  bool isImageLoaded = false; // 이미지 로드 상태
  bool hasShared = false; // 공유 함수 호출 여부
  Image? _image; // 이미지 위젯
  ImageStreamListener? _imageStreamListener; // 이미지 로드 감지 리스너

  @override
  void initState() {
    super.initState();
    // 이미지가 있을 경우 네트워크 이미지를 사용
    if (widget.problem.processImageUrl != null) {
      _image = Image.network(
        widget.problem.processImageUrl!,
        fit: BoxFit.contain,
      );
    } else {
      // 이미지가 없을 경우 로컬 기본 이미지 사용
      _image = Image.asset(
        'assets/no_image.png',
        fit: BoxFit.contain,
      );
    }

    // 이미지 로딩이 완료되면 상태 업데이트
    final ImageStream imageStream = _image!.image.resolve(const ImageConfiguration());
    _imageStreamListener = ImageStreamListener(
          (ImageInfo imageInfo, bool synchronousCall) {
        if (!isImageLoaded) {
          isImageLoaded = true;
          setState(() {});
        }
      },
    );
    imageStream.addListener(_imageStreamListener!);
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
    final formattedDate = DateFormat('yyyy년 M월 d일').format(widget.problem.solvedAt!);

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
                        if (widget.problem.solvedAt != null)
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: themeProvider.primaryColor),
                              const SizedBox(width: 8),
                              DecorateText(
                                text: '푼 날짜',
                                fontSize: 20,
                                color: themeProvider.primaryColor,
                              ),
                              const Spacer(),
                              UnderlinedText(
                                text: formattedDate,
                                fontSize: 20,
                              ),
                            ],
                          ),
                        const SizedBox(height: 30),
                        if (widget.problem.processImageUrl != null)
                          Row(
                            children: [
                              Icon(Icons.camera_alt, color: themeProvider.primaryColor),
                              const SizedBox(width: 8),
                              DecorateText(
                                text: '문제 이미지',
                                fontSize: 20,
                                color: themeProvider.primaryColor,
                              ),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                      child: Stack(
                                        children: [
                                          _image!,
                                          if (!isImageLoaded)
                                            const Center(
                                              child: CircularProgressIndicator(),
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

      // 추가적인 딜레이를 줘서 boundary가 준비될 시간을 확보합니다.
      await Future.delayed(const Duration(milliseconds: 20));

      // RenderRepaintBoundary로부터 이미지를 캡처
      RenderRepaintBoundary boundary = widget._globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // 이미지 캡처
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
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

      // 필요에 따라 화면 닫기
      // Navigator.pop(context, true);
    } catch (e, stackTrace) {
      log('이미지 공유 실패: $e');
      log('스택 트레이스: $stackTrace');
      // 에러 처리 로직
    }
  }
}