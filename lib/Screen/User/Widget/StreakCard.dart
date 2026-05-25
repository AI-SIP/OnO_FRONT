import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Model/StudyCalendar/StudyCalendarModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Service/Api/StudyCalendar/StudyCalendarService.dart';
import '../LearningCalendarScreen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadExpandedPreference();
    _loadCalendarData();
  }

  Future<void> _loadExpandedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isCalendarExpanded = prefs.getBool(_calendarExpandedKey) ?? false;
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
      MaterialPageRoute(builder: (_) => const LearningCalendarScreen()),
    );
  }

  Future<void> _loadCalendarData() async {
    final now = DateTime.now();
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
      // 실패해도 에러 미표시 — 미니 달력 섹션만 숨김
      if (mounted) setState(() => _isCalendarLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final primaryColor = widget.themeProvider.primaryColor;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * widget.horizontalMarginFactor,
        vertical: screenHeight * 0.005,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, primaryColor),
            const SizedBox(height: 10),
            _buildStreakBanner(primaryColor),
            if (!_isCalendarLoading && _calendarData != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: _openCalendarDetail,
                borderRadius: BorderRadius.circular(8),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: _buildMiniCalendar(context, screenWidth, primaryColor),
                ),
              ),
            ] else if (_isCalendarLoading) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: Center(
                  child: CircularProgressIndicator(
                    color: primaryColor,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ],
            if (_isCalendarExpanded) ...[
              const SizedBox(height: 12),
              _buildFooterStats(primaryColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryColor) {
    final calendarYear = _calendarData?.year ?? DateTime.now().year;
    final calendarMonth = _calendarData?.month ?? DateTime.now().month;

    return InkWell(
      onTap: _toggleCalendarExpanded,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          StandardText(
            text: '$calendarYear년 $calendarMonth월 학습 달력',
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          const Spacer(),
          Icon(
            _isCalendarExpanded
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            size: 20,
            color: Colors.black38,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBanner(Color primaryColor) {
    if (_isCalendarLoading) {
      return SizedBox(
        height: 64,
        child: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final currentStreak = _calendarData?.currentStreak;

    return InkWell(
      onTap: _openCalendarDetail,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const SizedBox(width: 6),
            StandardText(
              text: currentStreak != null ? '$currentStreak' : '--',
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
            const SizedBox(width: 4),
            const StandardText(
              text: '일 연속 학습중',
              fontSize: 12,
              color: Colors.black54,
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCalendar(
      BuildContext context, double screenWidth, Color primaryColor) {
    final now = DateTime.now();
    final calendarData = _calendarData!;
    final firstDayOfMonth = DateTime(calendarData.year, calendarData.month, 1);
    // weekday: Mon=1..Sun=7, 달력 offset: 일=0..토=6
    final firstWeekdayOffset = firstDayOfMonth.weekday % 7;
    final daysInMonth =
        DateTime(calendarData.year, calendarData.month + 1, 0).day;
    final monthRowCount = ((firstWeekdayOffset + daysInMonth) / 7).ceil();
    final todayIndex =
        now.year == calendarData.year && now.month == calendarData.month
            ? firstWeekdayOffset + now.day - 1
            : 0;
    final firstRowIndex =
        _isCalendarExpanded ? 0 : (todayIndex ~/ 7).clamp(0, monthRowCount - 1);
    final rowCount = _isCalendarExpanded ? monthRowCount : 1;

    // 점 크기 계산 (패딩 32 = 양쪽 16)
    final availableWidth = screenWidth * 0.92 - 32;
    final dotSize = (availableWidth / 7).clamp(0.0, 12.0);

    const weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      children: [
        // 요일 헤더
        Row(
          children: weekdayLabels
              .map(
                (label) => Expanded(
                  child: Center(
                    child: StandardText(
                      text: label,
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        // 펼치면 월 전체, 접히면 오늘이 포함된 주만 렌더링
        ...List.generate(rowCount, (rowIndex) {
          final calendarRowIndex = firstRowIndex + rowIndex;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(7, (colIndex) {
                final cellIndex = calendarRowIndex * 7 + colIndex;
                final day = cellIndex - firstWeekdayOffset + 1;

                if (day < 1 || day > daysInMonth) {
                  return Expanded(
                    child: SizedBox(
                      height: dotSize,
                    ),
                  );
                }

                final cellDate =
                    DateTime(calendarData.year, calendarData.month, day);
                final isToday = cellDate.year == now.year &&
                    cellDate.month == now.month &&
                    cellDate.day == now.day;
                final isFuture = cellDate.isAfter(now);

                Color dotColor;
                if (isFuture) {
                  dotColor = Colors.grey[100]!;
                } else {
                  final record = calendarData.recordFor(day);
                  final intensity = record?.intensityLevel ?? 0;
                  switch (intensity) {
                    case 1:
                      dotColor = primaryColor.withOpacity(0.3);
                      break;
                    case 2:
                      dotColor = primaryColor.withOpacity(0.6);
                      break;
                    case 3:
                      dotColor = primaryColor;
                      break;
                    default:
                      dotColor = Colors.grey[200]!;
                  }
                }

                return Expanded(
                  child: Center(
                    child: SizedBox(
                      width: dotSize,
                      height: dotSize + 5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: dotSize,
                            height: 2,
                            decoration: BoxDecoration(
                              color:
                                  isToday ? primaryColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFooterStats(Color primaryColor) {
    final bestStreak = _calendarData?.bestStreak;
    final thisMonthStudyDays = _calendarData?.thisMonthStudyDays;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.star_outline, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            StandardText(
              text: '이번 달 최장 복습: ${bestStreak != null ? '$bestStreak일' : '--'}',
              fontSize: 12,
              color: Colors.black54,
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 13, color: Colors.black38),
            const SizedBox(width: 4),
            StandardText(
              text:
                  '이번 달 복습 일수: ${thisMonthStudyDays != null ? '$thisMonthStudyDays일' : '--'}',
              fontSize: 12,
              color: Colors.black54,
            ),
          ],
        ),
      ],
    );
  }
}
