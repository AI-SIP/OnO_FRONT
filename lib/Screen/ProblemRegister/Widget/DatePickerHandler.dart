import 'package:flutter/material.dart';

import '../../../Module/Text/StandardText.dart';

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
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              StandardText(
                text: widget.title,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _canGoNext ? () => _changeMonth(1) : null,
                    icon: Icon(
                      Icons.chevron_right,
                      color: _canGoNext ? primaryColor : Colors.grey[300],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildWeekdayHeader(),
              const SizedBox(height: 8),
              _buildDateGrid(primaryColor),
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rowCount * 7,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
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

        return InkWell(
          onTap: selectable ? () => widget.onDateSelected(date) : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor
                  : selectable
                      ? Colors.grey[100]
                      : Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
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
                fontSize: 13,
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
  }
}
