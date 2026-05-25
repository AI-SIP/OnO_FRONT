import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/StudyCalendar/StudyCalendarModel.dart';
import '../../Service/Api/StudyCalendar/StudyCalendarService.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Util/AppSnackBar.dart';

class LearningCalendarScreen extends StatefulWidget {
  const LearningCalendarScreen({super.key});

  @override
  State<LearningCalendarScreen> createState() => _LearningCalendarScreenState();
}

class _LearningCalendarScreenState extends State<LearningCalendarScreen> {
  late int _year;
  late int _month;
  StudyCalendarModel? _calendarData;
  bool _isLoading = true;
  int? _selectedDay;

  final StudyCalendarService _service = StudyCalendarService();

  static const List<String> _weekdayLabels = [
    '일',
    '월',
    '화',
    '수',
    '목',
    '금',
    '토'
  ];
  static const List<String> _dayOfWeekNames = [
    '일요일',
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getStudyCalendar(
        year: _year,
        month: _month,
        showErrorSnackBar: false,
      );
      if (mounted) {
        setState(() {
          _calendarData = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.showError('학습 달력을 불러오지 못했어요.');
      }
    }
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _year -= 1;
        _month = 12;
      } else {
        _month -= 1;
      }
      _selectedDay = null;
    });
    _loadCalendar();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_year > now.year || (_year == now.year && _month >= now.month)) return;
    setState(() {
      if (_month == 12) {
        _year += 1;
        _month = 1;
      } else {
        _month += 1;
      }
      _selectedDay = null;
    });
    _loadCalendar();
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _year == now.year && _month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: StandardText(
          text: '학습 달력',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMonthNavigator(themeProvider),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildWeekdayHeader(themeProvider),
                        const SizedBox(height: 8),
                        _buildCalendarGrid(themeProvider),
                      ],
                    ),
                  ),
                  const Divider(),
                  _buildStatsSection(themeProvider),
                  const Divider(),
                  _buildSelectedDayDetail(themeProvider),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthNavigator(ThemeHandler themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _prevMonth,
            color: Colors.black87,
          ),
          GestureDetector(
            onTap: () => _showMonthPicker(themeProvider),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StandardText(
                      text: '$_year년 $_month월',
                      fontSize: 16,
                      color: Colors.black87),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down,
                      size: 18, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right,
                color: _isCurrentMonth ? Colors.grey[300] : Colors.black87),
            onPressed: _isCurrentMonth ? null : _nextMonth,
          ),
        ],
      ),
    );
  }

  void _showMonthPicker(ThemeHandler themeProvider) {
    int pickerYear = _year;
    final now = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 연도 선택
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => setDialogState(() => pickerYear--),
                          color: Colors.black87,
                        ),
                        StandardText(
                            text: '$pickerYear년',
                            fontSize: 16,
                            color: Colors.black87),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: pickerYear >= now.year
                                ? Colors.grey[300]
                                : Colors.black87,
                          ),
                          onPressed: pickerYear >= now.year
                              ? null
                              : () => setDialogState(() => pickerYear++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 월 그리드 (4열 × 3행)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1.6,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (_, index) {
                        final month = index + 1;
                        final isFuture = pickerYear > now.year ||
                            (pickerYear == now.year && month > now.month);
                        final isSelected =
                            pickerYear == _year && month == _month;

                        return GestureDetector(
                          onTap: isFuture
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _year = pickerYear;
                                    _month = month;
                                    _selectedDay = null;
                                  });
                                  _loadCalendar();
                                },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? themeProvider.primaryColor
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: StandardText(
                                text: '$month월',
                                fontSize: 13,
                                color: isSelected
                                    ? Colors.white
                                    : isFuture
                                        ? Colors.grey[300]!
                                        : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWeekdayHeader(ThemeHandler themeProvider) {
    return Row(
      children: _weekdayLabels.map((label) {
        return Expanded(
          child: Center(
            child: StandardText(
              text: label,
              fontSize: 12,
              color: Colors.grey[600]!,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(ThemeHandler themeProvider) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final isTablet = mq.size.shortestSide >= 600;

    // 셀 1개의 자연 크기: 전체 너비에서 그리드 패딩(32)과 셀 패딩(4×7) 제외
    const double gridPadding = 32.0;
    const double cellPadding = 4.0;
    final double naturalCellSize = (screenWidth - gridPadding) / 7 - cellPadding;
    // 태블릿에서는 최대 72px로 제한
    final double cellSize = isTablet ? naturalCellSize.clamp(0.0, 72.0) : naturalCellSize;

    final now = DateTime.now();
    final firstWeekday = DateTime(_year, _month, 1).weekday % 7;
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Row(
          children: List.generate(7, (colIndex) {
            final cellIndex = rowIndex * 7 + colIndex;
            final day = cellIndex - firstWeekday + 1;

            if (day < 1 || day > daysInMonth) {
              return Expanded(
                child: SizedBox(height: cellSize + cellPadding),
              );
            }

            final cellDate = DateTime(_year, _month, day);
            final isFuture =
                cellDate.isAfter(DateTime(now.year, now.month, now.day));
            final isToday = cellDate.year == now.year &&
                cellDate.month == now.month &&
                cellDate.day == now.day;

            final record = _calendarData?.recordFor(day);
            final intensity = record?.intensityLevel ?? 0;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Center(
                  child: SizedBox(
                    width: cellSize,
                    height: cellSize,
                    child: _CalendarCell(
                      day: day,
                      isToday: isToday,
                      isFuture: isFuture,
                      intensityLevel: intensity,
                      themeProvider: themeProvider,
                      onTap: isFuture
                          ? null
                          : () => setState(() {
                                _selectedDay =
                                    (_selectedDay == day) ? null : day;
                              }),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildStatChip(String label, String value, Color primaryColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            StandardText(text: value, fontSize: 15, color: primaryColor),
            const SizedBox(height: 2),
            StandardText(text: label, fontSize: 10, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDayDetail(ThemeHandler themeProvider) {
    if (_selectedDay == null || _calendarData == null)
      return const SizedBox.shrink();

    final record = _calendarData!.recordFor(_selectedDay!);
    final weekdayIndex = DateTime(_year, _month, _selectedDay!).weekday % 7;
    final weekdayName = _dayOfWeekNames[weekdayIndex];
    final primaryColor = themeProvider.primaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StandardText(
                  text: '$_month월 $_selectedDay일 $weekdayName',
                  fontSize: 14,
                  color: primaryColor,
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedDay = null),
                  child: Icon(Icons.close, size: 16, color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (record == null || !record.hasStudied)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: StandardText(
                    text: '이 날은 학습하지 않았어요',
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  _buildStatChip('복습', '${record.reviewCount}회', primaryColor),
                  const SizedBox(width: 8),
                  _buildStatChip(
                      '오답노트', '${record.noteWriteCount}개', primaryColor),
                  const SizedBox(width: 8),
                  _buildStatChip('학습', '${record.studyMinutes}분', primaryColor),
                ],
              ),
              if (record.reviewedItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                StandardText(
                  text: '복습한 항목',
                  fontSize: 11,
                  color: Colors.black45,
                ),
                const SizedBox(height: 6),
                ...record.reviewedItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(Icons.article_outlined,
                              size: 13, color: Colors.grey[400]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: StandardText(
                              text: item,
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(ThemeHandler themeProvider) {
    final currentStreak = _calendarData?.currentStreak;
    final bestStreak = _calendarData?.bestStreak;
    final studyDays = _calendarData?.thisMonthStudyDays;
    final daysInMonth = DateTime(_year, _month + 1, 0).day;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStreakCard(
                  label: '현재 연속',
                  emoji: '🔥',
                  value: currentStreak != null ? '${currentStreak}일' : '--',
                  color: themeProvider.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStreakCard(
                  label: '이번 달 최장 복습',
                  emoji: '⭐',
                  value: bestStreak != null ? '${bestStreak}일' : '--',
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StandardText(
                text: '이번 달 학습',
                fontSize: 14,
                color: Colors.black87,
              ),
              StandardText(
                text: studyDays != null
                    ? '${studyDays}일 / ${daysInMonth}일'
                    : '--',
                fontSize: 14,
                color: Colors.black54,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: studyDays != null
                  ? (studyDays / daysInMonth).clamp(0.0, 1.0)
                  : 0.0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                themeProvider.primaryColor.withOpacity(0.7),
              ),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard({
    required String label,
    required String emoji,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StandardText(
            text: label,
            fontSize: 12,
            color: Colors.grey,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              StandardText(
                text: emoji,
                fontSize: 20,
                color: Colors.black87,
              ),
              const SizedBox(width: 6),
              StandardText(
                text: value,
                fontSize: 20,
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isFuture;
  final int intensityLevel;
  final ThemeHandler themeProvider;
  final VoidCallback? onTap;

  const _CalendarCell({
    required this.day,
    required this.isToday,
    required this.isFuture,
    required this.intensityLevel,
    required this.themeProvider,
    this.onTap,
  });

  Color _getBackgroundColor() {
    if (isToday && intensityLevel >= 1) return themeProvider.primaryColor;
    if (isToday && intensityLevel == 0) return Colors.grey[100]!;
    switch (intensityLevel) {
      case 1:
        return themeProvider.primaryColor.withOpacity(0.18);
      case 2:
        return themeProvider.primaryColor.withOpacity(0.45);
      case 3:
        return themeProvider.primaryColor.withOpacity(0.78);
      default:
        return Colors.grey[100]!;
    }
  }

  List<BoxShadow>? _getBoxShadow() {
    if (!isToday) return null;
    // 오늘 + 학습: 흰색 링 (주제색 배경 위에서 잘 보임)
    // 오늘 + 미학습: 주제색 링 (회색 배경 위에서 잘 보임)
    final ringColor = intensityLevel >= 1
        ? Colors.white.withOpacity(0.85)
        : themeProvider.primaryColor;
    return [
      BoxShadow(
        color: ringColor,
        spreadRadius: 2,
        blurRadius: 0,
        offset: Offset.zero,
      ),
    ];
  }

  Color _getTextColor() {
    if (isFuture) return Colors.grey[300]!;
    if (isToday && intensityLevel == 0) return themeProvider.primaryColor;
    if (intensityLevel == 0) return Colors.grey[400]!;
    return Colors.white;
  }

  Widget _buildCellContent() {
    if (intensityLevel > 0) {
      return FractionallySizedBox(
        widthFactor: 0.68,
        heightFactor: 0.68,
        child: Image.asset(
          'assets/FrogCharacter/FROG_STAMP.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const StandardText(
            text: '🐸',
            fontSize: 10,
            color: Colors.white,
          ),
        ),
      );
    }
    return StandardText(
      text: '$day',
      fontSize: 11,
      color: _getTextColor(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          boxShadow: _getBoxShadow(),
        ),
        child: Center(child: _buildCellContent()),
      ),
    );
  }
}
