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
  /// 사진을 올렸든 개구리가 섰든 **원 위에 그대로 얹는다.** 테두리는 안에 무엇이
  /// 들어 있든 둘레를 도는 것이고, 그래야 사진을 바꿔도 테두리가 유지된다.
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

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = imageUrl?.trim();
    final frame = frameUrl?.trim();

    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        // 치장 테두리를 둘렀으면 기본 테두리를 지운다. 두 겹이면 둘레에 선이
        // 두 줄 생겨서 치장이 덧댄 것처럼 보인다.
        border: frame == null || frame.isEmpty
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: resolvedUrl == null || resolvedUrl.isEmpty
            ? _defaultImage()
            : CachedNetworkImage(
                imageUrl: resolvedUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _defaultImage(),
                errorWidget: (_, __, ___) => _defaultImage(),
              ),
      ),
    );

    if (frame == null || frame.isEmpty) return circle;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          circle,
          // 테두리는 원 전체를 덮는 한 장이다. 안쪽은 비어 있어서 사진도
          // 개구리도 그대로 비친다. 누름은 아래 원이 받아야 한다.
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
  Widget _defaultImage() {
    final framed = frameUrl != null && frameUrl!.trim().isNotEmpty;
    return FrogHeadAvatar(
      layers: frogLayers ?? _bareFrog,
      // 치장 테두리를 둘렀으면 기본 테두리가 없으니 안쪽으로 들일 것도 없다.
      size: framed ? size : size - borderWidth * 2,
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
