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
      child: Padding(
        padding: const EdgeInsets.all(10.0), // 원하는 padding 값
        child: imagePath == null || imagePath!.isEmpty
            ? Container(
                alignment: Alignment.center,
                child: StandardText(
                  text: '이미지가 없습니다!',
                  color: themeProvider.primaryColor,
                ),
              )
            : CachedNetworkImage(
                imageUrl: imagePath!,
                fit: fit,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: imageProvider,
                      fit: fit,
                    ),
                    //borderRadius: BorderRadius.circular(10), // 이미지 둥근 모서리
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  alignment: Alignment.center,
                  child: StandardText(
                    text: '이미지가 없습니다!',
                    color: themeProvider.primaryColor,
                  ),
                ),
              ),
      ),
    );
  }
}
