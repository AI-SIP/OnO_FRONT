import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 치장 그림 한 장이다.
///
/// **확장자로 그리는 방법을 가른다.** 개구리에 겹치는 파츠는 512 비트맵
/// (`assets/Cosmetic/*.png`)이지만 프로필 테두리는 벡터(`assets/ProfileFrame/*.svg`)
/// 다. 테두리는 32픽셀 아바타부터 큰 미리보기까지 크기가 널뛰는 자리에 쓰여서,
/// 비트맵으로 두면 어느 한쪽이 뭉갠다.
///
/// `Image.asset` 은 SVG 를 못 읽는다. 그림 한 장의 종류를 화면마다 따져 묻는
/// 대신 여기 한 군데에서 가른다. 서버가 언젠가 SVG 를 더 내려줘도 이 파일만
/// 알면 된다.
///
/// 그림을 못 읽으면 그 자리를 **비운다.** 그림 한 장 때문에 개구리가 통째로
/// 안 그려지거나 격자가 깨지면 안 된다.
class CosmeticArt extends StatelessWidget {
  /// 그림의 위치. `http` 로 시작하면 네트워크, 아니면 에셋이다.
  final String url;

  /// 한 변. null 이면 주어진 자리를 채운다.
  final double? size;

  final BoxFit fit;

  /// 벡터 그림에서 `currentColor` 로 그려진 부분에 넣을 색.
  ///
  /// 프로필 테두리는 색이 박혀 있어서 지금은 안 쓴다. 미션 아이콘처럼 갈래 색을
  /// 따라가야 하는 그림이 이 자리를 쓴다.
  final Color? currentColor;

  const CosmeticArt({
    super.key,
    required this.url,
    this.size,
    this.fit = BoxFit.contain,
    this.currentColor,
  });

  /// 벡터 그림인지. 확장자만 본다.
  static bool isVector(String url) => url.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();

    final isNetwork = url.startsWith('http');

    if (isVector(url)) {
      final theme =
          currentColor == null ? null : SvgTheme(currentColor: currentColor!);
      return isNetwork
          ? SvgPicture.network(
              url,
              width: size,
              height: size,
              fit: fit,
              theme: theme,
              placeholderBuilder: (_) => SizedBox(width: size, height: size),
            )
          : SvgPicture.asset(
              url,
              width: size,
              height: size,
              fit: fit,
              theme: theme,
              placeholderBuilder: (_) => SizedBox(width: size, height: size),
            );
    }

    return Image(
      image: isNetwork
          ? NetworkImage(url) as ImageProvider<Object>
          : AssetImage(url),
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
