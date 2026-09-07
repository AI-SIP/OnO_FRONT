import 'package:flutter/material.dart';

import '../Text/StandardText.dart';
import 'AnimatedGauge.dart';
import 'AppMotion.dart';

/// 여러 단계를 거치는 흐름에서 지금 어디쯤인지 보여주는 막대다.
///
/// 오답노트 일괄 등록(이미지 고르기 다음 상세 입력)이나 복습 세트 만들기
/// (제목 쓰기 다음 문제 고르기)처럼 화면이 몇 번 넘어가는 흐름에 놓는다.
/// 단계가 넘어가면 막대가 다음 자리까지 이어서 움직인다.
///
/// ```dart
/// StepProgressBar(
///   currentStep: 2,
///   totalSteps: 3,
///   color: themeProvider.primaryColor,
/// )
/// ```
class StepProgressBar extends StatelessWidget {
  /// 지금 몇 번째 단계인지. 첫 단계가 1 이다.
  final int currentStep;

  /// 전체 단계 수.
  final int totalSteps;

  final Color color;
  final Color? backgroundColor;
  final double height;

  /// 오른쪽에 "2 / 3" 을 함께 보일지.
  final bool showLabel;

  /// 라벨 글자색. 넘기지 않으면 회색이다.
  final Color? labelColor;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.color,
    this.backgroundColor,
    this.height = 4.0,
    this.showLabel = false,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = totalSteps > 0 ? currentStep / totalSteps : 0.0;

    final bar = AnimatedLinearGauge(
      value: ratio,
      color: color,
      backgroundColor: backgroundColor,
      height: height,
      borderRadius: height / 2,
      // 단계가 넘어가는 것은 게이지가 차오르는 것보다 짧아야 다음 화면을
      // 기다리는 느낌이 안 난다.
      duration: AppMotion.normal,
      curve: AppMotion.standard,
    );

    if (!showLabel) return bar;

    return Row(
      children: [
        Expanded(child: bar),
        const SizedBox(width: 8),
        StandardText(
          text: '$currentStep / $totalSteps',
          fontSize: 11,
          color: labelColor ?? Colors.grey[500]!,
          fontWeight: FontWeight.normal,
          fontFamily: 'PretendardLight',
        ),
      ],
    );
  }
}
