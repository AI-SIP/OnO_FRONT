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
        fontSize: 24,
        color: themeProvider.primaryColor,
      ),
      content: SizedBox(
        height: 320, // 80 (item size) * 4 (rows) = 320
        width: 320,  // 80 (item size) * 4 (columns) = 320
        child: GridView.count(
          crossAxisCount: 4, // Number of columns
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          children: [
            _buildColorCircle(Colors.pinkAccent),
            _buildColorCircle(Colors.purpleAccent),
            _buildColorCircle(Colors.purple),
            _buildColorCircle(Colors.deepPurple),
            _buildColorCircle(Colors.redAccent),
            _buildColorCircle(Colors.orangeAccent),
            _buildColorCircle(Colors.amberAccent),
            _buildColorCircle(Colors.lightGreen),
            _buildColorCircle(Colors.green),
            _buildColorCircle(Colors.greenAccent),
            _buildColorCircle(Colors.cyan),
            _buildColorCircle(Colors.blueAccent),
            _buildColorCircle(Colors.indigo),
            _buildColorCircle(Colors.brown),
            _buildColorCircle(Colors.grey),
            _buildColorCircle(Colors.black),
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
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        TextButton(
          onPressed: () {
            if (_selectedColor != null) {
              // Change the PrimaryColor to the selected color
              themeProvider.changePrimaryColor(_selectedColor!);

              Navigator.of(context).pop();
            }
          },
          child: DecorateText(
            text: '확인',
            fontSize: 20,
            color: themeProvider.primaryColor,
          ),
        ),
      ],
    );
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
        radius: 30,
        child: _selectedColor == color
            ? const Icon(Icons.check, color: Colors.white)
            : null,
      ),
    );
  }
}