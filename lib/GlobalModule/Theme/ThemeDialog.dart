import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'StandardText.dart';
import 'ThemeHandler.dart';

class ThemeDialog extends StatefulWidget {
  @override
  _ThemeDialogState createState() => _ThemeDialogState();
}

class _ThemeDialogState extends State<ThemeDialog> {
  Color? _selectedColor;
  String? _selectedColorName;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return AlertDialog(
      backgroundColor: Colors.white,
      title: const StandardText(
        text: '테마 색상 선택',
        fontSize: 20,
        color: Colors.black,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ensures the dialog fits content size
          children: [
            const SizedBox(height: 20), // Add vertical spacing
            SizedBox(
              height: 450, // Adjusted for smaller circles
              width: 280, // Adjusted for smaller circles
              child: GridView.count(
                crossAxisCount: 4, // Number of columns
                crossAxisSpacing: 8.0, // Adjusted spacing
                mainAxisSpacing: 8.0, // Adjusted spacing
                children: [
                  _buildColorCircle(Colors.pink[200]!, '연핑크'),
                  _buildColorCircle(Colors.pink[400]!, '진핑크'),
                  _buildColorCircle(Colors.purple[300]!, '라일락'),
                  _buildColorCircle(Colors.purple[700]!, '보라색'),
                  _buildColorCircle(Colors.red[500]!, '빨간색'),
                  _buildColorCircle(Colors.yellow[900]!, '황금색'),
                  _buildColorCircle(Colors.orange[300]!, '오렌지색'),
                  _buildColorCircle(Colors.yellow[600]!, '노란색'),
                  _buildColorCircle(Colors.lightGreen, '라이트그린'),
                  _buildColorCircle(Colors.green[500]!, '초록색'),
                  _buildColorCircle(Colors.green[700]!, '다크그린'),
                  _buildColorCircle(Colors.green[900]!, '딥그린'),
                  _buildColorCircle(Colors.cyan, '시안'),
                  _buildColorCircle(Colors.blue[700]!, '블루'),
                  _buildColorCircle(Colors.indigo, '인디고'),
                  _buildColorCircle(Colors.indigo[900]!, '딥인디고'),
                  _buildColorCircle(const Color(0xFFC8B68A), '베이지'),
                  _buildColorCircle(const Color(0xFF7A6748), '브론즈'),
                  _buildColorCircle(Colors.brown[500]!, '브라운'),
                  _buildColorCircle(Colors.brown[800]!, '다크브라운'),
                  _buildColorCircle(Colors.grey[400]!, '라이트그레이'),
                  _buildColorCircle(Colors.grey[600]!, '그레이'),
                  _buildColorCircle(Colors.grey[800]!, '다크그레이'),
                  _buildColorCircle(Colors.black, '블랙'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const StandardText(
            text: '취소',
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        TextButton(
          onPressed: () {
            if (_selectedColor != null) {
              // Change the PrimaryColor to the selected color
              final darkerColor = _darken(_selectedColor!, 0.1);
              themeProvider.changePrimaryColor(darkerColor, _selectedColorName!);

              Navigator.of(context).pop();
            }
          },
          child: StandardText(
            text: '확인',
            fontSize: 16,
            color: themeProvider.primaryColor,
          ),
        ),
      ],
    );
  }

  Color _darken(Color color, [double amount = .1]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Widget _buildColorCircle(Color color, String colorName) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
          _selectedColorName = colorName; // 선택한 색상의 이름을 설정
        });
      },
      child: CircleAvatar(
        backgroundColor: color,
        radius: 16, // Reduced radius for smaller circles
        child: _selectedColor == color
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      ),
    );
  }
}
