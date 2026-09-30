import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Provider/CosmeticProvider.dart';
import 'Widget/CalendarDaySheet.dart';
import 'Widget/CalendarMonthSheet.dart';
import 'Widget/DiaryPage.dart';
import 'Widget/DiaryTheme.dart';
import '../../Model/StudyCalendar/StudyCalendarModel.dart';
import '../../Module/Emoji/OnoEmojiCategory.dart';
import '../../Module/Emoji/OnoEmojiPicker.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Service/Api/StudyCalendar/StudyCalendarService.dart';
import '../../Util/AppSnackBar.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/Skeleton.dart';
import '../../Module/Motion/TossDialog.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppToast.dart';
import '../../Util/AppAnalytics.dart';

class LearningCalendarScreen extends StatefulWidget {
  /// 테스트에서 가짜 서비스를 넣기 위한 것이다. 앱에서는 넘기지 않는다.
  final StudyCalendarService? service;

  const LearningCalendarScreen({super.key, this.service});

  /// 연월 선택 창에서 달 칸과 연도 화살표를 찾는 키. 테스트에서 쓴다.
  static Key monthPickerMonthKey(int month) => Key('month_picker_$month');
  static const Key monthPickerPrevYearKey = Key('month_picker_prev_year');
  static const Key monthPickerNextYearKey = Key('month_picker_next_year');

  @override
  State<LearningCalendarScreen> createState() => _LearningCalendarScreenState();
}

class _LearningCalendarScreenState extends State<LearningCalendarScreen> {
  late int _year;
  late int _month;
  StudyCalendarModel? _calendarData;
  bool _isLoading = true;
  int? _selectedDay;

  /// 고른 날의 일기. 불러오는 중이면 null, 안 쓴 날이면 빈 문자열이다.
  String? _diaryText;
  int _loadDiarySeq = 0;

  /// 이 달에서 일기를 쓴 날들. 달력 칸에 연필 표시를 단다.
  Set<int> _diaryDays = const {};
  int _loadDiaryDaysSeq = 0;

  late final StudyCalendarService _service =
      widget.service ?? StudyCalendarService();

  /// 마지막 달력 조회가 실패했는지. 머리 문장 자리에 `다시 불러오기` 를 띄운다.
  bool _loadFailed = false;

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
    AppAnalytics.logScreenView('LearningCalendarScreen');
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    // 들어오자마자 오늘 일기를 쓸 수 있게 오늘을 골라 둔다. 아무 날도 안 고른
    // 채로 열면 일기 칸이 아예 보이지 않아 당일에는 쓸 곳이 없는 줄 알았다.
    _selectedDay = now.day;
    _loadCalendar();
    _loadDiary(_year, _month, now.day);
  }

  String _diaryKey(int year, int month, int day) =>
      '${_diaryMonthPrefix(year, month)}$day';

  String _diaryMonthPrefix(int year, int month) =>
      'diary_text_${year}_${month}_';

  Future<void> _loadDiaryDays() async {
    final seq = ++_loadDiaryDaysSeq;
    final year = _year;
    final month = _month;
    final prefs = await SharedPreferences.getInstance();
    final prefix = _diaryMonthPrefix(year, month);
    final days = <int>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(prefix)) continue;
      final day = int.tryParse(key.substring(prefix.length));
      if (day != null) days.add(day);
    }
    if (!mounted || seq != _loadDiaryDaysSeq) return;
    setState(() => _diaryDays = days);
  }

  Future<void> _loadDiary(int year, int month, int day) async {
    final seq = ++_loadDiarySeq;
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_diaryKey(year, month, day)) ?? '';
    if (!mounted || seq != _loadDiarySeq) return;
    setState(() => _diaryText = text);
  }

  Future<bool> _saveDiary(int year, int month, int day, String text) async {
    final isChange = (_diaryText ?? '').isNotEmpty;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _diaryKey(year, month, day);
      if (text.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, text);
      }
    } catch (_) {
      if (mounted) {
        AppToast.show(
          message: '일기를 저장하지 못했어요.',
          type: ToastType.error,
          context: context,
        );
      }
      return false;
    }
    if (!mounted) return true;
    AppAnalytics.logEvent('calendar_diary_saved', {
      'is_delete': text.isEmpty,
      'is_change': isChange,
      'length': text.length,
    });
    setState(() {
      // 저장하는 사이 다른 날이나 다른 달로 옮겨 갔으면 지금 보는 쪽을 덮지 않는다.
      if (_year == year && _month == month) {
        if (_selectedDay == day) _diaryText = text;
        final days = {..._diaryDays};
        if (text.isEmpty) {
          days.remove(day);
        } else {
          days.add(day);
        }
        _diaryDays = days;
      }
    });
    AppToast.show(
      message: text.isEmpty ? '일기를 지웠어요.' : '일기를 남겼어요.',
      type: ToastType.success,
      context: context,
    );
    return true;
  }

  Future<void> _loadCalendar() async {
    setState(() => _isLoading = true);
    _loadDiaryDays();
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
          _loadFailed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadFailed = true;
        });
        AppSnackBar.showError('학습 달력을 불러오지 못했어요.');
      }
    }
  }

  void _prevMonth() {
    // 지난 달을 얼마나 거슬러 보는지. 달력을 기록 보관용으로 쓰는지 본다.
    AppAnalytics.logEvent('calendar_month_change', {'direction': 'prev'});
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
    AppAnalytics.logEvent('calendar_month_change', {'direction': 'next'});
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

  /// 두 장을 좌우로 펼칠지. 폭이 넉넉한 가로 태블릿에서만 편다. 세로
  /// 태블릿은 폭이 900 에 못 미쳐 폰처럼 위아래로 쌓는다.
  static bool _isSpread(BuildContext context, double width) =>
      width >= 900 &&
      MediaQuery.orientationOf(context) == Orientation.landscape;

  /// 펼쳤을 때 왼쪽 달력 장의 폭. 시안 값이다.
  static const double _spreadCalendarWidth = 560;

  /// 쌓았을 때 두 장의 최대 폭. 세로 태블릿에서 종이가 화면 끝까지 늘어나면
  /// 일기장이 아니라 게시판처럼 보인다.
  static const double _stackedMaxWidth = 640;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final ink = DiaryInk.of(themeProvider.primaryColor);

    return Scaffold(
      backgroundColor: ink.desk,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: StandardText(
          text: '학습 달력',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final spread = _isSpread(context, constraints.maxWidth);
          final padding = spread
              ? const EdgeInsets.fromLTRB(28, 14, 28, 28)
              : const EdgeInsets.fromLTRB(12, 14, 12, 28);
          final first = _isLoading
              ? _PaperSkeleton(ink: ink, height: 440, withHead: true)
              : _buildMonthSheet(ink);
          final second = _isLoading
              ? _PaperSkeleton(ink: ink, height: 280)
              : _buildDaySheet(ink, themeProvider);

          // 두 장이 따로 스크롤하지 않고 화면 전체가 하나로 스크롤한다.
          return SingleChildScrollView(
            padding: padding,
            child: spread
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: _spreadCalendarWidth, child: first),
                      const SizedBox(width: 20),
                      Expanded(child: second),
                    ],
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _stackedMaxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [first, const SizedBox(height: 20), second],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  /// 달력을 못 불러왔으면 null. 실패한 뒤에 전 달의 결과가 남아 있어도
  /// 그 숫자를 이 달 것처럼 적지 않게 여기서 한 번 거른다.
  StudyCalendarModel? get _shownCalendar => _loadFailed ? null : _calendarData;

  Widget _buildMonthSheet(DiaryInk ink) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    return CalendarMonthSheet(
      ink: ink,
      year: _year,
      month: _month,
      today: DateTime.now(),
      data: _shownCalendar,
      selectedDay: _selectedDay,
      diaryDays: _diaryDays,
      large: MediaQuery.sizeOf(context).shortestSide >= 600,
      onPrevMonth: _prevMonth,
      onNextMonth: _isCurrentMonth ? null : _nextMonth,
      onPickMonth: () => _showMonthPicker(themeProvider),
      onRetry: _loadCalendar,
      onDayTap: (day) {
        final newDay = (_selectedDay == day) ? null : day;
        setState(() {
          _selectedDay = newDay;
          _diaryText = null;
        });
        if (newDay != null) {
          _loadDiary(_year, _month, newDay);
        }
      },
    );
  }

  Widget _buildDaySheet(DiaryInk ink, ThemeHandler themeProvider) {
    final day = _selectedDay;
    if (day == null) {
      // 날짜를 풀면 둘째 장이 통째로 사라져 태블릿 오른쪽이 텅 빈다. 무엇을
      // 누르면 되는지 한 줄 적어 둔다.
      return DiarySheet(
        edgeColor: ink.edge,
        child: HandText(
          '날짜를 누르면 그날의 기록과 일기가 여기에 적혀요',
          size: 17,
          color: ink.soft,
        ),
      );
    }

    // 일기는 기기에만 있으므로 달력 조회에 실패해도 쓸 수 있어야 한다.
    // 학습 기록은 조회가 된 때만 보인다.
    final calendarData = _shownCalendar;
    final record = calendarData?.recordFor(day);
    final date = DateTime(_year, _month, day);
    final weekdayName = _dayOfWeekNames[date.weekday % 7];
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return CalendarDaySheet(
      ink: ink,
      date: date,
      isToday: isToday,
      weekdayName: weekdayName,
      showRecord: calendarData != null,
      record: record,
      onMoodTap: record == null ? null : () => _showMoodPicker(record),
      diary: DiaryPage(
        // 날짜마다 쓰던 상태를 따로 둔다. 다른 날로 옮기면 입력칸이 닫힌다.
        key: ValueKey('diary_${_year}_${_month}_$day'),
        embedded: true,
        ink: ink,
        savedText: _diaryText,
        date: date,
        weekdayName: weekdayName,
        moodEmojiKey: record?.moodEmojiKey,
        frogLayers: context.watch<CosmeticProvider>().layersWithoutBackdrop,
        primaryColor: themeProvider.primaryColor,
        onSave: (text) => _saveDiary(_year, _month, day, text),
      ),
    );
  }

  void _showMonthPicker(ThemeHandler themeProvider) {
    int pickerYear = _year;
    final now = DateTime.now();
    // 학습 달력 화면과 같은 종이, 테이프, 손글씨로 그린다. 흰 다이얼로그에
    // 회색 칩이면 달력을 펼쳐 둔 일기장 위에 딴 물건이 뜬 것처럼 보였다.
    final ink = DiaryInk.of(themeProvider.primaryColor);

    showTossDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final canGoNextYear = pickerYear < now.year;
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ConstrainedBox(
                // 태블릿에서 달 칸이 옆으로 늘어나 흩어지지 않게 폭을 묶는다.
                constraints: const BoxConstraints(maxWidth: 360),
                child: DiarySheet(
                  edgeColor: ink.edge,
                  tapeColor: ink.tape,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 연도 선택
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PickerArrow(
                            key: LearningCalendarScreen.monthPickerPrevYearKey,
                            label: '지난해',
                            glyph: InkGlyph.chevronLeft,
                            color: ink.ink,
                            onTap: () => setDialogState(() => pickerYear--),
                          ),
                          const SizedBox(width: 12),
                          HandText('$pickerYear년', size: 23, color: ink.ink),
                          const SizedBox(width: 12),
                          Opacity(
                            opacity: canGoNextYear ? 1 : 0.3,
                            child: _PickerArrow(
                              key:
                                  LearningCalendarScreen.monthPickerNextYearKey,
                              label: '다음 해',
                              glyph: InkGlyph.chevronRight,
                              color: ink.ink,
                              onTap: canGoNextYear
                                  ? () => setDialogState(() => pickerYear++)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 월 그리드 (4열 × 3행)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisExtent: 48,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: 12,
                        itemBuilder: (_, index) {
                          final month = index + 1;
                          final isFuture = pickerYear > now.year ||
                              (pickerYear == now.year && month > now.month);
                          final isSelected =
                              pickerYear == _year && month == _month;
                          final isThisMonth =
                              pickerYear == now.year && month == now.month;

                          return PressableScale(
                            key: LearningCalendarScreen.monthPickerMonthKey(
                                month),
                            haptic: HapticLevel.selection,
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
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ink.levelFill(2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                                border: isThisMonth && !isSelected
                                    ? Border.all(color: ink.ink, width: 1.5)
                                    : null,
                              ),
                              child: HandText(
                                '$month월',
                                size: 19,
                                color: isFuture
                                    ? ink.faint
                                    : isSelected
                                        ? ink.numberOn(2)
                                        : ink.ink,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMoodPicker(DailyStudyRecord record) {
    OnoEmojiPicker.show(
      context,
      categories: const [
        OnoEmojiCategory.emotion,
        OnoEmojiCategory.study,
        OnoEmojiCategory.cheer,
      ],
      selectedKey: record.moodEmojiKey,
      onSelected: (emoji) async {
        try {
          await _service.updateMoodEmoji(
            date: record.date,
            emojiKey: emoji.key,
            showErrorSnackBar: false,
          );
          AppAnalytics.logEvent('mood_set', {
            'mood': emoji.key,
            'is_change': record.moodEmojiKey != null,
          });
          if (!mounted) return;
          await _loadCalendar();
        } catch (_) {
          if (!mounted) return;
          AppSnackBar.showError('감정을 저장하지 못했어요.');
        }
      },
    );
  }
}

/// 불러오는 동안 놓는 종이 한 장 모양의 자리. 회색 막대 대신 종이 위에 옅은
/// 테마 색 자국처럼 보이게 해서, 다 불러온 뒤 같은 자리에 같은 종이가 놓인다.
class _PaperSkeleton extends StatelessWidget {
  final DiaryInk ink;
  final double height;

  /// 첫 장처럼 프로필과 문장 자리를 그릴지.
  final bool withHead;

  const _PaperSkeleton({
    required this.ink,
    required this.height,
    this.withHead = false,
  });

  @override
  Widget build(BuildContext context) {
    final base =
        Color.alphaBlend(ink.theme.withValues(alpha: 0.08), DiaryPaper.paper);
    final shine =
        Color.alphaBlend(ink.theme.withValues(alpha: 0.03), DiaryPaper.paper);
    Widget box({double? width, required double height, double radius = 8}) =>
        SkeletonBox(
          width: width,
          height: height,
          borderRadius: radius,
          baseColor: base,
          highlightColor: shine,
        );

    return DiarySheet(
      edgeColor: ink.edge,
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (withHead) ...[
              Row(
                children: [
                  box(width: 58, height: 58, radius: 29),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        box(width: 150, height: 26),
                        const SizedBox(height: 8),
                        box(width: 180, height: 14),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
            ] else ...[
              box(width: 110, height: 26),
              const SizedBox(height: 18),
            ],
            Expanded(child: box(height: double.infinity, radius: 14)),
          ],
        ),
      ),
    );
  }
}

/// 연월 선택 창의 연도 화살표. 누르는 자리는 44 를 지킨다.
class _PickerArrow extends StatelessWidget {
  final String label;
  final InkGlyph glyph;
  final Color color;
  final VoidCallback? onTap;

  const _PickerArrow({
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
