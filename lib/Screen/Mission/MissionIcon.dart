import 'package:flutter/material.dart';

import '../../Model/Mission/MissionModel.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Emoji/OnoEmojiCatalog.dart';
import 'MissionPalette.dart';

/// 미션 아이콘을 고르는 곳이다. **아이콘 결정은 전부 이 파일에 모아 둔다.**
///
/// 원래 계획은 `assets/MissionIcon/{iconKey}.svg` 19종이었는데 아직 제작
/// 중이다. 그동안 Material 아이콘으로 그렸더니 앱의 다른 화면과 결이 달랐다.
/// 이 앱에는 이미 직접 그린 이모지 66종(`assets/emoji/`)이 있고 문자열 키로
/// 쓰는 체계도 있다. 전용 아이콘이 나올 때까지 그것을 빌려 쓴다.
///
/// 전용 에셋이 들어오면 [_emojiByCode] / [_emojiByIconKey] 자리에 SVG 경로를
/// 넣고 [MissionIcon.build] 안쪽만 바꾸면 된다. 화면 코드는 손대지 않는다.
abstract final class MissionIconKeys {
  /// 모르는 키가 왔을 때 쓰는 폴백. 모델이 쓰는 기본값과 같아야 한다.
  static const String fallback = MissionModel.fallbackIconKey;

  /// 아무것도 못 찾았을 때 쓰는 이모지. 새싹이 자라는 그림이다.
  static const String fallbackEmoji = 'sprout_growth';
}

/// 미션 코드로 먼저 고른다.
///
/// 일일과 주간이 같은 `iconKey` 를 쓰기 때문이다(주간 출석도 `attendance`).
/// 코드로 갈라야 `꾸준함`과 `출석`이 다른 그림을 갖는다.
const Map<String, String> _emojiByCode = <String, String>{
  'DAILY_ATTEND': 'success_checkmark',
  'DAILY_NOTE_WRITE': 'holding_pen',
  'DAILY_REVIEW_3': 'reading_with_glasses',
  'DAILY_CORRECT_3': 'got_100_score',
  'DAILY_PRACTICE_SET': 'studying_with_lamp',
  'DAILY_MOOD': 'star_eyes_excited',
  'WEEKLY_ATTEND_5': 'fired_up_sparkle_eyes',
  'WEEKLY_NOTE_10': 'writing_wink',
  'WEEKLY_REVIEW_30': 'reading_tablet',
  'WEEKLY_SET_3': 'trophy_celebration',
};

/// 코드를 모르면 아이콘 키로 고른다. 서버가 미션을 새로 추가해도 여기서 걸린다.
const Map<String, String> _emojiByIconKey = <String, String>{
  'attendance': 'success_checkmark',
  'note_write': 'holding_pen',
  'review': 'reading_with_glasses',
  'accuracy': 'got_100_score',
  'practice_set': 'studying_with_lamp',
  'mood': 'star_eyes_excited',
  'streak': 'fired_up_sparkle_eyes',
  'master': 'trophy_celebration',
  'revenge': 'winking_fist',
  'overdue': 'frustrated_studying',
  'reflection': 'writing_wink',
  'photo': 'star_eyes_excited',
  'tag': 'puzzle_teamwork',
  'share': 'studying_together',
  'cheer': 'thumbs_up_wink',
  'cleanup': 'success_checkmark',
  'dawn': 'sprout_growth',
  'night': 'cozy_blanket',
  MissionIconKeys.fallback: MissionIconKeys.fallbackEmoji,
};

/// 이모지 에셋마저 없을 때 쓰는 마지막 폴백이다.
const Map<String, IconData> _iconByKey = <String, IconData>{
  'note_write': Icons.edit_note,
  'review': Icons.refresh,
  'practice_set': Icons.style_outlined,
  'mood': Icons.chat_bubble_outline,
  'revenge': Icons.gps_fixed,
  'overdue': Icons.schedule,
  'tag': Icons.local_offer_outlined,
  'photo': Icons.photo_outlined,
  'reflection': Icons.notes,
  'share': Icons.ios_share,
  'cheer': Icons.favorite_outline,
  'attendance': Icons.event_available_outlined,
  'master': Icons.star_outline,
  'cleanup': Icons.cleaning_services_outlined,
  'streak': Icons.local_fire_department_outlined,
  'accuracy': Icons.adjust,
  'dawn': Icons.wb_twilight,
  'night': Icons.nightlight_outlined,
  MissionIconKeys.fallback: Icons.flag_outlined,
};

/// 미션 아이콘 하나를 그린다.
class MissionIcon extends StatelessWidget {
  final String iconKey;

  /// 미션 코드. 있으면 이쪽을 먼저 본다.
  final String? code;

  /// 이모지를 못 그렸을 때 쓰는 폴백 아이콘의 색.
  final Color color;

  final double size;

  const MissionIcon({
    super.key,
    required this.iconKey,
    required this.color,
    this.code,
    this.size = 28,
  });

  /// 이 미션에 쓸 이모지 키. 모르는 값은 새싹으로 떨어진다.
  static String resolveEmojiKey({String? code, String? iconKey}) {
    final byCode = code == null ? null : _emojiByCode[code];
    if (byCode != null) return byCode;
    final byIconKey = iconKey == null ? null : _emojiByIconKey[iconKey];
    return byIconKey ?? MissionIconKeys.fallbackEmoji;
  }

  /// 이모지 에셋까지 없을 때 쓰는 아이콘. 모르는 키는 깃발이다.
  static IconData resolve(String? iconKey) {
    return _iconByKey[iconKey] ?? _iconByKey[MissionIconKeys.fallback]!;
  }

  /// 이 키를 앱이 아는지. 테스트와 디버깅용이다.
  static bool isKnown(String? iconKey) => _iconByKey.containsKey(iconKey);

  @override
  Widget build(BuildContext context) {
    final emoji = OnoEmojiCatalog.byKey(
      resolveEmojiKey(code: code, iconKey: iconKey),
    );
    if (emoji == null) {
      return Icon(resolve(iconKey), color: color, size: size);
    }

    // 이모지 원본은 한 장에 200KB 가까이 된다. 화면에는 30px 안팎으로 뜨므로
    // 디코딩 크기를 그 두 배 남짓으로 잘라 둔다. 이걸 안 하면 목록에 카드가
    // 열 장만 떠도 메모리가 크게 는다.
    final devicePixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final cacheWidth = (size * devicePixelRatio).round().clamp(24, 256);

    return Image.asset(
      emoji.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) =>
          Icon(resolve(iconKey), color: color, size: size),
    );
  }
}

/// 아이콘을 옅은 사각형 안에 넣은 것. 홈 배너가 쓴다.
///
/// 색은 미션의 갈래를 따른다. 목록이든 배너든 같은 미션은 같은 색이어야 한다.
class MissionIconBox extends StatelessWidget {
  final String iconKey;
  final String? code;

  /// 갈래 색 한 벌. 주지 않으면 미션에서 알아서 고른다.
  final MissionKindColors? colors;

  final double padding;
  final double iconSize;

  const MissionIconBox({
    super.key,
    required this.iconKey,
    this.code,
    this.colors,
    this.padding = 8,
    this.iconSize = 30,
  });

  @override
  Widget build(BuildContext context) {
    final resolved =
        colors ?? MissionPalette.colorsOf(code: code, iconKey: iconKey);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: resolved.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: MissionIcon(
        iconKey: iconKey,
        code: code,
        color: resolved.accent,
        size: iconSize,
      ),
    );
  }
}
