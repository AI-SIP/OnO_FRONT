import 'dart:io';

import 'package:flutter/material.dart';

import '../../../Module/Theme/ThemeHandler.dart';

class StudyRoomThumbnail extends StatelessWidget {
  final String? imagePath;
  final ThemeHandler themeProvider;
  final double size;
  final String? roomName;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const StudyRoomThumbnail({
    super.key,
    required this.imagePath,
    required this.themeProvider,
    required this.size,
    this.roomName,
    this.onTap,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnail = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: SizedBox(
        width: size,
        height: size,
        child: _buildImage(),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          thumbnail,
          if (showEditBadge)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: size * 0.17,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final path = imagePath;
    if (path == null || path.isEmpty) return _buildDefaultImage();

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultImage(),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildDefaultImage(),
    );
  }

  Widget _buildDefaultImage() {
    final initial = (roomName != null && roomName!.isNotEmpty)
        ? roomName![0].toUpperCase()
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeProvider.lightPrimaryColor,
            themeProvider.primaryColor,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 우측 상단 장식 원
          Positioned(
            right: -size * 0.18,
            top: -size * 0.14,
            child: Container(
              width: size * 0.68,
              height: size * 0.68,
              decoration: const BoxDecoration(
                color: Color(0x26FFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 좌측 하단 장식 원
          Positioned(
            left: -size * 0.14,
            bottom: -size * 0.10,
            child: Container(
              width: size * 0.50,
              height: size * 0.50,
              decoration: const BoxDecoration(
                color: Color(0x1AFFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 우측 하단 작은 점 강조
          Positioned(
            right: size * 0.14,
            bottom: size * 0.13,
            child: Container(
              width: size * 0.09,
              height: size * 0.09,
              decoration: const BoxDecoration(
                color: Color(0x4DFFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 중앙 콘텐츠: 이니셜 또는 아이콘
          Center(
            child: initial != null
                ? Text(
                    initial,
                    style: TextStyle(
                      fontSize: size * 0.42,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'PretendardBold',
                      shadows: const [
                        Shadow(
                          color: Color(0x22000000),
                          offset: Offset(0, 1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  )
                : _buildFallbackIcons(),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.menu_book_rounded,
          size: size * 0.34,
          color: Colors.white,
        ),
        SizedBox(height: size * 0.04),
        Icon(
          Icons.people_alt_rounded,
          size: size * 0.22,
          color: const Color(0xCCFFFFFF),
        ),
      ],
    );
  }
}
