import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/StandardText.dart';
import 'package:provider/provider.dart';

import '../Theme/ThemeHandler.dart';

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

    final themeProvider = Provider.of<ThemeHandler>(context);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(10), // 테두리 radius 설정
      child: imagePath == null || imagePath!.isEmpty
          ? Container(
        color: themeProvider.primaryColor.withOpacity(0.03), // 배경색 설정 (선택 사항)
        alignment: Alignment.center,
        child: StandardText(text: '이미지가 없습니다!', color: themeProvider.primaryColor,),
      )
          : CachedNetworkImage(
        imageUrl: imagePath!,
        fit: fit,
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: Text(
            '이미지가 없습니다!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
