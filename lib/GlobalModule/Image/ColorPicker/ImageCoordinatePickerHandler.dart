import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Text/StandardText.dart';
import '../../Theme/ThemeHandler.dart';
import 'ImageCoordinateGuideDialog.dart';

class ImageCoordinatePickerHandler {
  Future<List<List<double>>?> showCoordinatePicker(
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
  final List<Rect> boxes = [];
  final List<List<Rect>> history = []; // 상태를 저장하는 스택
  final List<Color> boxColors = [
    Colors.red.withOpacity(0.3),
    Colors.blue.withOpacity(0.3),
    Colors.green.withOpacity(0.3),
    Colors.yellow.withOpacity(0.3),
    Colors.orange.withOpacity(0.3),
    Colors.purple.withOpacity(0.3),
    Colors.cyan.withOpacity(0.3),
    Colors.brown.withOpacity(0.3),
    Colors.pink.withOpacity(0.3),
    Colors.lime.withOpacity(0.3),
  ];

  final GlobalKey _imageKey = GlobalKey();
  double originalImageWidth = 1;
  double originalImageHeight = 1;

  @override
  void initState() {
    super.initState();
    _getImageDimensions();
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

  void _addBox() {
    _saveToHistory(); // 현재 상태 저장
    setState(() {
      boxes.add(const Rect.fromLTWH(100, 100, 150, 150));
    });
  }

  void _undo() {
    if (history.isNotEmpty) {
      setState(() {
        boxes
          ..clear()
          ..addAll(history.removeLast()); // 가장 최근 상태로 복원
      });
    }
  }

  void _saveToHistory() {
    history.add(List.from(boxes)); // 현재 상태를 복사해 스택에 저장
  }

  List<List<double>> _getBoxCoordinates() {
    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final containerSize = renderBox.size; // 컨테이너 크기

      // 이미지 비율
      final double aspectRatio = originalImageWidth / originalImageHeight;

      double displayImageWidth, displayImageHeight;
      double offsetX = 0, offsetY = 0;

      // 이미지 렌더링 크기 및 여백 계산
      if (containerSize.width / containerSize.height > aspectRatio) {
        // 세로 기준 맞춤: 양옆에 여백이 생김
        displayImageHeight = containerSize.height;
        displayImageWidth = displayImageHeight * aspectRatio;
        offsetX = (containerSize.width - displayImageWidth) / 2;
      } else {
        // 가로 기준 맞춤: 위아래 여백이 생김
        displayImageWidth = containerSize.width;
        displayImageHeight = displayImageWidth / aspectRatio;
        offsetY = (containerSize.height - displayImageHeight) / 2;
      }

      // 이미지 좌표로 변환
      final double widthRatio = originalImageWidth / displayImageWidth;
      final double heightRatio = originalImageHeight / displayImageHeight;

      return boxes.map((box) {
        // 박스 좌표에서 이미지 여백을 뺌
        final double adjustedLeft = (box.left - offsetX).clamp(0, displayImageWidth);
        final double adjustedTop = (box.top - offsetY).clamp(0, displayImageHeight);
        final double adjustedRight = (box.right - offsetX).clamp(0, displayImageWidth);
        final double adjustedBottom = (box.bottom - offsetY).clamp(0, displayImageHeight);

        // 원본 이미지 좌표로 변환
        return [
          adjustedLeft * widthRatio,
          adjustedTop * heightRatio,
          adjustedRight * widthRatio,
          adjustedBottom * heightRatio,
        ];
      }).toList();
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: StandardText(
          text: '문제와 겹치지 않는 필기들을 박스로 선택해주세요!',
          fontSize: 13,
          color: themeProvider.primaryColor,
          //textAlign: TextAlign.center,
        ),
      ),
      body: Column(
        children: [
          // 사용 방법 버튼
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: screenWidth * 0.45,
                child: OutlinedButton(
                  onPressed: () {
                    ImageCoordinateGuideDialog.show(context);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(
                        color: themeProvider.primaryColor, width: 2.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
                      border: Border.all(
                          color: themeProvider.primaryColor.withOpacity(0.2),
                          width: 2),
                    ),
                    child: Image.file(
                      File(widget.imagePath),
                      key: _imageKey,
                      width: screenWidth * 0.9,
                      height: screenWidth *
                          0.9 *
                          originalImageHeight /
                          originalImageWidth,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // 박스들
                  for (int i = 0; i < boxes.length; i++)
                    Positioned.fromRect(
                      rect: boxes[i],
                      child: GestureDetector(
                        onPanStart: (details) {
                          _saveToHistory(); // 이동 시작 시 기록
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            boxes[i] = boxes[i]
                                .translate(details.delta.dx, details.delta.dy);
                          });
                        },
                        onPanEnd: (details) {
                          _saveToHistory(); // 이동 종료 시 기록
                        },
                        child: Stack(
                          children: [
                            // 박스 본체
                            Container(
                              decoration: BoxDecoration(
                                color: boxColors[i % boxColors.length],
                              ),
                            ),
                            // 핸들
                            ..._buildCornerHandles(i),
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
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOutlinedActionButton(
                  "되돌리기",
                  Colors.grey,
                  _undo,
                ),
                _buildOutlinedActionButton(
                  "박스 추가",
                  themeProvider.primaryColor,
                  _addBox,
                ),
                _buildActionButton(
                  "완료",
                  themeProvider.primaryColor,
                  Colors.white,
                  () {
                    final rectCoordinates = _getBoxCoordinates();
                    log(rectCoordinates.toString());
                    Navigator.of(context).pop(rectCoordinates);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerHandles(int index) {
    final box = boxes[index]; // 현재 박스 정보
    return [
      _buildHandle(
        box: box,
        alignment: Alignment.topLeft,
        onDrag: (dx, dy) {
          setState(() {
            boxes[index] = Rect.fromLTRB(
              boxes[index].left + dx,
              boxes[index].top + dy,
              boxes[index].right,
              boxes[index].bottom,
            );
          });
        },
      ),
      _buildHandle(
        box: box,
        alignment: Alignment.topRight,
        onDrag: (dx, dy) {
          setState(() {
            boxes[index] = Rect.fromLTRB(
              boxes[index].left,
              boxes[index].top + dy,
              boxes[index].right + dx,
              boxes[index].bottom,
            );
          });
        },
      ),
      _buildHandle(
        box: box,
        alignment: Alignment.bottomLeft,
        onDrag: (dx, dy) {
          setState(() {
            boxes[index] = Rect.fromLTRB(
              boxes[index].left + dx,
              boxes[index].top,
              boxes[index].right,
              boxes[index].bottom + dy,
            );
          });
        },
      ),
      _buildHandle(
        box: box,
        alignment: Alignment.bottomRight,
        onDrag: (dx, dy) {
          setState(() {
            boxes[index] = Rect.fromLTRB(
              boxes[index].left,
              boxes[index].top,
              boxes[index].right + dx,
              boxes[index].bottom + dy,
            );
          });
        },
      ),
    ];
  }

  Widget _buildHandle({
    required Rect box, // 박스의 크기와 위치 정보
    required Alignment alignment,
    required void Function(double dx, double dy) onDrag,
  }) {
    const double handleSize = 8; // 실제로 보이는 원 크기
    const double handleSizeRatio = 0.2; // 터치 영역 크기의 박스 크기 비율
    const double minTouchArea = 20; // 최소 터치 영역 크기
    const double maxTouchArea = 50; // 최대 터치 영역 크기

    // 박스 크기를 기준으로 터치 영역 크기 계산
    final double touchAreaWidth = (box.width * handleSizeRatio).clamp(minTouchArea, maxTouchArea);
    final double touchAreaHeight = (box.height * handleSizeRatio).clamp(minTouchArea, maxTouchArea);

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanUpdate: (details) {
          onDrag(details.delta.dx, details.delta.dy);
        },
        child: Container(
          width: touchAreaWidth,
          height: touchAreaHeight,
          color: Colors.transparent, // 터치 영역을 시각적으로 표시하지 않음
          alignment: Alignment.center,
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 0.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildActionButton(String text, Color backgroundColor, Color textColor,
    VoidCallback onPressed) {
  return SizedBox(
    width: 90,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      ),
      child: StandardText(
        text: text,
        fontSize: 15,
        color: textColor,
      ),
    ),
  );
}

Widget _buildOutlinedActionButton(
    String text, Color borderColor, VoidCallback onPressed) {
  return SizedBox(
    width: 90,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white, // 흰색 배경
        side: BorderSide(color: borderColor, width: 2), // 테두리 색상
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
      ),
      child: StandardText(
        text: text,
        fontSize: 15,
        color: borderColor, // 글자색을 테두리 색과 동일하게
      ),
    ),
  );
}
