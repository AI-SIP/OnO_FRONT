import 'package:flutter/cupertino.dart';

import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import 'ImageGallerySection.dart';

Widget buildImageSection(
    BuildContext ctx, List<String> urls, String label, ThemeHandler theme) {
  if (urls.isEmpty) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Center(
          child: StandardText(
              text: '$label가 없습니다.',
              fontSize: 14,
              color: theme.primaryColor.withOpacity(0.5))),
    );
  }
  return ImageGallerySection(
    imageUrls: urls,
    label: label,
    color: theme.primaryColor,
    themeProvider: theme,
  );
}
