import 'package:flutter/material.dart';

import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Design/AppSpacing.dart';
import '../../../Module/Text/StandardText.dart';
import '../../Mission/MissionPalette.dart';

/// 능력치 하나를 **어떻게 올리는지** 알려 주는 시트다.
///
/// 스탯창의 눈금판은 지금 어디에 서 있는지를 말해 주지만, 무엇을 해야 저 고리가
/// 차는지는 말해 주지 않았다. 미션 화면까지 가서 목록을 훑어야 짐작할 수
/// 있었고, 미션은 그날그날 바뀌어서 목록을 봐도 규칙은 안 보였다.
///
/// **여기 적힌 것은 미션이 아니라 적립 규칙이다.** 미션을 하나도 안 받아도
/// 행동 자체로 쌓이는 점수이고, 서버의 `MissionType` 과 `MissionLogService`
/// 가 정한다. 숫자를 바꿀 일이 생기면 그쪽을 먼저 고치고 [_guides] 를 맞춘다.
class AbilityGuideSheet extends StatelessWidget {
  final MissionKind kind;

  const AbilityGuideSheet({super.key, required this.kind});

  /// 능력치마다 어떻게 오르는지.
  ///
  /// 서버 `MissionType` 의 점수와 `MissionLogService` 의 중복 방지 규칙을 그대로
  /// 옮긴 것이다. 중복 방지가 능력치마다 달라서(출석은 하루 한 번, 오답노트는
  /// 하루 세 개, 복습은 문제마다 한 번) 점수만 적으면 실제로 얼마나 오를지
  /// 알 수 없다. 한도까지 같이 적는다.
  static const Map<MissionKind, _AbilityGuide> _guides = {
    MissionKind.attendance: _AbilityGuide(
      how: '하루에 한 번 앱을 열면',
      point: 15,
      limit: '하루 한 번까지',
      hint: '오늘 들어온 것만으로 쌓여요. 몇 번을 열어도 하루치는 한 번이에요.',
    ),
    MissionKind.noteWrite: _AbilityGuide(
      how: '오답노트를 한 개 등록하면',
      point: 10,
      limit: '하루 세 개까지',
      hint: '한 번에 여러 개를 올려도 하루에 세 개까지만 쌓여요.',
    ),
    MissionKind.problemPractice: _AbilityGuide(
      how: '문제를 한 개 복습하면',
      point: 5,
      limit: '문제마다 한 번까지',
      hint: '같은 문제를 다시 풀어도 처음 한 번만 쌓여요. 새 문제를 풀면 또 쌓여요.',
    ),
    MissionKind.notePractice: _AbilityGuide(
      how: '복습 세트를 한 개 끝내면',
      point: 15,
      limit: '세트마다 한 번까지',
      hint: '같은 세트를 다시 끝내도 처음 한 번만 쌓여요.',
    ),
    MissionKind.etc: _AbilityGuide(
      how: '앱을 쓰면',
      point: 0,
      limit: '',
      hint: '',
    ),
  };

  /// 하루에 쌓을 수 있는 점수의 총합. 서버의 `DAILY_MISSION_POINT_LIMIT` 이다.
  static const int dailyPointLimit = 200;

  @override
  Widget build(BuildContext context) {
    final guide = _guides[kind]!;
    final colors = MissionPalette.of(kind);
    final label = MissionPalette.labelOfKind(kind);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.cardPadding,
        AppSpacing.sm,
        AppSpacing.cardPadding,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(label, colors),
          const SizedBox(height: AppSpacing.xl),
          _buildRule(guide, colors),
          const SizedBox(height: AppSpacing.xl),
          _buildFacts(guide, colors),
        ],
      ),
    );
  }

  /// 제목 줄. 능력치 아이콘과 이름을 그 색으로 물들인다.
  ///
  /// 어느 눈금판을 눌러서 열린 시트인지가 색으로 바로 읽혀야 한다. 넷이 같은
  /// 모양이라 이름만으로는 잘못 눌렀는지 알기 어렵다.
  Widget _buildTitle(String label, MissionKindColors colors) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            MissionPalette.iconOfKind(kind),
            color: colors.accent,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StandardText(
            text: '$label 올리는 법',
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.3,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  /// 규칙 한 덩어리. `무엇을 하면` + `몇 점` + `얼마까지`.
  ///
  /// **숫자를 제일 먼저 보게 한다.** 이 시트를 여는 사람이 알고 싶은 것은
  /// 대체로 "얼마나 쌓이나" 하나다. 점수를 크게 세우고 조건을 그 아래 칩으로
  /// 붙인다. 한도가 문장 속에 묻혀 있으면 점수만 읽고 닫는다.
  Widget _buildRule(_AbilityGuide guide, MissionKindColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          StandardText(
            text: guide.how,
            fontSize: 13,
            color: AppColors.textSecondary,
            fontFamily: 'PretendardLight',
            height: 1.5,
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.sm),
          // 글자를 키운 기기에서 큰 숫자가 한 줄을 넘는다. 줄여서 앉힌다.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: StandardText(
              text: '+${guide.point}점',
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: colors.accent,
              height: 1.15,
              maxLines: 1,
            ),
          ),
          if (guide.limit.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _buildChip(guide.limit, colors),
          ],
        ],
      ),
    );
  }

  /// 한도를 담는 알약. 규칙 칸 안에서 점수 아래에 앉는다.
  Widget _buildChip(String text, MissionKindColors colors) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: StandardText(
          text: text,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colors.accent,
          height: 1.3,
          maxLines: 1,
        ),
      ),
    );
  }

  /// 알아 둘 것 몇 줄.
  ///
  /// **한 줄에 한 가지만 적는다.** 예전에는 설명 셋이 같은 크기 회색 글자로
  /// 붙어 있어서 세 문단이 한 덩어리로 보였다. 줄마다 여백을 벌리고 앞에
  /// 그 능력치 색의 점을 찍어 어디가 한 줄의 시작인지 눈으로 짚이게 한다.
  Widget _buildFacts(_AbilityGuide guide, MissionKindColors colors) {
    final facts = <String>[
      if (guide.hint.isNotEmpty) guide.hint,
      '다음 레벨까지 필요한 점수는 레벨이 오를수록 10점씩 늘어나요.',
      '능력치 넷을 다 합쳐 하루에 $dailyPointLimit점까지 쌓여요.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < facts.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.lg),
          _buildFact(facts[index], colors),
        ],
      ],
    );
  }

  Widget _buildFact(String text, MissionKindColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: colors.accent,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StandardText(
            text: text,
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.normal,
            fontFamily: 'PretendardLight',
            // 빽빽하다는 말의 대부분이 여기서 왔다. 설명 줄은 두 줄로 넘어가는
            // 일이 잦은데 줄 사이가 좁으면 글자가 뭉쳐 보인다.
            height: 1.65,
            maxLines: 3,
          ),
        ),
      ],
    );
  }
}

/// 능력치 하나의 적립 규칙.
class _AbilityGuide {
  /// 무엇을 하면 쌓이는지.
  final String how;

  /// 한 번에 쌓이는 점수.
  final int point;

  /// 얼마나 자주 쌓을 수 있는지. 빈 문자열이면 한도가 없다.
  final String limit;

  /// 헷갈리기 쉬운 것 한 줄. 빈 문자열이면 줄을 두지 않는다.
  final String hint;

  const _AbilityGuide({
    required this.how,
    required this.point,
    required this.limit,
    required this.hint,
  });
}
