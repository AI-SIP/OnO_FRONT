import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData? icon;
  final TextEditingController controller;
  final int maxLines;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.icon,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final standardTextStyle = const StandardText(text: '').getTextStyle();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon ?? Icons.label, color: themeProvider.primaryColor),
            const SizedBox(width: 6),
            StandardText(
                text: label, fontSize: 16, color: themeProvider.primaryColor),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          style: standardTextStyle.copyWith(
              color: themeProvider.primaryColor, fontSize: 16),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: themeProvider.primaryColor, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: themeProvider.primaryColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: themeProvider.primaryColor, width: 1.5),
            ),
            fillColor: Colors.white,
            filled: true,
            hintText: hintText,
            hintStyle: standardTextStyle.copyWith(
              color: themeProvider.desaturateColor,
              fontSize: 12,
            ),
          ),
          maxLines: maxLines,
        ),
      ],
    );
  }
}
