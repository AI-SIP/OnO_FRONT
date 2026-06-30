import 'dart:io';

import 'package:flutter/material.dart';

import '../../../Module/Emoji/OnoEmojiCatalog.dart';
import '../../../Module/Emoji/OnoEmojiImage.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class StudyRoomThumbnail extends StatelessWidget {
  static const String defaultEmojiKey = 'studying_together';

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
    final thumbnail = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: themeProvider.primaryColor, width: 1.5),
      ),
      padding: const EdgeInsets.all(1.5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.20),
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

    final emojiKey = _emojiKeyFromAssetPath(path);
    if (emojiKey != null) {
      return _buildEmojiImage(emojiKey, size * 0.76);
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultImage(),
      );
    }

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
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.white),
        Center(
          child: Padding(
            padding: EdgeInsets.all(size * 0.08),
            child: _buildEmojiImage(defaultEmojiKey, size * 0.80),
          ),
        ),
      ],
    );
  }

  String? _emojiKeyFromAssetPath(String path) {
    if (!path.startsWith('assets/emoji/') || !path.endsWith('.png')) {
      return null;
    }

    final emojiKey = path.split('/').last.replaceFirst('.png', '');
    return OnoEmojiCatalog.byKey(emojiKey) == null ? null : emojiKey;
  }

  Widget _buildEmojiImage(String emojiKey, double emojiSize) {
    return Center(
      child: OnoEmojiImage(
        emojiKey: emojiKey,
        size: emojiSize,
      ),
    );
  }
}
