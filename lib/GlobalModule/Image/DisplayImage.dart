import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class DisplayImage extends StatelessWidget {
  final String? imagePath;
  final String defaultImagePath = 'assets/no_image.png';
  final BoxFit fit;

  const DisplayImage(
      {super.key, required this.imagePath, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return imagePath == null || imagePath!.isEmpty
        ? Image.asset(defaultImagePath, fit: fit)
        : CachedNetworkImage(
            imageUrl: imagePath!,
            fit: fit,
            //placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) =>
                Image.asset(defaultImagePath, fit: fit),
          );
  }
}
