import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../Module/Text/mobile_font_size.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Motion/AppHaptic.dart';
import '../../../Module/Motion/PressableScale.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Design/AppColors.dart';

class DatePickerHandler extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;
  final String title;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DatePickerHandler({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
    this.title = '푼 날짜 선택',
    this.firstDate,
    this.lastDate,
  });

  @override
  State<DatePickerHandler> createState() => _DatePickerHandlerState();
}

class _DatePickerHandlerState extends State<DatePickerHandler> {
  static const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];
  static const _gridSpacing = 6.0;

  /// 가로 폰에서 칸을 낮출 때의 하한. 날짜 숫자 한 줄이 들어가는 높이다.
  /// 이보다 낮춰야 들어가는 화면에서는 칸을 더 줄이지 않고 달력만 스크롤한다.
  static const _minCellHeight = 28.0;
  static const _compactHeight = 500.0;

  late DateTime _visibleMonth;
  late final DateTime _firstSelectableDate;
  late final DateTime _lastSelectableDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _firstSelectableDate =
        _dateOnly(widget.firstDate ?? DateTime(now.year - 10, now.month));
    _lastSelectableDate = _dateOnly(widget.lastDate ?? today);
    _visibleMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  bool get _canGoPrev => DateTime(_visibleMonth.year, _visibleMonth.month)
      .isAfter(DateTime(_firstSelectableDate.year, _firstSelectableDate.month));

  bool get _canGoNext => DateTime(_visibleMonth.year, _visibleMonth.month)
      .isBefore(DateTime(_lastSelectableDate.year, _lastSelectableDate.month));

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    // 가로로 둔 폰처럼 높이가 낮은 화면. 여백을 줄여 달력 칸에 높이를 더 준다.
    // 세로 폰과 태블릿은 높이가 이보다 커서 원래 모습 그대로다.
    final compact = MediaQuery.sizeOf(context).height < _compactHeight;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: compact ? 8 : 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              StandardText(
                text: widget.title,
                fontSize: MobileFontSize.reduced(context, 17),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              SizedBox(height: compact ? 4 : 16),
              Row(
                children: [
                  IconButton(
                    visualDensity: compact ? VisualDensity.compact : null,
                    onPressed: _canGoPrev ? () => _changeMonth(-1) : null,
                    icon: Icon(
                      Icons.chevron_left,
                      color: _canGoPrev ? primaryColor : Colors.grey[300],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: StandardText(
                        text:
                            '${_visibleMonth.year}.${_visibleMonth.month.toString().padLeft(2, '0')}',
                        fontSize: MobileFontSize.reduced(context, 16),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: compact ? VisualDensity.compact : null,
                    onPressed: _canGoNext ? () => _changeMonth(1) : null,
                    icon: Icon(
                      Icons.chevron_right,
                      color: _canGoNext ? primaryColor : Colors.grey[300],
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 4 : 8),
              _buildWeekdayHeader(),
              SizedBox(height: compact ? 4 : 8),
              // 남은 높이를 달력에 넘겨 준다. 내용이 짧으면 원래 크기 그대로다.
              Flexible(child: _buildDateGrid(primaryColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    return Row(
      children: _weekdayLabels.map((label) {
        return Expanded(
          child: Center(
            child: StandardText(
              text: label,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500]!,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateGrid(Color primaryColor) {
    final firstWeekday =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday % 7;
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final totalCells = firstWeekday + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    // 칸은 폭으로 정한 정사각형이다. 가로 폰은 시트가 폭 640 까지 넓어지는데
    // 높이는 390 이 안 돼서, 정사각형 그대로면 3주차 이후가 시트 밖으로 밀려
    // 누를 수 없었다. 남은 높이에 안 들어갈 때만 칸 높이를 낮춘다.
    return LayoutBuilder(builder: (context, constraints) {
      final cellWidth = (constraints.maxWidth - _gridSpacing * 6) / 7;
      final spacingHeight = _gridSpacing * (rowCount - 1);
      var childAspectRatio = 1.0;
      var scrollable = false;
      if (constraints.hasBoundedHeight &&
          cellWidth * rowCount + spacingHeight > constraints.maxHeight) {
        final fittedHeight = (constraints.maxHeight - spacingHeight) / rowCount;
        childAspectRatio = cellWidth / math.max(fittedHeight, _minCellHeight);
        scrollable = fittedHeight < _minCellHeight;
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: scrollable
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: rowCount * 7,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: _gridSpacing,
          crossAxisSpacing: _gridSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (_, index) {
          final day = index - firstWeekday + 1;
          if (day < 1 || day > daysInMonth) {
            return const SizedBox.shrink();
          }

          final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
          final selectable = !date.isBefore(_firstSelectableDate) &&
              !date.isAfter(_lastSelectableDate);
          final isSelected = DateUtils.isSameDay(date, widget.initialDate);
          final isToday = DateUtils.isSameDay(date, DateTime.now());

          return PressableScale(
            haptic: HapticLevel.selection,
            enabled: selectable,
            onTap: selectable ? () => widget.onDateSelected(date) : null,
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor
                    : selectable
                        ? Colors.grey[100]
                        : Colors.grey[50],
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : isToday
                          ? primaryColor.withOpacity(0.6)
                          : selectable
                              ? Colors.grey[200]!
                              : Colors.transparent,
                  width: isToday && !isSelected ? 1.4 : 1,
                ),
              ),
              child: Center(
                child: StandardText(
                  text: '$day',
                  fontSize: MobileFontSize.reduced(context, 13),
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : selectable
                          ? Colors.black87
                          : Colors.grey[300]!,
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
