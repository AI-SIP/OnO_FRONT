import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../Theme/StandardText.dart';
import '../../Theme/ThemeHandler.dart';

class ImageCoordinatePickerHandler {
  Future<Map<String, dynamic>?> showCoordinatePicker(
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
  List<Offset> selectedCoordinates = [];
  bool isAddingCoordinates = false; // 좌표 추가 활성화 여부

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: StandardText(
          text: '제거할 필기를 모두 눌러주세요!',
          fontSize: 20,
          color: themeProvider.primaryColor,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTapUp: (details) {
                if (isAddingCoordinates) {
                  setState(() {
                    selectedCoordinates.add(details.localPosition);
                  });
                }
              },
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: themeProvider.primaryColor, width: 2), // 테두리 설정
                      ),
                      child: Image.file(
                        File(widget.imagePath),
                        height: screenHeight * 0.7,
                        width: screenWidth * 0.9,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // 선택된 좌표에 빨간 도넛형 원 표시
                  ...selectedCoordinates.map((coord) => Positioned(
                    left: coord.dx - 10,
                    top: coord.dy - 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red, width: 2),
                        color: Colors.transparent,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
            child: isAddingCoordinates
                ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  width: screenWidth * 0.3,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedCoordinates.clear();
                        isAddingCoordinates = false;
                      });
                    },
                    style: _buildButtonStyle(Colors.grey[500]!),
                    child: const StandardText(
                      text: '취소하기',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  width: screenWidth * 0.3,
                  child: ElevatedButton(
                    onPressed: () {
                      // 좌표 리스트를 x, y로 매핑하여 반환
                      final coordinates = selectedCoordinates
                          .map((coord) => {"x": coord.dx, "y": coord.dy})
                          .toList();
                      Navigator.of(context).pop({
                        'coordinates': coordinates,
                      });
                    },
                    style: _buildButtonStyle(themeProvider.primaryColor),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const StandardText(
                          text: '선택 완료',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: StandardText(
                            text: selectedCoordinates.length.toString(),
                            fontSize: 12,
                            color: themeProvider.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
                : SizedBox(
              width: screenWidth * 0.7,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    isAddingCoordinates = true;
                  });
                },
                style: _buildButtonStyle(themeProvider.primaryColor),
                child: const StandardText(
                  text: '제거할 필기 선택',
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
        ],
      ),
    );
  }

  ButtonStyle _buildButtonStyle(Color buttonColor) {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 10),
      backgroundColor: buttonColor,
      side: BorderSide(color: buttonColor, width: 2.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
    );
  }
}