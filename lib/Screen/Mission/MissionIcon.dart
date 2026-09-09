import 'package:flutter/material.dart';

import '../../Module/Design/AppRadius.dart';

/// 미션 아이콘을 고르는 곳이다. **아이콘 결정은 전부 이 파일에 모아 둔다.**
///
/// 원래 계획은 `assets/MissionIcon/{iconKey}.svg` 를 `flutter_svg` 로 그리고
/// 테마색을 입히는 것이다. 그런데 에셋 19종이 아직 제작 중이라 파일이 없다.
/// 없는 에셋을 `pubspec.yaml` 에 등록하면 빌드가 깨지므로, 지금은 Material
/// 아이콘으로 대신 그린다.
///
/// 에셋이 들어오면 [_iconByKey] 를 참고해 [MissionIcon.build] 안쪽만
/// `SvgPicture.asset('assets/MissionIcon/$iconKey.svg', colorFilter: ...)` 로
/// 바꾸면 된다. 화면 코드는 손대지 않아도 된다.
abstract final class MissionIconKeys {
  /// 모르는 키가 왔을 때 쓰는 폴백.
  static const String fallback = 'default';
}

/// 키 하나에 아이콘 하나. 에셋 정의서의 19종과 키를 맞춰 둔다.
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
///
/// 크기를 밖에서 정할 수 있게 열어 두되 기본값을 둔다. 글자를 키운 기기에서도
/// 아이콘은 같이 커지지 않아야 줄이 안정적이라 [size] 는 고정 값을 받는다.
class MissionIcon extends StatelessWidget {
  final String iconKey;
  final Color color;
  final double size;

  const MissionIcon({
    super.key,
    required this.iconKey,
    required this.color,
    this.size = 18,
  });

  /// 모르는 키는 기본 아이콘으로 떨어진다. 서버가 새 미션을 추가해도
  /// 구버전 앱에 빈칸이 뜨지 않는다.
  static IconData resolve(String? iconKey) {
    return _iconByKey[iconKey] ?? _iconByKey[MissionIconKeys.fallback]!;
  }

  /// 이 키를 앱이 아는지. 테스트와 디버깅용이다.
  static bool isKnown(String? iconKey) => _iconByKey.containsKey(iconKey);

  @override
  Widget build(BuildContext context) {
    return Icon(resolve(iconKey), color: color, size: size);
  }
}

/// 아이콘을 테마색 옅은 사각형 안에 넣은 것. 홈 배너와 미션 줄이 같이 쓴다.
class MissionIconBox extends StatelessWidget {
  final String iconKey;
  final Color color;
  final double padding;
  final double iconSize;

  const MissionIconBox({
    super.key,
    required this.iconKey,
    required this.color,
    this.padding = 10,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: MissionIcon(iconKey: iconKey, color: color, size: iconSize),
    );
  }
}
