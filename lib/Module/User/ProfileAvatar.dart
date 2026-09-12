import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../Constants/ProfileImageDefaults.dart';
import '../../Model/Cosmetic/CosmeticLoadoutModel.dart';
import '../../Screen/Cosmetic/Widget/CosmeticArt.dart';
import '../../Screen/User/Widget/FrogCharacter.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Color borderColor;
  final double borderWidth;
  final Color backgroundColor;

  /// 사진을 올리지 않았을 때 대신 세울 개구리.
  ///
  /// **꾸민 개구리는 넘긴 자리에서만 뜬다.** 스터디룸에서 보는 남의 프로필은
  /// 그 사람이 무엇을 입었는지 서버가 내려주지 않아서, 내 개구리를 남의 자리에
  /// 세우면 거짓말이 된다. 그래서 기본값은 null 이고, 내 프로필이 뜨는
  /// 자리에서만 `CosmeticProvider.layers` 를 넘긴다.
  ///
  /// 넘기지 않은 자리에는 [ProfileImageDefaults] 의 **맨 개구리**가 선다.
  /// 무엇을 입었는지는 몰라도 개구리인 것은 맞다.
  final List<CosmeticLayerModel>? frogLayers;

  /// 원 둘레에 두르는 **치장 테두리** 그림. 안 걸쳤으면 null 이다.
  ///
  /// `FRAME` 자리의 아이템이다. 개구리에 겹치는 파츠가 아니라서
  /// `CosmeticProvider.layers` 에는 안 들어오고 `profileFrame` 으로 따로 온다.
  /// [frogLayers] 와 같은 이유로 **내 프로필이 뜨는 자리에서만** 넘긴다. 남의
  /// 프로필에 내 테두리를 두르면 거짓말이 된다.
  ///
  /// 테두리는 안에 무엇이 들어 있든 **바깥에서 감싼다.** 사진을 바꿔도
  /// 그대로다.
  final String? frameUrl;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.size,
    required this.borderColor,
    this.borderWidth = 1,
    this.backgroundColor = Colors.white,
    this.frogLayers,
    this.frameUrl,
  });

  /// 테두리 그림 한 변에 대한 **안쪽 빈 자리**의 비율.
  ///
  /// 프레임 에셋은 120 × 120 이고 가운데 96 × 96 을 비워 두었다. 사진이 그
  /// 96 자리에 앉고 테두리가 바깥 12px 을 두른다.
  static const double _frameInnerRatio = 96 / 120;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = imageUrl?.trim();
    final frame = frameUrl?.trim();
    final framed = frame != null && frame.isNotEmpty;

    // **테두리를 둘러도 전체 지름은 그대로다.** 바깥으로 커지면 스터디룸
    // 목록에서 줄이 밀린다. 안쪽 사진이 그만큼 작아지는 것이 맞다.
    final innerSize = framed ? size * _frameInnerRatio : size;

    final circle = Container(
      width: innerSize,
      height: innerSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        // 치장 테두리를 둘렀으면 기본 테두리를 지운다. 두 겹이면 둘레에 선이
        // 두 줄 생겨서 치장이 덧댄 것처럼 보인다.
        border:
            framed ? null : Border.all(color: borderColor, width: borderWidth),
      ),
      child: ClipOval(
        child: resolvedUrl == null || resolvedUrl.isEmpty
            ? _defaultImage(innerSize, framed)
            : CachedNetworkImage(
                imageUrl: resolvedUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _defaultImage(innerSize, framed),
                errorWidget: (_, __, ___) => _defaultImage(innerSize, framed),
              ),
      ),
    );

    if (!framed) return circle;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 안쪽 사진이 먼저다. 테두리는 그 둘레를 도는 것이라 위에 얹혀도
          // 사진을 덮지 않는다. 가운데가 비어 있는 그림이기 때문이다.
          circle,
          IgnorePointer(
            child: CosmeticArt(url: frame, size: size, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }

  /// 사진이 없을 때 세우는 개구리 얼굴.
  ///
  /// 개구리는 전신 그림인데 프로필은 작은 원이라 그냥 넣으면 머리가 위쪽에
  /// 조그맣게 박힌다. 얼굴만 도려내는 일은 [FrogHeadAvatar] 가 이미 하고
  /// 있어서 꾸민 개구리든 맨 개구리든 같은 것을 쓴다. 테두리 두께만큼 안쪽에
  /// 앉혀야 원 밖으로 삐져나오지 않는다.
  ///
  /// [innerSize] 는 치장 테두리를 둘렀을 때 그만큼 줄어든 안쪽 지름이다.
  Widget _defaultImage(double innerSize, bool framed) {
    return FrogHeadAvatar(
      layers: frogLayers ?? _bareFrog,
      // 치장 테두리를 둘렀으면 기본 테두리가 없으니 안쪽으로 들일 것도 없다.
      size: framed ? innerSize : innerSize - borderWidth * 2,
    );
  }

  /// 아무것도 안 걸친 개구리 한 장.
  static const List<CosmeticLayerModel> _bareFrog = [
    CosmeticLayerModel(
      imageUrl: ProfileImageDefaults.assetPath,
      layerOrder: 0,
    ),
  ];
}
