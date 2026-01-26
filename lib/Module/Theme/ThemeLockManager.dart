import 'package:flutter/material.dart';

import '../../Model/User/UserInfoModel.dart';

/// 테마 잠금 해제 관리 클래스
/// GridView 24개 항목 (4열 6행):
/// - 1, 5, 9, 13, 17, 21: 출석 레벨 기반
/// - 2, 6, 10, 14, 18, 22: 오답노트 작성 레벨 기반
/// - 3, 7, 11, 15, 19, 23: 오답노트 복습 레벨 기반
/// - 4, 8, 12, 16, 20, 24: 복습노트 복습 레벨 기반
/// - 첫 행(1-4번)은 기본적으로 모두 잠금 해제
class ThemeLockManager {
  // 각 테마의 색상 (원래 ThemeDialog 순서 그대로)
  static final List<Color> themeColors = [
    // 1행 (기본 해제)
    Colors.pink[200]!, // 1. 연핑크
    Colors.pink[400]!, // 2. 진핑크
    Colors.purple[300]!, // 3. 라일락
    Colors.purple[700]!, // 4. 보라색

    // 2행 (레벨 3)
    Colors.red[500]!, // 5. 빨간색
    Colors.yellow[900]!, // 6. 황금색
    Colors.orange[300]!, // 7. 오렌지색
    Colors.yellow[600]!, // 8. 노란색

    // 3행 (레벨 6)
    Colors.lightGreen, // 9. 라이트그린
    Colors.green[500]!, // 10. 초록색
    Colors.green[700]!, // 11. 다크그린
    Colors.green[900]!, // 12. 딥그린

    // 4행 (레벨 9)
    Colors.cyan, // 13. 시안
    Colors.blue[700]!, // 14. 블루
    Colors.indigo, // 15. 인디고
    Colors.indigo[900]!, // 16. 딥인디고

    // 5행 (레벨 12)
    const Color(0xFFC8B68A), // 17. 베이지
    const Color(0xFF7A6748), // 18. 브론즈
    Colors.brown[500]!, // 19. 브라운
    Colors.brown[800]!, // 20. 다크브라운

    // 6행 (레벨 15)
    Colors.grey[400]!, // 21. 라이트그레이
    Colors.grey[600]!, // 22. 그레이
    Colors.grey[800]!, // 23. 다크그레이
    Colors.black, // 24. 블랙
  ];

  // 각 테마의 이름 (원래 ThemeDialog 순서 그대로)
  static const List<String> themeNames = [
    '연핑크',
    '진핑크',
    '라일락',
    '보라색',
    '빨간색',
    '황금색',
    '오렌지색',
    '노란색',
    '라이트그린',
    '초록색',
    '다크그린',
    '딥그린',
    '시안',
    '블루',
    '인디고',
    '딥인디고',
    '베이지',
    '브론즈',
    '브라운',
    '다크브라운',
    '라이트그레이',
    '그레이',
    '다크그레이',
    '블랙',
  ];

  /// 인덱스로 카테고리(열) 구하기
  /// 1, 5, 9, 13, 17, 21 → 0 (출석)
  /// 2, 6, 10, 14, 18, 22 → 1 (노트작성)
  /// 3, 7, 11, 15, 19, 23 → 2 (오답복습)
  /// 4, 8, 12, 16, 20, 24 → 3 (복습노트)
  static int getCategoryIndex(int themeIndex) {
    return themeIndex % 4;
  }

  /// 인덱스로 행 번호 구하기 (0-5)
  static int getRowIndex(int themeIndex) {
    return themeIndex ~/ 4;
  }

  /// 행별 필요 레벨 반환
  /// 0행: 레벨 0 (기본 해제)
  /// 1행: 레벨 3
  /// 2행: 레벨 6
  /// 3행: 레벨 9
  /// 4행: 레벨 12
  /// 5행: 레벨 15
  static int getRequiredLevel(int rowIndex) {
    if (rowIndex == 0) return 0;
    return 3 * rowIndex;
  }

  /// 특정 테마가 잠금 해제되었는지 확인
  /// [themeIndex]: 0-23 (GridView 인덱스)
  /// [userInfo]: 유저 정보
  static bool isThemeUnlocked(int themeIndex, UserInfoModel? userInfo) {
    int categoryIndex = getCategoryIndex(themeIndex);
    int rowIndex = getRowIndex(themeIndex);

    // 첫 행은 항상 잠금 해제
    if (rowIndex == 0) return true;

    // 유저 정보가 없으면 잠금
    if (userInfo == null) return false;

    int requiredLevel = getRequiredLevel(rowIndex);
    int userLevel;

    switch (categoryIndex) {
      case 0: // 출석 레벨 (1, 5, 9, 13, 17, 21)
        userLevel = userInfo.attendanceLevel;
        break;
      case 1: // 오답노트 작성 레벨 (2, 6, 10, 14, 18, 22)
        userLevel = userInfo.noteWriteLevel;
        break;
      case 2: // 오답노트 복습 레벨 (3, 7, 11, 15, 19, 23)
        userLevel = userInfo.problemPracticeLevel;
        break;
      case 3: // 복습노트 복습 레벨 (4, 8, 12, 16, 20, 24)
        userLevel = userInfo.notePracticeLevel;
        break;
      default:
        return false;
    }

    return userLevel >= requiredLevel;
  }

  /// 테마 색상 가져오기
  static Color getThemeColor(int themeIndex) {
    return themeColors[themeIndex];
  }

  /// 테마 이름 가져오기
  static String getThemeName(int themeIndex) {
    return themeNames[themeIndex];
  }

  /// 카테고리 이름 가져오기
  static String getCategoryName(int categoryIndex) {
    switch (categoryIndex) {
      case 0:
        return '출석';
      case 1:
        return '오답노트 작성';
      case 2:
        return '문제 복습';
      case 3:
        return '복습노트 복습';
      default:
        return '';
    }
  }

  /// 필요 레벨 메시지 생성
  static String getRequiredLevelMessage(
      int themeIndex, UserInfoModel? userInfo) {
    int categoryIndex = getCategoryIndex(themeIndex);
    int rowIndex = getRowIndex(themeIndex);
    int requiredLevel = getRequiredLevel(rowIndex);

    if (rowIndex == 0) return '잠금 해제됨';

    String categoryName = getCategoryName(categoryIndex);
    int currentLevel = 0;

    if (userInfo != null) {
      switch (categoryIndex) {
        case 0:
          currentLevel = userInfo.attendanceLevel;
          break;
        case 1:
          currentLevel = userInfo.noteWriteLevel;
          break;
        case 2:
          currentLevel = userInfo.problemPracticeLevel;
          break;
        case 3:
          currentLevel = userInfo.notePracticeLevel;
          break;
      }
    }

    if (currentLevel >= requiredLevel) {
      return '잠금 해제됨';
    }

    return '$categoryName Lv.$requiredLevel 필요\n(현재 ${categoryName} 레벨: Lv.$currentLevel)';
  }
}
