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
    'cheers_beer': 1.14,
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
    'stressed_bomb': 1.30,
    'studying_together': 1.10,
    'texting_heart': 1.14,
    'thumbs_up_wink': 1.08,
    'trophy_celebration': 1.45,
    'umbrella_rain': 1.14,
    'waving_hello': 1.18,
    'winking_fist': 1.21,
    'writing_wink': 1.40,
  };

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
      child: ClipRect(
        child: Transform.scale(
          scale: visualScale,
          child: Image.asset(
            resolvedEmoji.assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              developer
                  .log('Missing OnO emoji asset: ${resolvedEmoji.assetPath}');
              return SizedBox(width: size, height: size);
            },
          ),
        ),
      ),
    );
  }
}
