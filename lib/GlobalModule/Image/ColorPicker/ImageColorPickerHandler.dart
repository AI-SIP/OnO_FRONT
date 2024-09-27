import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/HandWriteText.dart';
import 'package:provider/provider.dart';

import '../../Theme/ThemeHandler.dart';
import 'PixelPicker.dart';

class ImageColorPickerHandler {
  Future<List<Map<String, int>?>> showColorPicker(BuildContext context, String imagePath) async {

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ColorPickerScreen(imagePath: imagePath),
      ),
    );

    return result ?? [];
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
  final GlobalKey<ColorPickerState> colorPickerKey = GlobalKey();  // ColorPickerState에 접근하기 위한 Key

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HandWriteText(
              text: '하단의 + 버튼을 누른 뒤,',
              fontSize: 20,
              color: themeProvider.primaryColor,
            ),
            HandWriteText(
              text: '펜을 움직여 지우고 싶은 색상을 선택하세요!!',
              fontSize: 20,
              color: themeProvider.primaryColor,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40), // 상단에 여백 추가
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
                height: MediaQuery.of(context).size.height * 0.6, // 이미지의 높이를 더 크게 설정
                width: MediaQuery.of(context).size.width, // 이미지의 너비를 화면 크기에 맞춤
                fit: BoxFit.contain, // 이미지를 화면에 맞추어 표시
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                  radius: 30,
                  backgroundColor: selectedColors[index] ?? themeProvider.primaryColor,
                  child: selectedColors[index] == null
                      ? const Icon(Icons.add, color: Colors.white)
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
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
                name: 'color_picker_count',
                parameters: {
                  'selected_color_count': selectedColorCount,
                },
              );

              Navigator.of(context).pop(colorMaps); // 변환된 리스트 반환
            },
            child: HandWriteText(
              text: '완료',
              fontSize: 16,
              color: themeProvider.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}