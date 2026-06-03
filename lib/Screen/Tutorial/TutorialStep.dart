import 'package:flutter/material.dart';

import 'TutorialTargets.dart';

enum TutorialLaunchSource {
  firstSignup,
  settingsReplay,
}

enum TutorialStatus {
  idle,
  intro,
  running,
}

enum TutorialTargetType {
  folderList,
  directoryCreateFab,
  practiceCreateFab,
  levelCard,
  calendarCard,
  reportCard,
}

class TutorialStep {
  final String id;
  final int tabIndex;
  final TutorialTargetType targetType;
  final String title;
  final String description;

  const TutorialStep({
    required this.id,
    required this.tabIndex,
    required this.targetType,
    required this.title,
    required this.description,
  });
}

const int currentTutorialVersion = 1;

const List<TutorialStep> tutorialSteps = [
  TutorialStep(
    id: 'folder_unit',
    tabIndex: 0,
    targetType: TutorialTargetType.folderList,
    title: '공책과 오답노트',
    description: '공책은 오답노트를 담는 폴더예요. 과목이나 시험 범위별로 나눠 관리할 수 있어요.',
  ),
  TutorialStep(
    id: 'create_problem_note',
    tabIndex: 0,
    targetType: TutorialTargetType.directoryCreateFab,
    title: '오답노트 작성 시작',
    description:
        '+ 추가 버튼에서 공책을 만들거나 오답노트를 작성할 수 있어요. 여러 장 작성으로 이미지를 한 번에 등록할 수도 있어요.',
  ),
  TutorialStep(
    id: 'practice_set',
    tabIndex: 1,
    targetType: TutorialTargetType.practiceCreateFab,
    title: '복습 세트',
    description: '복습 세트는 여러 오답노트를 묶어 다시 푸는 공간이에요. 시험 전에 필요한 문제만 골라 반복할 수 있어요.',
  ),
  TutorialStep(
    id: 'level',
    tabIndex: 2,
    targetType: TutorialTargetType.levelCard,
    title: '레벨과 성장',
    description: '출석, 오답노트 작성, 문제 복습이 쌓이면 레벨과 포인트가 올라요.',
  ),
  TutorialStep(
    id: 'calendar',
    tabIndex: 2,
    targetType: TutorialTargetType.calendarCard,
    title: '학습 달력',
    description: '공부한 날과 복습 기록을 달력에서 확인해요. 며칠 동안 꾸준히 공부했는지도 볼 수 있어요.',
  ),
  TutorialStep(
    id: 'report',
    tabIndex: 2,
    targetType: TutorialTargetType.reportCard,
    title: '복습 리포트',
    description: '복습 추이와 약점을 확인하고, 설정에서는 테마 변경과 튜토리얼 다시 보기를 할 수 있어요.',
  ),
];

extension TutorialTargetResolver on TutorialTargetType {
  GlobalKey resolve(TutorialTargets targets) {
    switch (this) {
      case TutorialTargetType.folderList:
        return targets.folderListKey;
      case TutorialTargetType.directoryCreateFab:
        return targets.directoryCreateFabKey;
      case TutorialTargetType.practiceCreateFab:
        return targets.practiceCreateFabKey;
      case TutorialTargetType.levelCard:
        return targets.levelCardKey;
      case TutorialTargetType.calendarCard:
        return targets.calendarCardKey;
      case TutorialTargetType.reportCard:
        return targets.reportCardKey;
    }
  }
}
