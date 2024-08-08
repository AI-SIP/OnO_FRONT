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
      content: Column(
        mainAxisSize: MainAxisSize.min, // Ensures the dialog fits content size
        children: [
          const SizedBox(height: 20), // Add vertical spacing
          SizedBox(
            height: 300, // Adjusted for smaller circles
            width: 300,  // Adjusted for smaller circles
            child: GridView.count(
              crossAxisCount: 4, // Number of columns
              crossAxisSpacing: 12.0, // Adjusted spacing
              mainAxisSpacing: 12.0,  // Adjusted spacing
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
        ],
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
        radius: 20, // Reduced radius for smaller circles
        child: _selectedColor == color
            ? const Icon(Icons.check, color: Colors.white)
            : null,
      ),
    );
  }
}