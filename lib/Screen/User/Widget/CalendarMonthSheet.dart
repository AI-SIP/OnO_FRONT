import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Model/StudyCalendar/StudyCalendarModel.dart';
import '../../../Module/Emoji/OnoEmojiImage.dart';
import '../../../Module/Motion/AppHaptic.dart';
import '../../../Module/Motion/AppMotion.dart';
import '../../../Module/Motion/AppearTransition.dart';
import '../../../Module/Motion/PressableScale.dart';
import '../../../Module/User/ProfileAvatar.dart';
import '../../../Provider/CosmeticProvider.dart';
import '../../../Provider/UserProvider.dart';
import 'DiaryTheme.dart';

/// 학습 달력 일기장의 첫 장. 내 프로필과 이번 달 기록 세 문장, 월 이동,
/// 한 달 달력이 한 장에 들어간다.
///
/// 전에는 통계 카드 두 개와 진행 막대가 따로 있었는데, 위젯과 같은 일기장
/// 모양으로 바꾸면서 숫자는 머리 문장 세 줄로 옮겼다. 데이터는 화면이 불러 온
/// [StudyCalendarModel] 을 그대로 받아 그리기만 한다.
class CalendarMonthSheet extends StatelessWidget {
  final DiaryInk ink;
  final int year;
  final int month;

  /// 오늘. 테스트에서 날짜를 고정할 수 있게 밖에서 받는다.
  final DateTime today;

  /// 달력 조회 결과. 불러오지 못했으면 null 이고, 그때는 칸에 숫자만 적는다.
  final StudyCalendarModel? data;

  final int? selectedDay;

  /// 이 달에서 일기를 쓴 날들.
  final Set<int> diaryDays;

  /// 칸을 크게 그릴지. 태블릿이면 켠다.
  final bool large;

  final VoidCallback onPrevMonth;

  /// 다음 달이 미래라 넘어갈 수 없으면 null 이다.
  final VoidCallback? onNextMonth;

  final VoidCallback onPickMonth;
  final ValueChanged<int> onDayTap;
  final VoidCallback onRetry;

  const CalendarMonthSheet({
    super.key,
    required this.ink,
    required this.year,
    required this.month,
    required this.today,
    required this.data,
    required this.selectedDay,
    required this.diaryDays,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onPickMonth,
    required this.onDayTap,
    required this.onRetry,
    this.large = false,
  });

  static const Key prevMonthKey = Key('calendar_prev_month');
  static const Key nextMonthKey = Key('calendar_next_month');
  static const Key monthLabelKey = Key('calendar_month_label');
  static const Key retryKey = Key('calendar_retry');

  /// 날짜 칸. 이 안에 표시마다 아래 키를 단 조각이 들어간다.
  static Key dayKey(int day) => Key('calendar_day_$day');
  static Key studiedKey(int day) => Key('calendar_day_${day}_studied');
  static Key todayKey(int day) => Key('calendar_day_${day}_today');
  static Key selectedKey(int day) => Key('calendar_day_${day}_selected');
  static Key moodKey(int day) => Key('calendar_day_${day}_mood');
  static Key diaryKey(int day) => Key('calendar_day_${day}_diary');

  bool get _isCurrentMonth => year == today.year && month == today.month;

  @override
  Widget build(BuildContext context) {
    return DiarySheet(
      edgeColor: ink.edge,
      tapeColor: ink.tape,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHead(context),
          // 손글씨는 줄 사이가 좁으면 한 덩어리로 몰려 보여서 칸마다 숨 쉴
          // 여백을 크게 둔다.
          const SizedBox(height: 28),
          _buildMonthNavigator(),
          const SizedBox(height: 18),
          _buildWeekdays(),
          const SizedBox(height: 16),
          _buildGrid(context),
        ],
      ),
    );
  }

  Widget _buildHead(BuildContext context) {
    final data = this.data;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ProfileSticker(size: large ? 64 : 58, ink: ink),
        const SizedBox(width: 14),
        Expanded(
          child: data == null ? _buildFailedHead() : _buildSentences(data),
        ),
      ],
    );
  }

  Widget _buildFailedHead() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HandText('기록을 불러오지 못했어요', size: 22, color: ink.ink),
        PressableScale(
          key: retryKey,
          onTap: onRetry,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: HandText(
                '다시 불러오기',
                size: 17,
                color: ink.soft,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 머리 두 줄. 연속 일수는 서버가 준 값을 그대로 적는다.
  ///
  /// 처음에는 최고 기록 형광펜까지 세 줄이었는데 머리가 빽빽해 보여서 뺐다.
  /// 이번 달 최고 기록은 마이페이지 학습 달력 카드를 펼치면 보인다.
  ///
  /// 지난달을 보고 있을 때 `이번 달엔` 이라고 적으면 거짓말이 돼서, 그때는
  /// `8월엔` 처럼 그 달 이름으로 바꿔 적는다.
  Widget _buildSentences(StudyCalendarModel data) {
    final monthName = _isCurrentMonth ? '이번 달' : '$month월';
    final streak = data.currentStreak;
    final studyDays = data.thisMonthStudyDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (streak > 0)
          HandText('$streak일째 공부 중', size: 32, color: ink.ink, height: 1.1)
        else
          // 32 로 쓰면 폰에서 두 줄로 꺾여 달력을 밀어낸다.
          HandText('오늘 공부하면 1일째가 돼요', size: 24, color: ink.ink),
        const SizedBox(height: 6),
        HandText(
          studyDays > 0
              ? '$monthName엔 $studyDays일 공부했어요'
              : _isCurrentMonth
                  ? '이번 달엔 아직 공부한 날이 없어요'
                  : '$month월엔 공부한 날이 없어요',
          size: 17,
          color: ink.soft,
          height: 1.4,
        ),
      ],
    );
  }

  Widget _buildMonthNavigator() {
    final canGoNext = onNextMonth != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavButton(
          key: prevMonthKey,
          label: '지난달',
          glyph: InkGlyph.chevronLeft,
          color: ink.ink,
          onTap: onPrevMonth,
        ),
        const SizedBox(width: 10),
        // 가운데 글자를 누르면 전과 같은 연월 선택 창이 뜬다. 글자를 크게
        // 키운 작은 폰에서는 화살표를 밀어내지 않게 글자 쪽이 줄어든다.
        Flexible(
          child: PressableScale(
            key: monthLabelKey,
            onTap: onPickMonth,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 44),
              child: Center(
                widthFactor: 1,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: HandText(
                    '$year년 $month월',
                    size: 26,
                    color: ink.ink,
                    height: 1.1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Opacity(
          opacity: canGoNext ? 1 : 0.3,
          child: _NavButton(
            key: nextMonthKey,
            label: '다음 달',
            glyph: InkGlyph.chevronRight,
            color: ink.ink,
            onTap: onNextMonth,
          ),
        ),
      ],
    );
  }

  static const List<String> _weekdayLabels = [
    '일',
    '월',
    '화',
    '수',
    '목',
    '금',
    '토'
  ];

  Widget _buildWeekdays() {
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Center(
              child: HandText(
                _weekdayLabels[i],
                size: 16,
                color: i == 0 ? DiaryPaper.sunday : ink.soft,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    final todayDate = DateTime(today.year, today.month, today.day);
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final rows = ((firstWeekday + daysInMonth) / 7).ceil();
    // 칸끼리 붙어 보이지 않게 줄 사이를 넉넉히 띄운다.
    final rowGap = large ? 14.0 : 13.0;
    final data = this.data;

    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = constraints.maxWidth / 7;
        // 칸 지름은 가로 한 칸 폭의 80% 라 옆 칸과 사이에 틈이 생긴다. 넓은
        // 화면에서 동그라미가 풍선처럼 커지지 않게 폰 42, 태블릿 50 에서 멈춘다.
        final diameter =
            math.max(0.0, math.min(slot * 0.8, large ? 50.0 : 42.0));
        // 누르는 자리는 동그라미 바깥까지 칸 전체다. 44 보다 낮아지지 않게 한다.
        final rowHeight = math.max(diameter + rowGap, 44.0);

        return Column(
          children: [
            for (var row = 0; row < rows; row++)
              // 한 줄씩 내려오며 그린다. 한꺼번에 나타나면 어느 날에 기록이
              // 있는지 눈이 따라가기 어렵다.
              AppearTransition(
                delay: AppMotion.stagger * row,
                child: Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(
                        child: _buildCell(
                          date: DateTime(
                            year,
                            month,
                            row * 7 + col - firstWeekday + 1,
                          ),
                          todayDate: todayDate,
                          data: data,
                          diameter: diameter,
                          rowHeight: rowHeight,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCell({
    required DateTime date,
    required DateTime todayDate,
    required StudyCalendarModel? data,
    required double diameter,
    required double rowHeight,
  }) {
    final inMonth = date.month == month && date.year == year;
    if (!inMonth) {
      // 지난달과 다음 달 날짜는 흐린 숫자로만 채운다. 누를 수 없다.
      return SizedBox(
        height: rowHeight,
        child: Center(
          child: _DayCircle(
            day: date.day,
            diameter: diameter,
            ink: ink,
            large: large,
            numberColor: ink.faint,
          ),
        ),
      );
    }

    final day = date.day;
    final isFuture = date.isAfter(todayDate);
    final isToday = date == todayDate;
    final record = data?.recordFor(day);
    final level = record?.intensityLevel ?? 0;
    final isSelected = selectedDay == day;

    return Semantics(
      label: '$month월 $day일',
      selected: isSelected,
      child: PressableScale(
        key: dayKey(day),
        haptic: HapticLevel.selection,
        semanticButton: !isFuture,
        onTap: isFuture ? null : () => onDayTap(day),
        child: SizedBox(
          height: rowHeight,
          child: Center(
            child: _DayCircle(
              day: day,
              diameter: diameter,
              ink: ink,
              large: large,
              level: level,
              numberColor: isFuture ? ink.faint : ink.numberOn(level),
              isToday: isToday,
              // 오늘은 이미 잉크 테두리가 있어서 점선을 겹치지 않는다.
              isSelected: isSelected && !isToday,
              moodEmojiKey: record?.moodEmojiKey,
              hasDiary: diaryDays.contains(day),
            ),
          ),
        ),
      ),
    );
  }
}

/// 달력 동그라미 한 칸.
class _DayCircle extends StatelessWidget {
  final int day;
  final double diameter;
  final DiaryInk ink;
  final bool large;
  final int level;
  final Color numberColor;
  final bool isToday;
  final bool isSelected;
  final String? moodEmojiKey;
  final bool hasDiary;

  const _DayCircle({
    required this.day,
    required this.diameter,
    required this.ink,
    required this.large,
    required this.numberColor,
    this.level = 0,
    this.isToday = false,
    this.isSelected = false,
    this.moodEmojiKey,
    this.hasDiary = false,
  });

  @override
  Widget build(BuildContext context) {
    // 글자 크기 설정은 따르되 숫자가 동그라미 밖으로 나가지 않게 막는다.
    final base = large ? 20.0 : 18.0;
    final fontSize = math.min(
      MediaQuery.textScalerOf(context).scale(base),
      diameter * 0.5,
    );

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 공부한 날만 칠한다. 안 한 날은 동그라미 없이 숫자만 둬서 공부한
          // 날이 한눈에 튀어 보이게 한다.
          Positioned.fill(
            child: DecoratedBox(
              key: level > 0 ? CalendarMonthSheet.studiedKey(day) : null,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ink.levelFill(level),
              ),
            ),
          ),
          if (isToday)
            Positioned.fill(
              child: DecoratedBox(
                key: CalendarMonthSheet.todayKey(day),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ink.ink, width: 1.8),
                ),
              ),
            ),
          if (isSelected)
            Positioned.fill(
              child: CustomPaint(
                key: CalendarMonthSheet.selectedKey(day),
                painter: DashedCirclePainter(color: ink.ink, strokeWidth: 1.8),
              ),
            ),
          Padding(
            // 손글씨 숫자는 글자 칸 위쪽에 앉아 있어 가운데보다 살짝 내린다.
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '$day',
              textScaler: TextScaler.noScaling,
              style: HandText.style(size: fontSize, color: numberColor),
            ),
          ),
          // 기분 스티커는 숫자와 원을 가리지 않게 작게, 원 바깥 오른쪽 아래
          // 가장자리에 살짝만 걸친다.
          if (moodEmojiKey != null)
            Positioned(
              key: CalendarMonthSheet.moodKey(day),
              right: -9,
              bottom: -6,
              child: Transform.rotate(
                angle: 8 * math.pi / 180,
                child: OnoEmojiImage(emojiKey: moodEmojiKey, size: 16),
              ),
            ),
          // 기분 스티커가 오른쪽 아래를 쓰므로 일기 표시는 오른쪽 위에 둔다.
          if (hasDiary)
            Positioned(
              key: CalendarMonthSheet.diaryKey(day),
              right: -8,
              top: -5,
              child: InkIcon(
                InkGlyph.pencil,
                size: 12,
                color: ink.ink,
                strokeWidth: 1.8,
              ),
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final InkGlyph glyph;
  final Color color;
  final VoidCallback? onTap;

  const _NavButton({
    super.key,
    required this.label,
    required this.glyph,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: onTap != null,
      child: PressableScale(
        onTap: onTap,
        enabled: onTap != null,
        semanticButton: false,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: InkIcon(glyph, size: 18, color: color)),
        ),
      ),
    );
  }
}

/// 머리 왼쪽의 프로필 스티커. 마이페이지와 같은 프로필(사진이 없으면 꾸민
/// 개구리, 치장 테두리까지)을 살짝 비뚤게 붙인다.
class _ProfileSticker extends StatelessWidget {
  final double size;
  final DiaryInk ink;

  const _ProfileSticker({required this.size, required this.ink});

  @override
  Widget build(BuildContext context) {
    final cosmetic = context.watch<CosmeticProvider>();
    final imageUrl = context.select<UserProvider, String?>(
      (user) => user.userInfoModel?.profileImageUrl,
    );

    return Transform.rotate(
      angle: -6 * math.pi / 180,
      child: ProfileAvatar(
        imageUrl: imageUrl,
        size: size,
        borderColor: ink.theme.withValues(alpha: 0.25),
        borderWidth: 1.2,
        backgroundColor: Colors.white,
        frogLayers: cosmetic.layers,
        frameUrl: cosmetic.profileFrame?.imageUrl,
      ),
    );
  }
}
