import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../Theme/StandardText.dart';
import '../../Theme/ThemeHandler.dart';

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
  List<List<double>> selectedCoordinates = [];
  List<Offset> displayCoordinates = []; // 화면에 표시할 실제 좌표
  bool isAddingCoordinates = false;

  double originalImageWidth = 1;
  double originalImageHeight = 1;
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _getImageDimensions();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  List<double> _calculateBoundingBox() {
    if (selectedCoordinates.isEmpty) return [];

    // 최소/최대 x, y 값 계산
    final minX = selectedCoordinates.map((coord) => coord[0]).reduce((a, b) => a < b ? a : b);
    final minY = selectedCoordinates.map((coord) => coord[1]).reduce((a, b) => a < b ? a : b);
    final maxX = selectedCoordinates.map((coord) => coord[0]).reduce((a, b) => a > b ? a : b);
    final maxY = selectedCoordinates.map((coord) => coord[1]).reduce((a, b) => a > b ? a : b);

    return [minX, minY, maxX, maxY];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    double screenWidth = MediaQuery.of(context).size.width;

    // 화면에 표시할 이미지 크기 설정
    final double displayImageWidth = screenWidth * 0.9;
    final double displayImageHeight = displayImageWidth * originalImageHeight / originalImageWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: StandardText(
          text: '제거할 필기를 모두 눌러주세요!',
          fontSize: 20,
          color: themeProvider.primaryColor,
          textAlign: TextAlign.center,
        ),
      ),
      body: Column(
        children: [
          StandardText(text: '(문제 위에 적힌 필기는 선택하지 않아도 괜찮아요!)', color: themeProvider.primaryColor, fontSize: 15,),
          const SizedBox(height: 10,),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTapUp: (details) {
                  if (isAddingCoordinates) {
                    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      final localPosition = renderBox.globalToLocal(details.globalPosition);

                      // 이미지 컨테이너 내에서의 위치로 변환
                      if (localPosition.dx >= 0 &&
                          localPosition.dx <= displayImageWidth &&
                          localPosition.dy >= 0 &&
                          localPosition.dy <= displayImageHeight) {
                        setState(() {
                          // 원본 이미지 좌표계에서의 절대 좌표 계산
                          final double relativeX = localPosition.dx / displayImageWidth;
                          final double relativeY = localPosition.dy / displayImageHeight;
                          final double absoluteX = relativeX * originalImageWidth;
                          final double absoluteY = relativeY * originalImageHeight;

                          selectedCoordinates.add([absoluteX, absoluteY]);

                          // 이미지의 좌상단을 기준으로 한 화면 좌표계 위치
                          displayCoordinates.add(localPosition);

                          log("Selected Absolute Coordinate: [x=${absoluteX.toStringAsFixed(2)}, y=${absoluteY.toStringAsFixed(2)}]");
                        });
                      }
                    }
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: themeProvider.primaryColor, width: 2),
                      ),
                      child: Image.file(
                        File(widget.imagePath),
                        key: _imageKey,
                        width: displayImageWidth,
                        height: displayImageHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // 터치한 부분에 빨간 원 표시 (상대적 좌표 이용)
                    ...displayCoordinates.map((coord) => Positioned(
                      left: coord.dx - 7, // 원의 반지름(10에서 7로 줄임)
                      top: coord.dy - 7, // 원의 반지름(10에서 7로 줄임)
                      child: Container(
                        width: 14, // 원의 지름(20에서 14로 줄임)
                        height: 14, // 원의 지름(20에서 14로 줄임)
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 3), // 두께 증가(2에서 3으로)
                          color: Colors.transparent,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
            child: isAddingCoordinates
                ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton('취소하기', Colors.grey[500]!, () {
                  setState(() {
                    selectedCoordinates.clear();
                    displayCoordinates.clear();
                    isAddingCoordinates = false;
                  });
                }),
                _buildActionButton('선택 완료', themeProvider.primaryColor, () {
                  final boundingBox = _calculateBoundingBox();
                  Navigator.of(context).pop(boundingBox);
                }, selectedCoordinates.length),
              ],
            )
                : _buildActionButton('제거할 필기 선택', themeProvider.primaryColor, () {
              setState(() {
                isAddingCoordinates = true;
              });
            }),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed, [int? count]) {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          side: BorderSide(color: color, width: 2.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StandardText(
              text: text,
              fontSize: 14,
              color: Colors.white,
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}