import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Theme/StandardText.dart';
import '../../Theme/ThemeHandler.dart';
import 'ImageCoordinateGuideDialog.dart';

class ImageCoordinatePickerHandler {
  Future<List<double>?> showCoordinatePicker(
      BuildContext context, String imagePath) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CoordinatePickerScreen(imagePath: imagePath),
      ),
    );
    return result;
  }
}

class CoordinatePickerScreen extends StatefulWidget {
  final String imagePath;

  const CoordinatePickerScreen({required this.imagePath, super.key});

  @override
  _CoordinatePickerScreenState createState() => _CoordinatePickerScreenState();
}

class _CoordinatePickerScreenState extends State<CoordinatePickerScreen> {
  double rectLeft = 100;
  double rectTop = 100;
  double rectWidth = 150;
  double rectHeight = 150;

  double initialRectLeft = 100;
  double initialRectTop = 100;
  double initialRectWidth = 150;
  double initialRectHeight = 150;

  double originalImageWidth = 1;
  double originalImageHeight = 1;

  bool isRectangleVisible = false; // 영역 선택 상태
  bool isInitialButtonsVisible = true; // 초기 버튼 표시 여부

  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _getImageDimensions();

    initialRectLeft = rectLeft;
    initialRectTop = rectTop;
    initialRectWidth = rectWidth;
    initialRectHeight = rectHeight;
  }

  Future<void> _getImageDimensions() async {
    final file = File(widget.imagePath);
    final data = await file.readAsBytes();
    final image = await decodeImageFromList(data);
    setState(() {
      originalImageWidth = image.width.toDouble();
      originalImageHeight = image.height.toDouble();
    });
  }

  void _resetToInitialState() {
    setState(() {
      rectLeft = initialRectLeft;
      rectTop = initialRectTop;
      rectWidth = initialRectWidth;
      rectHeight = initialRectHeight;
      isRectangleVisible = false;
      isInitialButtonsVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final double screenWidth = MediaQuery.of(context).size.width;

    final double displayImageWidth = screenWidth * 0.9;
    final double displayImageHeight = displayImageWidth * originalImageHeight / originalImageWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: StandardText(
          text: '필기만 작성된 영역을 선택해주세요!',
          fontSize: 20,
          color: themeProvider.primaryColor,
          textAlign: TextAlign.center,
        ),
      ),
      body: Column(
        children: [
          // 사용 방법 버튼
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: screenWidth * 0.5,
                child: OutlinedButton(
                  onPressed: () {
                    ImageCoordinateGuideDialog.show(context);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: themeProvider.primaryColor, width: 2.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StandardText(
                        text: "사용 방법",
                        fontSize: 16,
                        color: themeProvider.primaryColor,
                      ),
                      const SizedBox(width: 10), // 텍스트와 아이콘 간격
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            "?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Stack(
                children: [
                  // 이미지
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: themeProvider.primaryColor.withOpacity(0.2), width: 2),
                    ),
                    child: Image.file(
                      File(widget.imagePath),
                      key: _imageKey,
                      width: displayImageWidth,
                      height: displayImageHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // 직사각형
                  if (isRectangleVisible)
                    Positioned(
                      left: rectLeft,
                      top: rectTop,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            rectLeft += details.delta.dx;
                            rectTop += details.delta.dy;
                          });
                        },
                        child: Stack(
                          children: [
                            // 직사각형
                            Container(
                              width: rectWidth,
                              height: rectHeight,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                border: Border.all(color: Colors.green, width: 2),
                              ),
                            ),
                            // 흰색 동그라미 핸들
                            ..._buildCornerHandles(),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 하단 버튼
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
            child: isInitialButtonsVisible
                ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  "건너뛰기",
                  Colors.grey,
                      () {
                    Navigator.of(context).pop([0.0, 0.0, 0.0, 0.0]);
                  },
                ),
                _buildActionButton(
                  "영역 선택",
                  themeProvider.primaryColor,
                      () {
                    setState(() {
                      isInitialButtonsVisible = false;
                      isRectangleVisible = true;
                    });
                  },
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  "취소하기",
                  Colors.grey,
                  _resetToInitialState,
                ),
                _buildActionButton(
                  "완료",
                  themeProvider.primaryColor,
                      () {
                    final rectCoordinates = _convertRectToOriginalCoordinates();
                    log(rectCoordinates.toString());
                    Navigator.of(context).pop(rectCoordinates);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _buildCornerHandles() {
    return [
      // 왼쪽 위
      _buildHandle(
        onDrag: (dx, dy) {
          setState(() {
            rectWidth -= dx;
            rectHeight -= dy;
            rectLeft += dx;
            rectTop += dy;
            _validateDimensions();
          });
        },
        top: -16,
        left: -16,
      ),
      // 오른쪽 위
      _buildHandle(
        onDrag: (dx, dy) {
          setState(() {
            rectWidth += dx;
            rectHeight -= dy;
            rectTop += dy;
            _validateDimensions();
          });
        },
        top: -16,
        right: -16,
      ),
      // 왼쪽 아래
      _buildHandle(
        onDrag: (dx, dy) {
          setState(() {
            rectWidth -= dx;
            rectHeight += dy;
            rectLeft += dx;
            _validateDimensions();
          });
        },
        bottom: -16,
        left: -16,
      ),
      // 오른쪽 아래
      _buildHandle(
        onDrag: (dx, dy) {
          setState(() {
            rectWidth += dx;
            rectHeight += dy;
            _validateDimensions();
          });
        },
        bottom: -16,
        right: -16,
      ),
    ];
  }

  Widget _buildHandle({
    required Function(double dx, double dy) onDrag,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta.dx, details.delta.dy),
        child: Container(
          width: 40, // 확대된 터치 영역
          height: 40,
          alignment: Alignment.center,
          child: Container(
            width: 20, // 실제 표시되는 핸들
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: StandardText(
          text: text,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  /// 이미지 렌더링된 크기와 오프셋을 계산
  Map<String, dynamic> _getRenderedImageSizeAndOffset() {
    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final containerSize = renderBox.size; // 컨테이너 크기
      final aspectRatio = originalImageWidth / originalImageHeight;

      double displayImageWidth;
      double displayImageHeight;
      double offsetX = 0;
      double offsetY = 0;

      // 이미지 비율에 맞춰 렌더링 크기 계산
      if (containerSize.width / containerSize.height > aspectRatio) {
        // 세로 기준으로 맞추기
        displayImageHeight = containerSize.height;
        displayImageWidth = displayImageHeight * aspectRatio;
        offsetX = (containerSize.width - displayImageWidth) / 2;
      } else {
        // 가로 기준으로 맞추기
        displayImageWidth = containerSize.width;
        displayImageHeight = displayImageWidth / aspectRatio;
        offsetY = (containerSize.height - displayImageHeight) / 2;
      }

      return {
        'width': displayImageWidth,
        'height': displayImageHeight,
        'offset': Offset(offsetX, offsetY),
      };
    }
    return {
      'width': 0.0,
      'height': 0.0,
      'offset': Offset.zero,
    };
  }

  List<double> _convertRectToOriginalCoordinates() {
    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final imageInfo = _getRenderedImageSizeAndOffset();
      final displayImageWidth = imageInfo['width'];
      final displayImageHeight = imageInfo['height'];
      final offset = imageInfo['offset'] as Offset;

      // 이미지 내부의 실제 좌표 계산
      double left = ((rectLeft - offset.dx) / displayImageWidth) * originalImageWidth;
      double top = ((rectTop - offset.dy) / displayImageHeight) * originalImageHeight;
      double right = ((rectLeft + rectWidth - offset.dx) / displayImageWidth) * originalImageWidth;
      double bottom = ((rectTop + rectHeight - offset.dy) / displayImageHeight) * originalImageHeight;
      // 음수 좌표는 0으로, 초과 좌표는 경계값으로 제한
      left = left < 0 ? 0 : (left > originalImageWidth ? originalImageWidth : left);
      top = top < 0 ? 0 : (top > originalImageHeight ? originalImageHeight : top);
      right = right < 0 ? 0 : (right > originalImageWidth ? originalImageWidth : right);
      bottom = bottom < 0 ? 0 : (bottom > originalImageHeight ? originalImageHeight : bottom);

      return [left, top, right, bottom];
    }
    return [];
  }

  /// 박스 위치와 크기 검증
  void _validateDimensions() {
    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final imageInfo = _getRenderedImageSizeAndOffset();
      final displayImageWidth = imageInfo['width'];
      final displayImageHeight = imageInfo['height'];
      final offset = imageInfo['offset'] as Offset;

      // 최소 크기 보장
      if (rectWidth < 20) rectWidth = 20;
      if (rectHeight < 20) rectHeight = 20;

      // 화면 밖으로 나가지 않도록 제한
      if (rectLeft < offset.dx) rectLeft = offset.dx;
      if (rectTop < offset.dy) rectTop = offset.dy;

      if (rectLeft + rectWidth > offset.dx + displayImageWidth) {
        rectLeft = offset.dx + displayImageWidth - rectWidth;
      }
      if (rectTop + rectHeight > offset.dy + displayImageHeight) {
        rectTop = offset.dy + displayImageHeight - rectHeight;
      }
    }
  }
}
