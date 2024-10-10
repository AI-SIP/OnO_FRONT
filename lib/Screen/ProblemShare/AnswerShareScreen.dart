import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../GlobalModule/Image/DisplayImage.dart';
import '../../GlobalModule/Theme/HandWriteText.dart';
import '../../GlobalModule/Theme/GridPainter.dart';
import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../GlobalModule/Theme/UnderlinedText.dart';
import '../../Model/ProblemModel.dart';

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
    if (widget.problem.answerImageUrl != null &&
        widget.problem.answerImageUrl!.isNotEmpty) {
      _image = Image.network(
        widget.problem.answerImageUrl!,
        fit: BoxFit.contain,
      );
    } else {
      // 이미지가 없을 경우 로컬 기본 이미지 사용
      _image = Image.asset(
        'assets/no_image.png',
        fit: BoxFit.contain,
      );
    }

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
    final String memoText =
        widget.problem.memo != null && widget.problem.memo!.isNotEmpty
            ? widget.problem.memo!
            : '메모 없음';

    /*
    // 이미지가 로드되었고, 공유하지 않았다면 공유 함수 호출
    if (isImageLoaded && !hasShared) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _shareProblemAsImage();
      });
      hasShared = true; // 한 번만 호출되도록 설정
    }

     */

    return Scaffold(
      appBar: AppBar(
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
                            (widget.problem.reference != null && widget.problem.reference!.isNotEmpty) ? widget.problem.reference! : "출처 없음",
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
                                // 메모가 있으면 표시, 없으면 '메모 없음' 표시
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.edit,
                                            color: themeProvider.primaryColor),
                                        const SizedBox(width: 8),
                                        HandWriteText(
                                          text: '메모',
                                          fontSize: 20,
                                          color: themeProvider.primaryColor,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    UnderlinedText(
                                      text: memoText,
                                      fontSize: 20,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                Row(
                                  children: [
                                    Icon(Icons.camera_alt,
                                        color: themeProvider.primaryColor),
                                    const SizedBox(width: 8),
                                    HandWriteText(
                                      text: '정답 이미지',
                                      fontSize: 20,
                                      color: themeProvider.primaryColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Flexible(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (_image != null)
                                          buildAnswerImage(context,
                                              widget.problem.answerImageUrl),
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
              )
            ],
          )),
    );
  }

  // 정답 이미지 출력 함수
  Widget buildAnswerImage(BuildContext context, String? imageUrl) {
    final mediaQuery = MediaQuery.of(context);
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Center(
      child: Container(
        width: mediaQuery.size.width * 0.8,
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
      // 프레임 완료 후 실행되도록 대기
      await WidgetsBinding.instance.endOfFrame;

      RenderRepaintBoundary? boundary = widget._globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary?;

      // boundary가 null인 경우 종료
      if (boundary == null) return;

      // 추가적인 딜레이를 줘서 boundary가 준비될 시간을 확보합니다.
      await Future.delayed(const Duration(milliseconds: 20));

      // 이미지를 캡처합니다.
      ui.Image image = await boundary.toImage(pixelRatio: MediaQuery.of(context).devicePixelRatio);

      // 불투명한 배경을 가진 새로운 캔버스를 생성합니다.
      final paint = Paint();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final imageRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

      // 캔버스에 불투명 배경을 먼저 채운 후, 캡처된 이미지를 덧씁니다.
      canvas.drawRect(imageRect, paint..color = Colors.white);
      canvas.drawImage(image, Offset.zero, paint);
      final picture = recorder.endRecording();
      final imgWithOpaqueBg = await picture.toImage(image.width, image.height);

      ByteData? byteData = await imgWithOpaqueBg.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/answer_$timestamp.png';
      final file = await File(filePath).create();
      await file.writeAsBytes(pngBytes);

      final XFile xFile = XFile(file.path);

      Share.shareXFiles([xFile], text: '내 오답노트야! 어때?');

      // 공유 후 화면을 닫습니다.
      Navigator.pop(context);
    } catch (e, stackTrace) {
      log('이미지 공유 실패: $e');
      log('스택 트레이스: $stackTrace');
    }
  }
}
