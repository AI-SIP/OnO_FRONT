import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class DisplayImage extends StatelessWidget {
  final String? imagePath;
  final String defaultImagePath = 'assets/no_image.png';
  final BoxFit fit;

  const DisplayImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10), // 테두리 radius 설정
      child: imagePath == null || imagePath!.isEmpty
          ? Image.asset(defaultImagePath, fit: fit)
          : CachedNetworkImage(
        imageUrl: imagePath!,
        fit: fit,
        errorWidget: (context, url, error) =>
            Image.asset(defaultImagePath, fit: fit),
      ),
    );
  }
}
