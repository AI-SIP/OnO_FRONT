import 'package:flutter/material.dart';

import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Text/StandardText.dart';

/// 미션 화면들이 쓰는 작은 라벨이다.
///
/// 기간(`지난주`), 능력치(`문제 복습`), 진행도(`2/3`), 보상(`+10 XP`)이 저마다
/// 다른 모서리와 크기, 여백을 갖고 있으면 화면이 누가 급하게 붙인 것처럼
/// 보인다. **모양은 하나로 두고 색만 다르게 한다.**
///
/// 테두리도 그림자도 없다. 옅은 바탕에 글자만 얹는 납작한 알약이라 앱의 다른
/// 버튼, 카드와 같은 결로 앉는다.
class MissionTag extends StatelessWidget {
  /// 라벨 글자.
  final String text;

  /// 글자색. 바탕은 이 색을 옅게 깐 것이 기본이다.
  final Color color;

  /// 바탕색. 주지 않으면 [color] 를 옅게 깐다.
  final Color? background;

  /// 글자 앞에 놓을 것. 보상 표시의 동그란 점 같은 것.
  final Widget? leading;

  /// 흐리게 둘지. 이미 받은 보상처럼 다 끝난 것에 쓴다.
  final bool dimmed;

  const MissionTag({
    super.key,
    required this.text,
    required this.color,
    this.background,
    this.leading,
    this.dimmed = false,
  });

  /// 모양을 정하는 값들이다. 이 셋은 어디서나 같다.
  static const double fontSize = 11;
  static const EdgeInsets padding =
      EdgeInsets.symmetric(horizontal: 8, vertical: 3);

  /// 색을 쓰지 않는 중성 라벨. 진행도처럼 뜻이 없는 숫자에 쓴다.
  factory MissionTag.neutral(String text) {
    return MissionTag(
      text: text,
      color: AppColors.textSecondary,
      background: AppColors.surfaceMuted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = background ??
        Color.alphaBlend(color.withValues(alpha: 0.14), Colors.white);

    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 5),
            ],
            // 글자를 키운 기기에서도 라벨이 줄을 밀어내지 않게 한 줄로 줄인다.
            Flexible(
              child: StandardText(
                text: text,
                fontSize: fontSize,
                color: color,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
