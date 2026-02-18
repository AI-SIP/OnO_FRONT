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
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      icon ?? Icons.label,
                      color: themeProvider.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  StandardText(
                    text: label,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: standardTextStyle.copyWith(
                  color: Colors.black87,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: themeProvider.primaryColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  hintText: hintText,
                  hintStyle: standardTextStyle.copyWith(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: maxLines > 1 ? 16 : 14,
                  ),
                ),
                maxLines: maxLines,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
