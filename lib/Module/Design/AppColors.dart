import 'package:flutter/material.dart';

/// 앱이 쓰는 중성색이다.
///
/// 그동안 `Colors.grey[200]` 부터 `Colors.grey[800]` 까지 열 가지가 화면마다
/// 다르게 쓰였다. 같은 자리인데 어떤 화면은 300, 어떤 화면은 400 이라 미묘하게
/// 어긋나 보였다. 쓰임새로 이름을 붙여 고를 여지를 줄인다.
///
/// 강조색은 여기 없다. 사용자가 테마에서 고른 색을 그대로 쓰기 때문에
/// `ThemeHandler.primaryColor` 를 계속 쓴다.
abstract final class AppColors {
  // ── 글자 ──────────────────────────────────────────────────

  /// 제목과 본문. 순검정보다 살짝 부드럽다.
  static const Color textPrimary = Color(0xFF191F28);

  /// 설명과 보조 문구.
  static const Color textSecondary = Color(0xFF4E5968);

  /// 날짜, 개수처럼 옅게 두는 것.
  static const Color textTertiary = Color(0xFF8B95A1);

  /// 입력칸의 안내 문구, 비활성 글자.
  static const Color textDisabled = Color(0xFFB0B8C1);

  // ── 면 ───────────────────────────────────────────────────

  /// 카드와 시트의 바탕.
  static const Color surface = Color(0xFFFFFFFF);

  /// 화면 바탕. 카드가 흰색이라 아주 옅게 깐다.
  static const Color background = Color(0xFFF9FAFB);

  /// 눌린 상태나 비활성 버튼처럼 한 단계 눌러 둔 면.
  static const Color surfaceMuted = Color(0xFFF2F4F6);

  // ── 선 ───────────────────────────────────────────────────

  /// 구분선과 아주 옅은 테두리.
  static const Color border = Color(0xFFE5E8EB);

  /// 입력칸처럼 경계가 분명해야 하는 곳.
  static const Color borderStrong = Color(0xFFD1D6DB);
}
