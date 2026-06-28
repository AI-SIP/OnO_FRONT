import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import 'OnoEmoji.dart';
import 'OnoEmojiCatalog.dart';

class OnoEmojiImage extends StatelessWidget {
  final String? emojiKey;
  final OnoEmoji? emoji;
  final double size;

  const OnoEmojiImage({
    super.key,
    this.emojiKey,
    this.emoji,
    required this.size,
  });

  static const Map<String, double> _visualScaleByKey = {
    'birthday_cake': 1.12,
    'cheek_to_cheek': 1.45,
    'confused_question': 1.11,
    'cool_sunglasses': 1.19,
    'cozy_blanket': 1.10,
    'cuddle_love': 1.45,
    'drinking_coffee': 1.13,
    'eating_ice_cream': 1.17,
    'eating_skewer': 1.25,
    'excited_happy': 1.08,
    'frustrated_studying': 1.13,
    'got_100_score': 1.15,
    'happy_tears': 1.45,
    'hi_greeting': 1.16,
    'holding_flower': 1.09,
    'lol_laughing_tears': 1.24,
    'puzzle_teamwork': 1.21,
    'reading_tablet': 1.25,
    'reading_with_glasses': 1.28,
    'scared_dread': 1.25,
    'shy_wink_heart': 1.24,
    'sprout_growth': 1.22,
    'star_eyes_excited': 1.11,
    'studying_together': 1.10,
    'texting_heart': 1.14,
    'thumbs_up_wink': 1.08,
    'trophy_celebration': 1.45,
    'umbrella_rain': 1.14,
    'waving_hello': 1.18,
    'winking_fist': 1.21,
    'writing_wink': 1.40,
  };

  static const List<Offset> _contrastHaloOffsets = [
    Offset(0, -1),
    Offset(1, 0),
    Offset(0, 1),
    Offset(-1, 0),
  ];

  @override
  Widget build(BuildContext context) {
    final resolvedEmoji = emoji ?? OnoEmojiCatalog.byKey(emojiKey ?? '');
    if (resolvedEmoji == null) {
      developer.log('Unknown OnO emoji key: $emojiKey');
      return SizedBox(width: size, height: size);
    }

    final visualScale = _visualScaleByKey[resolvedEmoji.key] ?? 1.0;

    return SizedBox(
      width: size,
      height: size,
      child: Transform.scale(
        scale: visualScale,
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (final offset in _contrastHaloOffsets)
              Transform.translate(
                offset: offset * (size * 0.035),
                child: _buildTintedAsset(
                  resolvedEmoji.assetPath,
                  Colors.black.withValues(alpha: 0.18),
                ),
              ),
            Transform.translate(
              offset: Offset(0, size * 0.045),
              child: _buildTintedAsset(
                resolvedEmoji.assetPath,
                Colors.black.withValues(alpha: 0.12),
              ),
            ),
            Image.asset(
              resolvedEmoji.assetPath,
              width: size,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) {
                developer
                    .log('Missing OnO emoji asset: ${resolvedEmoji.assetPath}');
                return SizedBox(width: size, height: size);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTintedAsset(String assetPath, Color color) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
    );
  }
}
