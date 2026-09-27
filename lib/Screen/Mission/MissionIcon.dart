import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Model/Mission/MissionModel.dart';
import '../../Module/Design/AppRadius.dart';
import 'MissionPalette.dart';

/// 미션 아이콘을 고르는 곳이다. **아이콘 결정은 전부 이 파일에 모아 둔다.**
///
/// 전용 아이콘 열아홉 종이 `assets/MissionIcon/{iconKey}.svg` 로 들어왔다.
/// 그전까지는 앱이 이미 가진 이모지 예순여섯 종을 빌려 썼는데, 이모지는 이
/// 앱의 다른 자리를 위해 그린 그림이라 미션이 말하는 것과 어긋나는 짝이
/// 있었고 한 장에 200KB 나 됐다.
///
/// 파일 이름이 곧 서버가 내려주는 `iconKey` 다. 열아홉 종이 서버가 쓰는 키
/// 전부와 일대일로 맞아서, 따로 옮겨 적는 표가 없어도 된다. 앱이 모르는 키가
/// 와도 `default.svg` 가 뜬다.
abstract final class MissionIconKeys {
  /// 모르는 키가 왔을 때 쓰는 폴백. 모델이 쓰는 기본값과 같아야 한다.
  static const String fallback = MissionModel.fallbackIconKey;

  /// 전용 아이콘이 놓인 자리.
  static const String assetDirectory = 'assets/MissionIcon';

  /// 앱이 가지고 있는 아이콘 이름 전부. 파일 목록과 같아야 한다.
  static const Set<String> known = <String>{
    'accuracy',
    'attendance',
    'cheer',
    'cleanup',
    'dawn',
    fallback,
    'master',
    'mood',
    'night',
    'note_write',
    'overdue',
    'photo',
    'practice_set',
    'reflection',
    'revenge',
    'review',
    'share',
    'streak',
    'tag',
  };
}

/// 미션 코드로 아이콘을 갈아 끼우는 자리다.
///
/// **일일과 주간이 같은 `iconKey` 로 오기 때문이다.** 주간 출석도 서버는
/// `attendance` 로 보내는데, 한 주를 채운 것과 오늘 하루 켠 것은 다른 그림이어야
/// 한다. 여기 적힌 코드만 갈아 끼우고 나머지는 `iconKey` 를 그대로 쓴다.
const Map<String, String> _iconNameByCode = <String, String>{
  'WEEKLY_ATTEND_5': 'streak',
  'WEEKLY_NOTE_10': 'reflection',
  'WEEKLY_SET_3': 'master',
};

/// 그림 파일마저 못 읽었을 때 쓰는 마지막 폴백이다.
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

  /// 이 미션에 쓸 아이콘 이름. 모르는 값은 `default` 로 떨어진다.
  static String resolveName({String? code, String? iconKey}) {
    final byCode = code == null ? null : _iconNameByCode[code];
    if (byCode != null) return byCode;
    if (iconKey != null && MissionIconKeys.known.contains(iconKey)) {
      return iconKey;
    }
    return MissionIconKeys.fallback;
  }

  /// 이 미션에 쓸 그림 파일의 자리.
  static String resolveAsset({String? code, String? iconKey}) =>
      '${MissionIconKeys.assetDirectory}/'
      '${resolveName(code: code, iconKey: iconKey)}.svg';

  /// 그림 파일까지 못 읽었을 때 쓰는 아이콘. 모르는 키는 깃발이다.
  static IconData resolve(String? iconKey) {
    return _iconByKey[iconKey] ?? _iconByKey[MissionIconKeys.fallback]!;
  }

  /// 이 키를 앱이 아는지. 테스트와 디버깅용이다.
  static bool isKnown(String? iconKey) =>
      MissionIconKeys.known.contains(iconKey);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      resolveAsset(code: code, iconKey: iconKey),
      width: size,
      height: size,
      fit: BoxFit.contain,
      // 벡터라서 크기를 키워도 뭉개지지 않는다. 이모지를 쓰던 때처럼 디코딩
      // 크기를 잘라 둘 일도 없다.
      //
      // 그림을 읽는 동안에는 자리만 잡아 둔다. 여기서 폴백 아이콘을 그리면
      // 목록이 뜰 때마다 깃발이 한 번 번쩍인다.
      placeholderBuilder: (_) => SizedBox(width: size, height: size),
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
