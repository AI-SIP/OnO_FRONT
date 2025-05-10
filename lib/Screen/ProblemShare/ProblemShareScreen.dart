import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:ono/Model/Problem/TemplateType.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../Model/Problem/ProblemModelWithTemplate.dart';
import '../../Module/Image/DisplayImage.dart';
import '../../Module/Text/HandWriteText.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Text/UnderlinedText.dart';
import '../../Module/Theme/GridPainter.dart';
import '../../Module/Theme/ThemeHandler.dart';

class ProblemShareScreen extends StatefulWidget {
  final ProblemModelWithTemplate problem;
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
  String? imageUrl;

  @override
  void initState() {
    super.initState();

    // 이미지가 있을 경우 네트워크 이미지를 사용
    if (widget.problem.templateType == TemplateType.simple) {
      if (widget.problem.problemImageUrl != null) {
        imageUrl = widget.problem.problemImageUrl;
        _image = Image.network(
          widget.problem.problemImageUrl!,
          fit: BoxFit.contain,
        );
      } else {
        // 이미지가 없을 경우 로컬 기본 이미지 사용
        _image = Image.asset(
          'assets/no_image.png',
          fit: BoxFit.contain,
        );
      }
    } else {
      if (widget.problem.processImageUrl != null) {
        imageUrl = widget.problem.processImageUrl;
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
    }

    // 이미지 로딩이 완료되면 상태 업데이트
    final ImageStream imageStream =
        _image!.image.resolve(const ImageConfiguration());
    _imageStreamListener = ImageStreamListener(
      (ImageInfo imageInfo, bool synchronousCall) {
        if (!isImageLoaded) {
          isImageLoaded = true;
          setState(() {});
        }
      },
    );
    imageStream.addListener(_imageStreamListener!);
    _shareProblemAsImage();
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
    final formattedDate = DateFormat('yyyy년 M월 d일')
        .format(widget.problem.solvedAt ?? widget.problem.createdAt!);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: StandardText(
          text: '공유 화면 미리보기',
          fontSize: 20,
          color: themeProvider.primaryColor,
        ),
      ),
      body: RepaintBoundary(
        key: widget._globalKey,
        child: Column(
          children: [
            Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.03),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          (widget.problem.reference != null &&
                                  widget.problem.reference!.isNotEmpty)
                              ? widget.problem.reference!
                              : "제목 없음",
                          style: TextStyle(
                            color: themeProvider.primaryColor,
                            fontSize: 24,
                            fontFamily: 'HandWrite',
                            fontWeight: ui.FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )),
            Expanded(
                child: Container(
              color: themeProvider.primaryColor.withOpacity(0.03),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: GridPainter(
                      gridColor: themeProvider.primaryColor,
                      isSpring: true,
                    ),
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
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: themeProvider.primaryColor),
                                const SizedBox(width: 8),
                                HandWriteText(
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
                            const SizedBox(height: 40),
                            Row(
                              children: [
                                Icon(Icons.camera_alt,
                                    color: themeProvider.primaryColor),
                                const SizedBox(width: 8),
                                HandWriteText(
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
                                      buildProblemImage(context, imageUrl),
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
            ))
          ],
        ),
      ),
    );
  }

  // 문제 이미지 출력 함수
  Widget buildProblemImage(BuildContext context, String? imageUrl) {
    final mediaQuery = MediaQuery.of(context);
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Center(
      child: Container(
        width: mediaQuery.size.width * 0.9,
        decoration: BoxDecoration(
          color: themeProvider.primaryColor.withOpacity(0.1), // 배경색 추가
          borderRadius: BorderRadius.circular(10), // 모서리 둥글게 설정
        ),
        child: AspectRatio(
          aspectRatio: 0.8, // 원하는 비율로 이미지의 높이를 조정
          child: DisplayImage(
            imagePath: imageUrl,
            fit: BoxFit.contain, // 이미지 전체를 보여주기 위한 설정
          ),
        ),
      ),
    );
  }

  Future<void> _shareProblemAsImage() async {
    try {
      await WidgetsBinding.instance.endOfFrame;

      await Future.delayed(const Duration(milliseconds: 30));

      RenderRepaintBoundary boundary = widget._globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // 이미지를 캡처합니다.
      ui.Image image = await boundary.toImage(
          pixelRatio: MediaQuery.of(context).devicePixelRatio);

      // 불투명한 배경을 가진 새로운 캔버스를 생성합니다.
      final paint = Paint();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final imageRect =
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

      // 캔버스에 불투명 배경을 먼저 채운 후, 캡처된 이미지를 덧씁니다.
      canvas.drawRect(imageRect, paint..color = Colors.white);
      canvas.drawImage(image, Offset.zero, paint);
      final picture = recorder.endRecording();
      final imgWithOpaqueBg = await picture.toImage(image.width, image.height);

      ByteData? byteData =
          await imgWithOpaqueBg.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/problem_$timestamp.png';
      final file = await File(filePath).create();
      await file.writeAsBytes(pngBytes);

      final XFile xFile = XFile(file.path);

      final RenderBox box = context.findRenderObject() as RenderBox;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      final size = MediaQuery.of(context).size;

      if (rect.size.width > 0 && rect.size.height > 0) {
        Share.shareXFiles(
          [xFile],
          text: '내 오답노트야! 어때?\n\nOnO 다운로드: https://ono-app.com/home',
          sharePositionOrigin: Rect.fromPoints(
            Offset.zero,
            Offset(size.width / 3 * 2, size.height),
          ),
        );
      } else {
        log('Invalid box size, defaulting to basic share...');
        Share.shareXFiles([xFile],
            text: '내 오답노트야! 어때?\n\nOnO 다운로드: https://ono-app.com/home');
      }

      Navigator.pop(context);
    } catch (e, stackTrace) {
      log('이미지 공유 실패: $e');
      log('스택 트레이스: $stackTrace');
    }
  }
}
