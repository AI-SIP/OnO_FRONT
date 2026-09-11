/// 치장을 여는 능력치다.
///
/// 서버 응답의 `requiredAbility` 에 실려 오는 값과 같다. **비어 있으면 총 학습
/// 레벨**을 본다. 그래서 이 enum 에 `총 학습` 항목을 두지 않았다. 넷은 각자
/// 따로 오르는 값이고 총 학습은 그 넷을 합산해 오르는 값이라, 같은 목록에
/// 섞어 두면 "다섯 중 하나"처럼 읽힌다.
enum CosmeticAbility {
  /// 출석. 하루 첫 로그인.
  attendance('ATTENDANCE'),

  /// 오답노트 작성.
  noteWrite('NOTE_WRITE'),

  /// 문제 복습.
  problemPractice('PROBLEM_PRACTICE'),

  /// 복습 세트 복습.
  notePractice('NOTE_PRACTICE');

  const CosmeticAbility(this.key);

  /// 서버가 쓰는 값.
  final String key;

  /// 서버 값으로 능력치를 찾는다.
  ///
  /// 비어 있으면 null 이고 **그 뜻은 총 학습 레벨**이다. 앱이 모르는 값이
  /// 와도 null 로 떨어뜨린다. 새 능력치가 생겼다고 옷장이 안 뜨는 쪽이 더
  /// 나쁘다. 그 경우 화면에는 총 학습 레벨 조건으로 적히는데, 그때는 서버가
  /// 앞서 나간 것이므로 앱을 올리면 맞춰진다.
  static CosmeticAbility? fromKeyOrNull(Object? value) {
    if (value is! String || value.isEmpty) return null;
    for (final ability in values) {
      if (ability.key == value) return ability;
    }
    return null;
  }
}

/// 능력치 넷과 총 학습 레벨을 한 묶음으로 들고 있는 값이다.
///
/// 해금 기준이 **총 학습 레벨 하나에서 능력치별로 바뀌면서**, 아이템 하나가
/// 열렸는지 알려면 레벨 하나로는 모자라게 됐다. 이 다섯을 같이 넘겨야
/// [CosmeticItemModel.isUnlockedAt] 이 답을 낼 수 있다.
///
/// 다섯을 따로따로 인자로 넘기지 않고 묶은 이유는, 넘기는 자리가 늘어날수록
/// 순서를 잘못 적는 실수가 늘기 때문이다. 값 하나면 그럴 일이 없다.
class CosmeticAbilityLevels {
  /// 능력치 넷의 상한.
  static const int maxAbility = 15;

  /// 총 학습 레벨의 상한. 넷을 합산해 오르는 값이라 더 높다.
  static const int maxTotalStudy = 20;

  /// 모든 레벨의 하한. Lv.0 인 사람은 없다.
  static const int minLevel = 1;

  final int attendance;
  final int noteWrite;
  final int problemPractice;
  final int notePractice;
  final int totalStudy;

  const CosmeticAbilityLevels._({
    required this.attendance,
    required this.noteWrite,
    required this.problemPractice,
    required this.notePractice,
    required this.totalStudy,
  });

  /// 다섯을 따로 준다. 상한과 하한을 벗어나면 잘린다.
  factory CosmeticAbilityLevels({
    int attendance = minLevel,
    int noteWrite = minLevel,
    int problemPractice = minLevel,
    int notePractice = minLevel,
    int totalStudy = minLevel,
  }) {
    return CosmeticAbilityLevels._(
      attendance: _clamp(attendance, maxAbility),
      noteWrite: _clamp(noteWrite, maxAbility),
      problemPractice: _clamp(problemPractice, maxAbility),
      notePractice: _clamp(notePractice, maxAbility),
      totalStudy: _clamp(totalStudy, maxTotalStudy),
    );
  }

  /// 다섯을 같은 값으로 놓는다. 상한이 달라서 총 학습만 더 올라갈 수 있다.
  ///
  /// "레벨이 오를수록 무엇이 열리나"를 한 축으로 훑어 보는 자리에서 쓴다.
  /// 실제 사용자의 다섯 레벨이 나란히 오르지는 않는다.
  factory CosmeticAbilityLevels.uniform(int level) => CosmeticAbilityLevels(
        attendance: level,
        noteWrite: level,
        problemPractice: level,
        notePractice: level,
        totalStudy: level,
      );

  /// 아직 아무것도 안 오른 사람.
  static const CosmeticAbilityLevels start = CosmeticAbilityLevels._(
    attendance: minLevel,
    noteWrite: minLevel,
    problemPractice: minLevel,
    notePractice: minLevel,
    totalStudy: minLevel,
  );

  /// 다섯을 전부 끝까지 올린 사람. 모든 치장이 열린다.
  static const CosmeticAbilityLevels max = CosmeticAbilityLevels._(
    attendance: maxAbility,
    noteWrite: maxAbility,
    problemPractice: maxAbility,
    notePractice: maxAbility,
    totalStudy: maxTotalStudy,
  );

  /// 이 능력치의 지금 레벨. null 이면 총 학습 레벨이다.
  int levelOf(CosmeticAbility? ability) => switch (ability) {
        CosmeticAbility.attendance => attendance,
        CosmeticAbility.noteWrite => noteWrite,
        CosmeticAbility.problemPractice => problemPractice,
        CosmeticAbility.notePractice => notePractice,
        null => totalStudy,
      };

  /// 이 능력치가 올라갈 수 있는 끝. null 이면 총 학습 레벨의 끝이다.
  static int maxLevelOf(CosmeticAbility? ability) =>
      ability == null ? maxTotalStudy : maxAbility;

  /// 이 능력치만 갈아 끼운 새 묶음. null 이면 총 학습 레벨을 바꾼다.
  CosmeticAbilityLevels withLevel(CosmeticAbility? ability, int level) {
    return switch (ability) {
      CosmeticAbility.attendance => CosmeticAbilityLevels(
          attendance: level,
          noteWrite: noteWrite,
          problemPractice: problemPractice,
          notePractice: notePractice,
          totalStudy: totalStudy,
        ),
      CosmeticAbility.noteWrite => CosmeticAbilityLevels(
          attendance: attendance,
          noteWrite: level,
          problemPractice: problemPractice,
          notePractice: notePractice,
          totalStudy: totalStudy,
        ),
      CosmeticAbility.problemPractice => CosmeticAbilityLevels(
          attendance: attendance,
          noteWrite: noteWrite,
          problemPractice: level,
          notePractice: notePractice,
          totalStudy: totalStudy,
        ),
      CosmeticAbility.notePractice => CosmeticAbilityLevels(
          attendance: attendance,
          noteWrite: noteWrite,
          problemPractice: problemPractice,
          notePractice: level,
          totalStudy: totalStudy,
        ),
      null => CosmeticAbilityLevels(
          attendance: attendance,
          noteWrite: noteWrite,
          problemPractice: problemPractice,
          notePractice: notePractice,
          totalStudy: level,
        ),
    };
  }

  static int _clamp(int level, int max) {
    if (level < minLevel) return minLevel;
    if (level > max) return max;
    return level;
  }

  @override
  bool operator ==(Object other) {
    return other is CosmeticAbilityLevels &&
        other.attendance == attendance &&
        other.noteWrite == noteWrite &&
        other.problemPractice == problemPractice &&
        other.notePractice == notePractice &&
        other.totalStudy == totalStudy;
  }

  @override
  int get hashCode => Object.hash(
        attendance,
        noteWrite,
        problemPractice,
        notePractice,
        totalStudy,
      );

  @override
  String toString() => 'CosmeticAbilityLevels(출석 $attendance, 오답노트 $noteWrite, '
      '문제 복습 $problemPractice, 복습 세트 $notePractice, 총 학습 $totalStudy)';
}
