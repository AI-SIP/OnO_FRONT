import 'package:flutter/material.dart';

/// 점토 렌더 아이콘 한 장.
///
/// 옷장 탭과 개구리가 말랑한 점토 그림으로 바뀌면서 앱의 나머지 아이콘도 같은
/// 재질로 다시 그렸다. 예전 그림은 SVG 였지만 이 그림들은 그늘과 하이라이트가
/// 들어간 512 짜리 PNG 라 [SvgPicture] 가 아니라 [Image] 로 그린다.
///
/// **원본 크기 그대로 물면 안 된다.** 512×512 한 장을 그대로 디코딩하면
/// 1MB 를 차지한다. 공책 아이콘은 목록에서 30~60 으로 뜨는데, 그 크기로
/// 스무 장이 떠 있으면 쓸데없이 20MB 를 붙들고 있는 셈이다. 그래서 화면에
/// 뜨는 크기 × 기기 배율만큼만 디코딩한다([Image.asset] 의 `cacheWidth`).
/// 옷장 탭 버튼(`CharacterScreen`)이 먼저 이렇게 하고 있다.
class ClayIcon extends StatelessWidget {
  const ClayIcon(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.tint,
  });

  /// `assets/Icon/...png` 경로.
  final String assetPath;

  final double? width;
  final double? height;
  final BoxFit fit;

  /// 그림 전체를 이 색으로 덮는다.
  ///
  /// 예전 [SvgPicture] 의 `color` 와 같은 자리다. 풀컬러 PNG 라 색을 "입히는"
  /// 것이 아니라 실루엣만 남기고 통째로 칠하게 되니, 아직 안 한 것을 비워
  /// 보이게 하는 용도로만 쓴다.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    // 테스트 환경처럼 MediaQuery 가 없을 수도 있다. 그때는 흔한 2배로 본다.
    final ratio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;

    // 그림이 정사각형이라 가로만 잘라 두면 세로는 따라온다. 둘 다 안 주면
    // 부모가 크기를 정한다는 뜻이라 원본대로 둔다.
    final longest = [width, height].whereType<double>().fold<double>(0, (a, b) {
      return a > b ? a : b;
    });
    final cacheWidth = longest > 0 ? (longest * ratio).round() : null;

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      color: tint,
      colorBlendMode: tint == null ? null : BlendMode.srcIn,
      filterQuality: FilterQuality.medium,
      // 그림 한 장이 없다고 화면이 빨간 상자로 덮이면 안 된다. 자리만
      // 지킨다. 경로 오타는 `test/asset/icon_asset_path_test.dart` 가 잡는다.
      errorBuilder: (_, __, ___) => SizedBox(width: width, height: height),
    );
  }
}
