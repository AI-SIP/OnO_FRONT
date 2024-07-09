import 'package:flutter/material.dart';

class DisplayImage extends StatelessWidget {
  final String? imagePath;
  final String defaultImagePath;

  const DisplayImage({
    Key? key,
    required this.imagePath,
    required this.defaultImagePath
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return imagePath == null || imagePath!.isEmpty
        ? Image.asset(defaultImagePath, fit: BoxFit.cover)
        : Image.network(imagePath!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
      // 네트워크 오류가 발생했을 때 기본 이미지를 보여줍니다.
      return Image.asset(defaultImagePath, fit: BoxFit.cover);
    });
  }
}