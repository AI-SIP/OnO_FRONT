import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/DecorateText.dart';
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

  @override
  Widget build(BuildContext context) {

    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      appBar: AppBar(
        title:  DecorateText(text: '지우고 싶은 필기 색상을 눌러주세요!!', fontSize: 24, color: themeProvider.primaryColor),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40), // 상단에 여백 추가
          Expanded(
            child: ColorPicker(
              showMarker: false, // 마커를 표시하지 않음
              onChanged: (response) {
                if (activeCircleIndex != null) {
                  setState(() {
                    selectedColors[activeCircleIndex!] = response.selectionColor;
                  });
                }
              },
              child: Image.asset(
                widget.imagePath,
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
                },
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: selectedColors[index] ?? Colors.grey,
                  child: selectedColors[index] == null
                      ? const Icon(Icons.add, color: Colors.white) // 선택되지 않은 경우 + 아이콘 표시
                      : null, // 선택된 경우 아이콘 제거
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

              Navigator.of(context).pop(colorMaps); // 변환된 리스트 반환
            },
            child: DecorateText(text: '완료', fontSize: 16, color: themeProvider.primaryColor,),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}