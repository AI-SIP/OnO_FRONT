// 테마 해금 규칙 잠금 테스트.
//
// 테마 고르는 창의 디자인을 갈아엎으면서 **보여 주는 방식만** 바꾸기로 했다.
// 어떤 테마가 몇 레벨에 열리는지는 그대로다. 화면 쪽에서 필요 레벨을 다시
// 계산하다가 규칙이 두 벌이 되는 일이 제일 위험하므로, 규칙을 여기서 통째로
// 못 박아 둔다. 이 파일이 깨지면 사용자가 갖고 있던 색이 사라지거나 없던
// 색이 생긴 것이다.
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Module/Theme/ThemeLockManager.dart';

/// 능력치 넷의 레벨만 바꿔 끼운 유저.
UserInfoModel _user({
  int attendance = 1,
  int noteWrite = 1,
  int problemPractice = 1,
  int notePractice = 1,
}) {
  return UserInfoModel(
    userId: 1,
    attendanceLevel: attendance,
    noteWriteLevel: noteWrite,
    problemPracticeLevel: problemPractice,
    notePracticeLevel: notePractice,
  );
}

void main() {
  group('격자 모양', () {
    test('4열 6행 24칸이고 색과 이름의 개수가 그만큼이다', () {
      expect(ThemeLockManager.categoryCount, 4);
      expect(ThemeLockManager.tierCount, 6);
      expect(ThemeLockManager.themeCount, 24);
      expect(ThemeLockManager.themeColors.length, 24);
      expect(ThemeLockManager.themeNames.length, 24);
    });

    test('themeIndexAt 은 getRowIndex/getCategoryIndex 의 반대 방향이다', () {
      for (var index = 0; index < ThemeLockManager.themeCount; index++) {
        final row = ThemeLockManager.getRowIndex(index);
        final category = ThemeLockManager.getCategoryIndex(index);

        expect(ThemeLockManager.themeIndexAt(row, category), index);
      }
    });

    test('열은 능력치 넷이고 이름이 바뀌지 않는다', () {
      expect(ThemeLockManager.getCategoryName(0), '출석');
      expect(ThemeLockManager.getCategoryName(1), '오답노트 작성');
      expect(ThemeLockManager.getCategoryName(2), '문제 복습');
      expect(ThemeLockManager.getCategoryName(3), '복습 세트 복습');
    });
  });

  group('단계별 필요 레벨', () {
    test('첫 행은 0 이고 그다음부터 3의 배수다', () {
      expect(
        [
          for (var row = 0; row < 6; row++)
            ThemeLockManager.getRequiredLevel(row)
        ],
        [0, 3, 6, 9, 12, 15],
      );
    });

    test('단계 이름은 첫 행만 기본이고 나머지는 필요 레벨을 그대로 쓴다', () {
      expect(
        [for (var row = 0; row < 6; row++) ThemeLockManager.getTierLabel(row)],
        ['기본', 'Lv.3', 'Lv.6', 'Lv.9', 'Lv.12', 'Lv.15'],
      );
    });
  });

  group('isThemeUnlocked', () {
    test('첫 행 네 칸은 유저 정보가 없어도 열려 있다', () {
      for (var category = 0; category < 4; category++) {
        expect(
          ThemeLockManager.isThemeUnlocked(
            ThemeLockManager.themeIndexAt(0, category),
            null,
          ),
          isTrue,
        );
      }
    });

    test('유저 정보가 없으면 둘째 행부터는 전부 잠긴다', () {
      for (var index = 4; index < ThemeLockManager.themeCount; index++) {
        expect(
          ThemeLockManager.isThemeUnlocked(index, null),
          isFalse,
          reason: '$index 번이 열려 있다',
        );
      }
    });

    test('능력치를 올리면 그 열만 열린다', () {
      // 출석만 9. 출석 열은 Lv.9 행까지 열리고 나머지 열은 첫 행만 열린다.
      final user = _user(attendance: 9);

      for (var row = 0; row < ThemeLockManager.tierCount; row++) {
        for (var category = 0; category < 4; category++) {
          final index = ThemeLockManager.themeIndexAt(row, category);
          final expected = row == 0 || (category == 0 && row <= 3);

          expect(
            ThemeLockManager.isThemeUnlocked(index, user),
            expected,
            reason: '$row 행 $category 열이 기대와 다르다',
          );
        }
      }
    });

    test('레벨이 필요 레벨과 같으면 열린다 (경계값)', () {
      expect(
        ThemeLockManager.isThemeUnlocked(
          ThemeLockManager.themeIndexAt(1, 1),
          _user(noteWrite: 3),
        ),
        isTrue,
      );
      expect(
        ThemeLockManager.isThemeUnlocked(
          ThemeLockManager.themeIndexAt(1, 1),
          _user(noteWrite: 2),
        ),
        isFalse,
      );
    });

    test('모든 능력치가 15면 24칸이 전부 열린다', () {
      final user = _user(
        attendance: 15,
        noteWrite: 15,
        problemPractice: 15,
        notePractice: 15,
      );

      for (var index = 0; index < ThemeLockManager.themeCount; index++) {
        expect(ThemeLockManager.isThemeUnlocked(index, user), isTrue);
      }
    });
  });

  group('getCurrentLevel', () {
    test('열 번호대로 능력치를 집어 온다', () {
      final user = _user(
        attendance: 2,
        noteWrite: 4,
        problemPractice: 6,
        notePractice: 8,
      );

      expect(ThemeLockManager.getCurrentLevel(0, user), 2);
      expect(ThemeLockManager.getCurrentLevel(1, user), 4);
      expect(ThemeLockManager.getCurrentLevel(2, user), 6);
      expect(ThemeLockManager.getCurrentLevel(3, user), 8);
    });

    test('유저 정보가 없으면 0 으로 본다', () {
      // isThemeUnlocked 가 유저 정보 없을 때를 잠금으로 보는 것과 같은 기준.
      for (var category = 0; category < 4; category++) {
        expect(ThemeLockManager.getCurrentLevel(category, null), 0);
      }
    });
  });

  group('getRemainingLevel', () {
    test('열려 있는 칸은 0 이다', () {
      final user = _user(attendance: 9);

      expect(
        ThemeLockManager.getRemainingLevel(
          ThemeLockManager.themeIndexAt(3, 0),
          user,
        ),
        0,
      );
      expect(ThemeLockManager.getRemainingLevel(0, null), 0);
    });

    test('잠긴 칸은 필요 레벨에서 지금 레벨을 뺀 만큼이다', () {
      final user = _user(attendance: 4);

      // 출석 Lv.9 칸. 지금 4 라서 5 남았다.
      expect(
        ThemeLockManager.getRemainingLevel(
          ThemeLockManager.themeIndexAt(3, 0),
          user,
        ),
        5,
      );
    });

    test('유저 정보가 없으면 필요 레벨 전부가 남은 것이다', () {
      expect(
        ThemeLockManager.getRemainingLevel(
          ThemeLockManager.themeIndexAt(5, 2),
          null,
        ),
        15,
      );
    });
  });

  group('getRequiredLevelMessage', () {
    test('첫 행과 이미 연 칸은 해제됨으로 답한다', () {
      expect(ThemeLockManager.getRequiredLevelMessage(0, null), '잠금 해제됨');
      expect(
        ThemeLockManager.getRequiredLevelMessage(4, _user(attendance: 3)),
        '잠금 해제됨',
      );
    });

    test('잠긴 칸은 능력치 이름과 필요·현재 레벨을 말해 준다', () {
      expect(
        ThemeLockManager.getRequiredLevelMessage(4, _user(attendance: 1)),
        '출석 Lv.3 필요\n(현재 출석 레벨: Lv.1)',
      );
    });
  });
}
