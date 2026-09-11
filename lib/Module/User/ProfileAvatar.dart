import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Constants/ProfileImageDefaults.dart';
import '../../Model/Cosmetic/CosmeticLoadoutModel.dart';
import '../../Screen/User/Widget/FrogCharacter.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Color borderColor;
  final double borderWidth;
  final Color backgroundColor;

  /// 사진을 올리지 않았을 때 대신 세울 개구리.
  ///
  /// **넘긴 자리에서만 개구리가 뜬다.** 스터디룸에서 보는 남의 프로필은 그
  /// 사람이 무엇을 입었는지 서버가 내려주지 않아서, 내 개구리를 남의 자리에
  /// 세우면 거짓말이 된다. 그래서 기본값은 null 이고, 내 프로필이 뜨는
  /// 자리에서만 `CosmeticProvider.layers` 를 넘긴다. 넘기지 않으면 예전처럼
  /// [ProfileImageDefaults] 의 그림이 나온다.
  final List<CosmeticLayerModel>? frogLayers;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.size,
    required this.borderColor,
    this.borderWidth = 1,
    this.backgroundColor = Colors.white,
    this.frogLayers,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = imageUrl?.trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
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
  }

  Widget _defaultImage() {
    // 개구리를 받은 자리에서는 개구리가 기본 사진이다. 테두리 두께만큼 안쪽에
    // 앉혀야 원 밖으로 삐져나오지 않는다.
    final layers = frogLayers;
    if (layers != null) {
      return FrogHeadAvatar(layers: layers, size: size - borderWidth * 2);
    }

    if (ProfileImageDefaults.assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        ProfileImageDefaults.assetPath,
        fit: BoxFit.cover,
      );
    }

    return Image.asset(ProfileImageDefaults.assetPath, fit: BoxFit.cover);
  }
}
