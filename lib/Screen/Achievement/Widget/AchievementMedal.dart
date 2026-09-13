import 'package:flutter/material.dart';

/// 훈장 그림 한 장이다.
///
/// 에셋은 512 정사각 PNG 인데 화면에는 64 남짓으로 뜬다. 디코딩 크기를 잘라
/// 두지 않으면 한 장에 1MB 를 물고, 열두 장이 한 목록에 있으니 12MB 가 된다.
/// 그래서 [Image.asset] 의 `cacheWidth` 를 반드시 준다. 치장의
/// `CosmeticArt` 를 그대로 쓰지 않은 것이 이 때문이다. 그쪽은 SVG 도 같이
/// 다뤄야 해서 디코딩 크기를 받지 않는다. 훈장 그림은 계약상 PNG 한 종류다.
///
/// **못 받은 것은 색을 빼고 옅게 둔다. 감추지는 않는다.** 옷장 격자와 같은
/// 규칙이다. 무엇이 기다리고 있는지 보여야 갖고 싶어진다.
class AchievementMedal extends StatelessWidget {
  /// 그림의 자리. `http` 로 시작하면 네트워크, 아니면 에셋이다.
  final String imageUrl;

  /// 한 변.
  final double size;

  /// 아직 못 받은 것인지.
  final bool locked;

  const AchievementMedal({
    super.key,
    required this.imageUrl,
    required this.size,
    required this.locked,
  });

  /// 못 받은 것을 흑백으로 만드는 행렬이다. 옷장이 쓰는 것과 같은 값이다.
  static const List<double> _grayscale = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return SizedBox(width: size, height: size);

    final devicePixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final cacheWidth = (size * devicePixelRatio).round();
    final isNetwork = imageUrl.startsWith('http');

    // 그림을 못 읽으면 그 자리를 비운다. 그림 한 장 때문에 목록이 깨지면 안 된다.
    Widget errorBox(BuildContext _, Object __, StackTrace? ___) =>
        SizedBox(width: size, height: size);

    final image = isNetwork
        ? Image.network(
            imageUrl,
            width: size,
            height: size,
            fit: BoxFit.contain,
            cacheWidth: cacheWidth,
            filterQuality: FilterQuality.medium,
            errorBuilder: errorBox,
          )
        : Image.asset(
            imageUrl,
            width: size,
            height: size,
            fit: BoxFit.contain,
            cacheWidth: cacheWidth,
            filterQuality: FilterQuality.medium,
            errorBuilder: errorBox,
          );

    if (!locked) return image;

    return Opacity(
      opacity: 0.5,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscale),
        child: image,
      ),
    );
  }
}
