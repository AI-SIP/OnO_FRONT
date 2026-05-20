import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Model/StudyCalendar/StudyCalendarModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Provider/UserProvider.dart';
import '../../../Service/Api/LearningReport/LearningReportService.dart';
import '../../../Service/Api/StudyCalendar/StudyCalendarService.dart';
import '../LearningCalendarScreen.dart';

class StreakCard extends StatefulWidget {
  final ThemeHandler themeProvider;
  const StreakCard({super.key, required this.themeProvider});

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard> {
  int _currentStreak = 0;
  bool _isStreakLoading = true;

  StudyCalendarModel? _calendarData;
  bool _isCalendarLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStreakData();
    _loadCalendarData();
  }

  Future<void> _loadStreakData() async {
    try {
      final report = await LearningReportService().getLearningReport();
      if (mounted) {
        setState(() {
          _currentStreak = report.total.consecutiveLearningDays;
          _isStreakLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isStreakLoading = false);
    }
  }

  Future<void> _loadCalendarData() async {
    final now = DateTime.now();
    try {
      final data = await StudyCalendarService().getStudyCalendar(
        year: now.year,
        month: now.month,
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

  static String _getFrogImagePath(int level) {
    if (level >= 15) return 'assets/FrogCharacter/FROG_LEVEL15.png';
    if (level >= 13) return 'assets/FrogCharacter/FROG_LEVEL13.png';
    if (level >= 11) return 'assets/FrogCharacter/FROG_LEVEL11.png';
    if (level >= 9) return 'assets/FrogCharacter/FROG_LEVEL9.png';
    if (level >= 7) return 'assets/FrogCharacter/FROG_LEVEL7.png';
    if (level >= 5) return 'assets/FrogCharacter/FROG_LEVEL5.png';
    if (level >= 3) return 'assets/FrogCharacter/FROG_LEVEL3.png';
    if (level >= 1) return 'assets/FrogCharacter/FROG_LEVEL1.png';
    return 'assets/FrogCharacter/FROG_LEVEL1.png';
  }

  String _getStreakMessage(int streak) {
    if (streak >= 100) return '100일 연속 학습 달성! 정말 대단해요 👑';
    if (streak >= 30)  return '한 달 이상 연속 학습! 실력이 쑥쑥 오르고 있어요 🌱';
    if (streak >= 14)  return '2주 연속 학습! 좋은 습관이 자리잡고 있어요 💪';
    if (streak >= 7)   return '일주일 연속 학습 달성! 아주 잘하고 있어요 🔥';
    if (streak >= 3)   return '꾸준히 학습 중이에요! (${streak}일째) 😊';
    if (streak >= 1)   return '학습을 시작했어요! 꾸준히 이어가 봐요 📚';
    return '오늘 학습하면 연속 학습이 시작돼요!';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final primaryColor = widget.themeProvider.primaryColor;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, primaryColor),
            const SizedBox(height: 14),
            _buildStreakBanner(context, primaryColor),
            if (!_isCalendarLoading && _calendarData != null) ...[
              const SizedBox(height: 14),
              _buildMiniCalendar(context, screenWidth, primaryColor),
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
            const SizedBox(height: 12),
            _buildFooterStats(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryColor) {
    return Row(
      children: [
        const StandardText(
          text: '학습 달력',
          fontSize: 15,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LearningCalendarScreen()),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StandardText(
                text: '자세히 보기',
                fontSize: 12,
                color: Colors.black38,
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.black38),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakBanner(BuildContext context, Color primaryColor) {
    if (_isStreakLoading) {
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

    final userLevel =
        Provider.of<UserProvider>(context, listen: false).userInfoModel?.totalStudyLevel ?? 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Image.asset(
            _getFrogImagePath(userLevel),
            width: 52,
            height: 52,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    StandardText(
                      text: '$_currentStreak',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 4),
                    const StandardText(
                      text: '일 연속',
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                StandardText(
                  text: _getStreakMessage(_currentStreak),
                  fontSize: 11,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCalendar(
      BuildContext context, double screenWidth, Color primaryColor) {
    final now = DateTime.now();
    final calendarData = _calendarData!;
    final firstDayOfMonth =
        DateTime(calendarData.year, calendarData.month, 1);
    // weekday: Mon=1..Sun=7, 달력 offset: 일=0..토=6
    final firstWeekdayOffset = firstDayOfMonth.weekday % 7;
    final daysInMonth =
        DateTime(calendarData.year, calendarData.month + 1, 0).day;

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
        // 5행 × 7열 점 그리드
        ...List.generate(5, (rowIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(7, (colIndex) {
                final cellIndex = rowIndex * 7 + colIndex;
                final day = cellIndex - firstWeekdayOffset + 1;

                if (day < 1 || day > daysInMonth) {
                  return Expanded(
                    child: SizedBox(
                      height: dotSize,
                    ),
                  );
                }

                final cellDate = DateTime(calendarData.year, calendarData.month, day);
                final isToday = cellDate.year == now.year &&
                    cellDate.month == now.month &&
                    cellDate.day == now.day;
                final isFuture = cellDate.isAfter(now);

                if (isToday) {
                  return Expanded(
                    child: Center(
                      child: SizedBox(
                        width: dotSize,
                        height: dotSize,
                        child: const FittedBox(
                          fit: BoxFit.contain,
                          child: Text('🐸'),
                        ),
                      ),
                    ),
                  );
                }

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
                    child: Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
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
              text: '이번 달 최장 복습 ${bestStreak != null ? '$bestStreak일' : '--'}',
              fontSize: 12,
              color: Colors.black54,
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.black38),
            const SizedBox(width: 4),
            StandardText(
              text: '이번 달 ${thisMonthStudyDays != null ? '$thisMonthStudyDays일' : '--'}',
              fontSize: 12,
              color: Colors.black54,
            ),
          ],
        ),
      ],
    );
  }
}
