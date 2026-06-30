import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Constants/ProfileImageDefaults.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Color borderColor;
  final double borderWidth;
  final Color backgroundColor;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.size,
    required this.borderColor,
    this.borderWidth = 1,
    this.backgroundColor = Colors.white,
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
    if (ProfileImageDefaults.assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        ProfileImageDefaults.assetPath,
        fit: BoxFit.cover,
      );
    }

    return Image.asset(ProfileImageDefaults.assetPath, fit: BoxFit.cover);
  }
}
