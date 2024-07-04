import 'dart:io';
import 'package:flutter/material.dart';

class DisplayImage extends StatelessWidget {
  final String? imagePath;
  final String defaultImagePath;

  const DisplayImage(
      {Key? key, required this.imagePath, required this.defaultImagePath})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imagePath == null ||
        imagePath!.isEmpty ||
        !File(imagePath!).existsSync()) {
      return Image.asset(defaultImagePath, fit: BoxFit.cover);
    } else {
      return Image.file(File(imagePath!), fit: BoxFit.cover);
    }
  }
}