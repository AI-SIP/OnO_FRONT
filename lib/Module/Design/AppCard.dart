import 'package:flutter/material.dart';

import 'AppColors.dart';
import 'AppRadius.dart';
import 'AppSpacing.dart';

/// 앱의 카드다.
///
/// 지금은 카드마다 생김새가 다르다. 어떤 것은 회색 테두리를 두르고, 어떤 것은
/// 테두리 없이 그림자만 있고, 어떤 것은 둘 다 있다. 모서리도 10 과 12 와 15 가
/// 섞여 있다.
///
/// 토스처럼 보이려면 선을 줄이고 면으로 구분하는 쪽이 낫다. 기본은 테두리 없는
/// 흰 면이고, 아주 옅은 그림자로 바닥에서 살짝 띄운다.
///
/// ```dart
/// AppCard(child: Column(children: [...]))
/// ```
class AppCard extends StatelessWidget {
  final Widget child;

  /// 카드 안쪽 여백. 이미지처럼 가장자리까지 채워야 하면 0 을 준다.
  final EdgeInsetsGeometry? padding;

  final EdgeInsetsGeometry? margin;

  /// 기본은 흰색.
  final Color? color;

  final double radius;

  /// 강조하고 싶은 카드만 켠다. 모든 카드가 떠 있으면 위계가 사라진다.
  final bool elevated;

  /// 테두리가 꼭 필요한 곳에서만 켠다.
  final bool bordered;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.radius = AppRadius.large,
    this.elevated = true,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: bordered ? Border.all(color: AppColors.border) : null,
        boxShadow: elevated
            ? const [
                // 그림자가 보이면 안 된다. 바닥에서 떨어져 있다는 것만
                // 느껴지는 정도로 둔다.
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 12,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// 카드 안의 작은 제목이다. 아이콘과 글자 간격, 크기를 맞춰 둔다.
class AppCardTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? iconColor;

  const AppCardTitle({
    super.key,
    required this.text,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? Theme.of(context).primaryColor;

    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'PretendardBold',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
