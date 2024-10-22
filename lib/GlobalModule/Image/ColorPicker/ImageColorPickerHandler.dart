import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Theme/StandardText.dart';
import '../../Theme/ThemeHandler.dart';
import 'PixelPicker.dart';

class ImageColorPickerHandler {
  Future<Map<String, dynamic>> showColorPicker(BuildContext context, String imagePath) async {

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ColorPickerScreen(imagePath: imagePath),
      ),
    );

    return result ?? {'colors': [], 'intensity': 1};
  }
}

class ColorPickerScreen extends StatefulWidget {
  final String imagePath;

  const ColorPickerScreen({required this.imagePath, super.key});

  @override
  _ColorPickerScreenState createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  List<Color?> selectedColors = [null, null, null];
  int? activeCircleIndex;
  int intensity = 1;
  final GlobalKey<ColorPickerState> colorPickerKey = GlobalKey();  // ColorPickerState에 접근하기 위한 Key

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StandardText(
              text: '하단의 + 버튼을 누른 뒤, 펜을 움직여',
              fontSize: 16,
              color: themeProvider.primaryColor,
            ),
            StandardText(
              text: '지우고 싶은 색상을 선택하세요',
              fontSize: 16,
              color: themeProvider.primaryColor,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: screenHeight * 0.02), // 상단에 여백 추가
          Expanded(
            child: ColorPicker(
              key: colorPickerKey,  // ColorPicker에 Key 할당
              showMarker: false, // 마커를 표시하지 않음
              onChanged: (response) {
                if (activeCircleIndex != null) {
                  setState(() {
                    selectedColors[activeCircleIndex!] = response.selectionColor;
                  });
                }
              },
              child: Image.file(
                File(widget.imagePath),  // Image.asset() 대신 Image.file() 사용
                height: screenHeight * 0.5, // 이미지의 높이를 더 크게 설정
                width: screenWidth * 0.8, // 이미지의 너비를 화면 크기에 맞춤
                fit: BoxFit.contain, // 이미지를 화면에 맞추어 표시
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
            child: Column(
              children: [
                const StandardText(
                  text: '필기 제거 옵션', // 슬라이더 위의 텍스트
                  fontSize: 18,
                  color: Colors.black,
                ),
                SizedBox(height: screenHeight * 0.005),
                StandardText(
                  text: getDescription(intensity),
                  fontSize: 14,
                  color: ThemeHandler.desaturatenColor(Colors.black),
                ),
                Slider(
                  value: intensity.toDouble(),
                  min: 0,
                  max: 2,
                  divisions: 2,
                  onChanged: (double value) {
                    setState(() {
                      intensity = value.toInt();
                    });
                  },
                  activeColor: themeProvider.primaryColor,
                  inactiveColor: Colors.grey,
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,  // 글씨와 슬라이더 값 맞추기
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: StandardText(
                          text: '약하게',
                          color: Colors.black,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: StandardText(
                          text: '중간',
                          color: Colors.black,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: StandardText(
                          text: '강하게',
                          color: Colors.black,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      activeCircleIndex = index;
                    });
                    // 펜을 중앙에 표시하고 해당 위치의 색상을 추출
                    colorPickerKey.currentState?.showPen();
                  },
                  child: CircleAvatar(
                    radius: screenHeight * 0.025,
                    backgroundColor: selectedColors[index] ?? themeProvider.desaturateColor,
                    child: selectedColors[index] == null
                        ? const Icon(Icons.add, color: Colors.white)
                        : null,
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          ElevatedButton(
            onPressed: () {
              // selectedColors 리스트를 RGB 값이 포함된 Map 형태로 변환
              List<Map<String, int>?> colorMaps = selectedColors.map((color) {
                if (color == null) return null;
                return {
                  'red': color.red,
                  'green': color.green,
                  'blue': color.blue,
                };
              }).toList();

              // 선택한 색상 개수 GA 로그로 수집
              int selectedColorCount = colorMaps.where((color) => color != null).length;

              FirebaseAnalytics.instance.logEvent(
                name: 'color_picker_counts_$selectedColorCount',
                parameters: {
                  'selected_color_count': selectedColorCount,
                },
              );

              Navigator.of(context).pop({
                'colors': colorMaps,
                'intensity' : intensity,
              }); // 변환된 리스트 반환
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryColor, // 버튼 배경색 변경
              //elevation: 5, // 그림자 깊이 설정 (옵션)

            ),
            child: const StandardText(
              text: '완료',
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
        ],
      ),
    );
  }

  String getDescription(int intensity) {
    switch (intensity) {
      case 0:
        return '샤프 필기 제거에 특화된 옵션입니다.';
      case 1:
        return '샤프와 색상펜을 골고루 제거합니다.';
      case 2:
        return '색상이 있는 펜 제거에 특화된 옵션입니다.';
      default:
        return '';
    }
  }
}