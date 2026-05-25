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
      _isCalendarExpanded = prefs.getBool(_calendarExpandedKey) ?? tabletDefault;
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

    final cardPadding = isTabletLandscape
        ? const EdgeInsets.fromLTRB(24, 24, 24, 20)
        : isTablet
            ? const EdgeInsets.fromLTRB(22, 18, 22, 16)
            : const EdgeInsets.fromLTRB(16, 14, 16, 12);

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
            color: primaryColor.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, primaryColor, isTablet: isTablet),
            SizedBox(height: isTabletLandscape ? 16 : 10),
            _buildStreakBanner(primaryColor, isTablet: isTablet),
            if (!_isCalendarLoading && _calendarData != null) ...[
              SizedBox(height: isTabletLandscape ? 18 : 12),
              InkWell(
                onTap: _openCalendarDetail,
                borderRadius: BorderRadius.circular(8),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: _buildMiniCalendar(
                    context,
                    primaryColor,
                    isTablet: isTablet,
                  ),
                ),
              ),
            ] else if (_isCalendarLoading) ...[
              SizedBox(height: isTabletLandscape ? 18 : 12),
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
              SizedBox(height: isTabletLandscape ? 18 : 12),
              _buildFooterStats(primaryColor, isTablet: isTablet),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Color primaryColor, {
    bool isTablet = false,
  }) {
    final calendarYear = _calendarData?.year ?? DateTime.now().year;
    final calendarMonth = _calendarData?.month ?? DateTime.now().month;

    return InkWell(
      onTap: _toggleCalendarExpanded,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          StandardText(
            text: '$calendarYear년 $calendarMonth월 학습 달력',
            fontSize: isTablet ? 18.0 : 15.0,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          const Spacer(),
          Icon(
            _isCalendarExpanded
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            size: isTablet ? 26.0 : 20.0,
            color: Colors.black38,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBanner(Color primaryColor, {bool isTablet = false}) {
    if (_isCalendarLoading) {
      return SizedBox(
        height: isTablet ? 80.0 : 64.0,
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
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16.0 : 12.0,
          vertical: isTablet ? 12.0 : 8.0,
        ),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha:0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const SizedBox(width: 6),
            StandardText(
              text: currentStreak != null ? '$currentStreak' : '--',
              fontSize: isTablet ? 28.0 : 21.0,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
            const SizedBox(width: 4),
            StandardText(
              text: '일 연속 학습중',
              fontSize: isTablet ? 15.0 : 12.0,
              color: Colors.black54,
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: isTablet ? 22.0 : 18.0,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCalendar(
    BuildContext context,
    Color primaryColor, {
    bool isTablet = false,
  }) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final isTabletLandscape = isTablet && screenWidth > mq.size.height;

    // Estimate available width without LayoutBuilder (avoids IntrinsicHeight conflict)
    // Tablet landscape: each card is ~45% of screen width (outer 4%+4% padding, 2% gap, ÷2)
    // Otherwise: full card width minus horizontal margins
    final double cardWidth = isTabletLandscape
        ? screenWidth * 0.45
        : screenWidth * (1.0 - 2.0 * widget.horizontalMarginFactor);
    final double cardPadding = isTablet ? 44.0 : 32.0;
    final double availableWidth = cardWidth - cardPadding;
    final double maxDotSize = isTablet ? 20.0 : 12.0;
    final double dotSize = ((availableWidth / 7) * 0.6).clamp(0.0, maxDotSize);

    final now = DateTime.now();
    final calendarData = _calendarData!;
    final firstDayOfMonth = DateTime(calendarData.year, calendarData.month, 1);
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

    const weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      children: [
        Row(
          children: weekdayLabels
              .map(
                (label) => Expanded(
                  child: Center(
                    child: StandardText(
                      text: label,
                      fontSize: isTablet ? 12.0 : 10.0,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        ...List.generate(rowCount, (rowIndex) {
          final calendarRowIndex = firstRowIndex + rowIndex;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(7, (colIndex) {
                final cellIndex = calendarRowIndex * 7 + colIndex;
                final day = cellIndex - firstWeekdayOffset + 1;

                if (day < 1 || day > daysInMonth) {
                  return Expanded(child: SizedBox(height: dotSize));
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
                      dotColor = primaryColor.withValues(alpha: 0.3);
                      break;
                    case 2:
                      dotColor = primaryColor.withValues(alpha: 0.6);
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

  Widget _buildFooterStats(Color primaryColor, {bool isTablet = false}) {
    final bestStreak = _calendarData?.bestStreak;
    final thisMonthStudyDays = _calendarData?.thisMonthStudyDays;
    final fontSize = isTablet ? 14.0 : 12.0;
    final iconSize = isTablet ? 16.0 : 13.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.star_outline, size: iconSize, color: Colors.amber),
            const SizedBox(width: 4),
            StandardText(
              text: '이번 달 최장 복습: ${bestStreak != null ? '$bestStreak일' : '--'}',
              fontSize: fontSize,
              color: Colors.black54,
            ),
          ],
        ),
        Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: iconSize - 1, color: Colors.black38),
            const SizedBox(width: 4),
            StandardText(
              text: '복습 일수: ${thisMonthStudyDays != null ? '$thisMonthStudyDays일' : '--'}',
              fontSize: fontSize,
              color: Colors.black54,
            ),
          ],
        ),
      ],
    );
  }
}
