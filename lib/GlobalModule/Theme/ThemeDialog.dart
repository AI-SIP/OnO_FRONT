import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'DecorateText.dart';
import 'ThemeHandler.dart';

class ThemeDialog extends StatefulWidget {
  @override
  _ThemeDialogState createState() => _ThemeDialogState();
}

class _ThemeDialogState extends State<ThemeDialog> {
  Color? _selectedColor;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return AlertDialog(
      title: DecorateText(
        text: '테마 색상 선택',
        fontSize: 30,
        color: themeProvider.primaryColor,
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
                  _buildColorCircle(Colors.pink[200]!),
                  _buildColorCircle(Colors.pink[400]!),
                  _buildColorCircle(Colors.purple[300]!),
                  _buildColorCircle(Colors.purple[700]!),
                  _buildColorCircle(Colors.red[500]!),
                  _buildColorCircle(Colors.yellow[900]!),
                  _buildColorCircle(Colors.orange[300]!),
                  _buildColorCircle(Colors.yellow[600]!),
                  _buildColorCircle(Colors.lightGreen),
                  _buildColorCircle(Colors.green[500]!),
                  _buildColorCircle(Colors.green[700]!),
                  _buildColorCircle(Colors.green[900]!),
                  _buildColorCircle(Colors.cyan),
                  _buildColorCircle(Colors.blue[700]!),
                  _buildColorCircle(Colors.indigo),
                  _buildColorCircle(Colors.indigo[900]!),
                  _buildColorCircle(const Color(0xFFC8B68A)),
                  _buildColorCircle(const Color(0xFF7A6748)),
                  _buildColorCircle(Colors.brown[500]!),
                  _buildColorCircle(Colors.brown[800]!),
                  _buildColorCircle(Colors.grey[400]!),
                  _buildColorCircle(Colors.grey[600]!),
                  _buildColorCircle(Colors.grey[800]!),
                  _buildColorCircle(Colors.black),
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
          child: const DecorateText(
            text: '취소',
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        TextButton(
          onPressed: () {
            if (_selectedColor != null) {
              // Change the PrimaryColor to the selected color
              final darkerColor = _darken(_selectedColor!, 0.1);
              themeProvider.changePrimaryColor(darkerColor);

              Navigator.of(context).pop();
            }
          },
          child: DecorateText(
            text: '확인',
            fontSize: 24,
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

  Widget _buildColorCircle(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
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
