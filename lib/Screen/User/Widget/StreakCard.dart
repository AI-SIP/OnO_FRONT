import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Model/StudyCalendar/StudyCalendarModel.dart';
import '../../../Module/Motion/AppHaptic.dart';
import '../../../Module/Motion/PressableScale.dart';
import '../../../Module/Motion/Skeleton.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Service/Api/StudyCalendar/StudyCalendarService.dart';
import '../../../Util/AppClock.dart';
import '../LearningCalendarScreen.dart';
import '../../../Module/Motion/TossPageRoute.dart';
import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import 'DiaryTheme.dart';

/// [date] 가 그 달의 몇 번째 주인지. 일요일에 시작하는 주로 세고, 1일이 든
/// 주가 1주차다. 예: 2026-09-30 → 5주차.
int weekOfMonth(DateTime date) {
  final firstWeekdayOffset = DateTime(date.year, date.month, 1).weekday % 7;
  return (date.day + firstWeekdayOffset - 1) ~/ 7 + 1;
}

class StreakCard extends StatefulWidget {
  final ThemeHandler themeProvider;
  final double horizontalMarginFactor;

  const StreakCard({
    super.key,
    required this.themeProvider,
    this.horizontalMarginFactor = 0.04,
  });

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard> {
  static const _calendarExpandedKey = 'my_page_calendar_expanded';
  StudyCalendarModel? _calendarData;
  bool _isCalendarLoading = true;
  bool _isCalendarExpanded = false;
  bool _prefLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefLoaded) {
      _prefLoaded = true;
      final mq = MediaQuery.of(context);
      final isTablet = mq.size.shortestSide >= 600;
      // 태블릿이면 즉시 펼침 상태로 설정 (prefs 로드 전 플리커 방지)
      _isCalendarExpanded = isTablet;
      _loadExpandedPreference(tabletDefault: isTablet);
    }
  }

  Future<void> _loadExpandedPreference({bool tabletDefault = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isCalendarExpanded =
          prefs.getBool(_calendarExpandedKey) ?? tabletDefault;
    });
  }

  Future<void> _toggleCalendarExpanded() async {
    final nextValue = !_isCalendarExpanded;
    setState(() {
      _isCalendarExpanded = nextValue;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_calendarExpandedKey, nextValue);
  }

  void _openCalendarDetail() {
    Navigator.push(
      context,
      TossPageRoute(builder: (_) => const LearningCalendarScreen()),
    );
  }

  Future<void> _loadCalendarData() async {
    final now = AppClock.now();
    try {
      final data = await StudyCalendarService().getStudyCalendar(
        year: now.year,
        month: now.month,
        showErrorSnackBar: false,
      );
      if (mounted) {
        setState(() {
          _calendarData = data;
          _isCalendarLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCalendarLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final screenHeight = mq.size.height;
    final isTablet = mq.size.shortestSide >= 600;
    final isTabletLandscape = isTablet && screenWidth > screenHeight;
    final primaryColor = widget.themeProvider.primaryColor;

    // 바로 아래 `학습 리포트` 카드(MyPageScreen._buildReviewReportButton)와
    // 같은 흰 카드, 테두리, 패딩이다. 이 카드만 모양이 다르면 마이페이지에서
    // 혼자 튀어 보였다.
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * widget.horizontalMarginFactor,
        vertical: screenHeight * 0.005,
      ),
      padding: EdgeInsets.fromLTRB(
        screenHeight * 0.018,
        isTabletLandscape ? screenHeight * 0.030 : screenHeight * 0.018,
        screenHeight * 0.018,
        isTabletLandscape ? screenHeight * 0.016 : screenHeight * 0.006,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(primaryColor, screenHeight),
          const SizedBox(height: 14),
          if (_isCalendarLoading)
            SkeletonBox(height: isTablet ? 76 : 68, borderRadius: 16)
          else
            PressableScale(
              onTap: _openCalendarDetail,
              scale: 0.98,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _buildPanel(context, primaryColor, isTablet: isTablet),
              ),
            ),
          if (isTabletLandscape) const Spacer() else const SizedBox(height: 4),
          if (!_isCalendarLoading) _buildExpandButton(isTablet: isTablet),
        ],
      ),
    );
  }

  /// 아이콘 칩 + `학습 달력` + 오른쪽 끝 `>`. 누르면 학습 달력으로 간다.
  ///
  /// 부제 줄까지 두면 글자가 빽빽해서, 숫자와 점은 아래 패널로 옮겼다.
  Widget _buildHeader(Color primaryColor, double screenHeight) {
    return PressableScale(
      onTap: _openCalendarDetail,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: primaryColor,
              size: 16,
            ),
          ),
          SizedBox(width: screenHeight * 0.015),
          const Expanded(
            child: StandardText(
              text: '학습 달력',
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  /// 테마 색을 옅게 깐 둥근 패널. 접혀 있으면 왼쪽에 연속 일수, 오른쪽에
  /// 이번 주 점 일곱 개. 펼치면 한 줄 요약과 한 달 달력이다.
  Widget _buildPanel(
    BuildContext context,
    Color primaryColor, {
    bool isTablet = false,
  }) {
    final data = _calendarData;
    final Widget child;
    if (_isCalendarExpanded) {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryLine(data, primaryColor),
          const SizedBox(height: 14),
          if (data != null)
            _buildMonthCalendar(context, data, primaryColor, isTablet: isTablet)
          else
            const StandardText(
              text: '기록을 불러오지 못했어요',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
        ],
      );
    } else {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPeriodLabel(),
          const SizedBox(height: 12),
          _buildWeekDots(data, primaryColor, isTablet),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  /// 이번 주가 언제인지 알려 주는 작은 라벨 `9월 5주차`. 날짜만으로 정하므로
  /// 기록 조회에 실패해도 그대로 보인다.
  ///
  /// 처음에는 `5주차` 를 크게 테마 색으로 썼는데 부담스러워서, 본문 회색 한
  /// 줄로 두고 점 줄이 패널 폭을 다 쓰게 했다. 연속 일수는 학습 달력 화면
  /// 머리에 있다.
  Widget _buildPeriodLabel() {
    final now = AppClock.now();
    return StandardText(
      text: '${now.month}월 ${weekOfMonth(now)}주차',
      fontSize: 14,
      color: AppColors.textSecondary,
      height: 1.3,
    );
  }

  /// 이번 주 일곱 칸을 점으로. 날짜 숫자는 적지 않는다.
  Widget _buildWeekDots(
    StudyCalendarModel? data,
    Color primaryColor,
    bool isTablet,
  ) {
    final now = AppClock.now();
    final today = DateTime(now.year, now.month, now.day);
    final sunday = today.subtract(Duration(days: today.weekday % 7));
    final dotSize = isTablet ? 20.0 : 18.0;
    const labels = ['일', '월', '화', '수', '목', '금', '토'];

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StandardText(
                  text: labels[i],
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  height: 1.3,
                ),
                const SizedBox(height: 6),
                _buildWeekDot(
                  date: sunday.add(Duration(days: i)),
                  today: today,
                  data: data,
                  primaryColor: primaryColor,
                  size: dotSize,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWeekDot({
    required DateTime date,
    required DateTime today,
    required StudyCalendarModel? data,
    required Color primaryColor,
    required double size,
  }) {
    final isToday = date == today;
    final isFuture = date.isAfter(today);
    // 이번 주가 지난달에 걸치면 그 날들의 기록은 이 달 조회에 없다. 안 한
    // 날로 그리면 거짓말이 돼서 아직 안 온 날처럼 옅게만 둔다.
    // 기록을 못 불러왔으면 모르는 날이라 전부 옅은 점으로 둔다.
    final inMonth =
        data != null && date.year == data.year && date.month == data.month;
    final studied =
        inMonth && !isFuture && (data.recordFor(date.day)?.hasStudied ?? false);

    final Color fill;
    final Border? border;
    if (studied) {
      fill = primaryColor;
      border = isToday
          ? Border.all(color: DiaryInk.of(primaryColor).ink, width: 2)
          : null;
    } else if (isToday) {
      fill = Colors.white;
      border = Border.all(color: primaryColor, width: 2);
    } else if (isFuture || !inMonth) {
      fill = Colors.grey[200]!.withValues(alpha: 0.7);
      border = null;
    } else {
      fill = Colors.white;
      border = Border.all(color: Colors.grey[300]!, width: 1.5);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: border,
      ),
    );
  }

  /// 펼쳤을 때 달력 위 한 줄. 어느 달인지만 적는다. 공부한 날 수까지 붙이면
  /// 달력 위가 다시 글자로 빽빽해져서 뺐다.
  Widget _buildSummaryLine(StudyCalendarModel? data, Color primaryColor) {
    final now = AppClock.now();
    return StandardText(
      text: '${data?.year ?? now.year}년 ${data?.month ?? now.month}월',
      fontSize: 14,
      color: AppColors.textSecondary,
      height: 1.3,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 카드 아래 가운데 `한 달 보기` / `접기`. 펼친 상태 저장은 전과 같다.
  Widget _buildExpandButton({bool isTablet = false}) {
    final expanded = _isCalendarExpanded;
    return Center(
      child: PressableScale(
        haptic: HapticLevel.selection,
        onTap: _toggleCalendarExpanded,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 88),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StandardText(
                text: expanded ? '접기' : '한 달 보기',
                fontSize: isTablet ? 13.0 : 12.0,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 2),
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: isTablet ? 18.0 : 16.0,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthCalendar(
    BuildContext context,
    StudyCalendarModel calendarData,
    Color primaryColor, {
    bool isTablet = false,
  }) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final isTabletLandscape = isTablet && screenWidth > mq.size.height;

    // LayoutBuilder 없이 폭을 어림한다(가로 태블릿의 IntrinsicHeight 와 충돌).
    // 가로 태블릿은 카드가 화면의 약 45%, 그 밖은 좌우 여백을 뺀 폭이다.
    // 카드 안쪽 여백과 패널 안쪽 여백(16 x 2)을 뺀다.
    final double cardWidth = isTabletLandscape
        ? screenWidth * 0.45
        : screenWidth * (1.0 - 2.0 * widget.horizontalMarginFactor);
    final double padding = (isTablet ? 44.0 : 32.0) + 32.0;
    final double availableWidth = cardWidth - padding;
    final double maxCircle = isTablet ? 32.0 : 26.0;
    final double circle = ((availableWidth / 7) - 6).clamp(0.0, maxCircle);
    final double numberSize = isTablet ? 11.0 : 10.0;

    final now = AppClock.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstWeekdayOffset =
        DateTime(calendarData.year, calendarData.month, 1).weekday % 7;
    final daysInMonth =
        DateTime(calendarData.year, calendarData.month + 1, 0).day;
    final rowCount = ((firstWeekdayOffset + daysInMonth) / 7).ceil();

    const weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];
    final ink = DiaryInk.of(primaryColor).ink;
    // 패널 바탕. 흰 카드 위에 테마 색 7% 를 깐 색이다.
    final panel = Color.alphaBlend(
      primaryColor.withValues(alpha: 0.07),
      Colors.white,
    );

    return Column(
      children: [
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Center(
                  child: StandardText(
                    text: label,
                    fontSize: 11,
                    fontFamily: 'PretendardLight',
                    fontWeight: FontWeight.normal,
                    color: AppColors.textTertiary,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (var row = 0; row < rowCount; row++)
          Padding(
            // 줄 사이를 넉넉히 띄워 칸끼리 붙어 보이지 않게 한다.
            padding: EdgeInsets.only(bottom: row == rowCount - 1 ? 0 : 9),
            child: Row(
              children: List.generate(7, (col) {
                final day = row * 7 + col - firstWeekdayOffset + 1;
                if (day < 1 || day > daysInMonth) {
                  return Expanded(child: SizedBox(height: circle));
                }

                final cellDate =
                    DateTime(calendarData.year, calendarData.month, day);
                final isToday = cellDate == today;
                final isFuture = cellDate.isAfter(today);
                // 공부한 날만 테마 색으로 칠한다. 안 한 날은 숫자만 둔다.
                final level = isFuture
                    ? 0
                    : calendarData.recordFor(day)?.intensityLevel ?? 0;
                final fill = switch (level) {
                  1 => primaryColor.withValues(alpha: 0.3),
                  2 => primaryColor.withValues(alpha: 0.6),
                  3 => primaryColor,
                  _ => Colors.transparent,
                };
                // 숫자는 가는 글씨에 회색으로 가볍게 둔다. 굵고 검은 숫자가
                // 서른 개 늘어서면 달력이 무겁게 보였다.
                final Color numberColor;
                if (isFuture) {
                  numberColor = AppColors.textDisabled;
                } else if (level > 0) {
                  // 칠한 원 위에서는 테마 진한 색과 흰색 중 더 잘 읽히는 쪽.
                  final onFill = Color.alphaBlend(fill, panel);
                  numberColor =
                      _contrast(onFill, ink) >= _contrast(onFill, Colors.white)
                          ? ink
                          : Colors.white;
                } else if (isToday) {
                  numberColor = ink;
                } else {
                  numberColor = AppColors.textSecondary;
                }

                return Expanded(
                  child: Center(
                    child: Container(
                      width: circle,
                      height: circle,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: fill,
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: primaryColor, width: 1.5)
                            : null,
                      ),
                      child: Text(
                        '$day',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          // 오늘만 조금 굵게 해서 테두리와 함께 눈에 띄게 한다.
                          fontFamily:
                              isToday ? 'PretendardBold' : 'PretendardLight',
                          fontSize: numberSize,
                          height: 1.1,
                          color: numberColor,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }
}
