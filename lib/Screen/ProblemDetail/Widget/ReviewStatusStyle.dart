import 'package:flutter/material.dart';

import '../../../Model/Problem/AnswerStatus.dart';

/// 복습 정답 여부별 색과 아이콘이다. 회차 카드와 복습 추이 판이 같이 쓴다.
abstract final class ReviewStatusStyle {
  /// 테두리, 칠, 아이콘에 쓰는 색이다.
  static Color color(AnswerStatus status) {
    switch (status) {
      case AnswerStatus.CORRECT:
        return Colors.green;
      case AnswerStatus.PARTIAL:
        return Colors.orange;
      case AnswerStatus.WRONG:
        return Colors.red;
      case AnswerStatus.UNKNOWN:
        return Colors.grey;
    }
  }

  /// 흰 바탕 위 글씨 색이다. [color] 를 글씨에 그대로 쓰면 주황과 초록이
  /// 대비 4.5 대 1 을 못 넘어서 한 단계 진하게 둔다.
  static Color textColor(AnswerStatus status) {
    switch (status) {
      case AnswerStatus.CORRECT:
        return const Color(0xFF2E7D32);
      case AnswerStatus.PARTIAL:
        return const Color(0xFFB45309);
      case AnswerStatus.WRONG:
        return const Color(0xFFC62828);
      case AnswerStatus.UNKNOWN:
        return const Color(0xFF616161);
    }
  }

  static IconData icon(AnswerStatus status) {
    switch (status) {
      case AnswerStatus.CORRECT:
        return Icons.check_circle;
      case AnswerStatus.PARTIAL:
        return Icons.radio_button_checked;
      case AnswerStatus.WRONG:
        return Icons.cancel;
      case AnswerStatus.UNKNOWN:
        return Icons.help;
    }
  }
}
