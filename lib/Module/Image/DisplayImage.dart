import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../Design/AppRadius.dart';

class DisplayImage extends StatelessWidget {
  final String? imagePath;
  final String defaultImagePath = 'assets/Icon/noImage.svg';
  final BoxFit fit;

  /// 이미지 둘레 여백. 작은 썸네일은 0 을 넘겨 칸을 다 쓴다.
  final EdgeInsetsGeometry padding;

  /// 잘라 낼 때 어느 쪽을 남길지. 문제 사진은 위쪽에 문제가 시작한다.
  final Alignment alignment;

  const DisplayImage({
    super.key,
    this.imagePath,
    this.fit = BoxFit.cover,
    this.padding = const EdgeInsets.all(10.0),
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.medium), // 테두리 radius 설정
      child: Padding(
        padding: padding,
        child: imagePath == null || imagePath!.isEmpty
            ? Center(
                child: SvgPicture.asset(
                  defaultImagePath,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  width: 200, // 원하는 크기 설정
                  height: 200,
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
                      alignment: alignment,
                    ),
                    //borderRadius: BorderRadius.circular(AppRadius.medium), // 이미지 둥근 모서리
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                  child: SvgPicture.asset(
                    defaultImagePath,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    width: 200, // 에러 시 이미지 크기 설정
                    height: 200,
                  ),
                ),
              ),
      ),
    );
  }
}
