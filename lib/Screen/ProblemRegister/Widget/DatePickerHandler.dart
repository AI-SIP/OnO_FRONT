import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../Module/Text/StandardText.dart';

class DatePickerHandler extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const DatePickerHandler(
      {super.key, required this.initialDate, required this.onDateSelected});

  @override
  _DatePickerHandlerState createState() => _DatePickerHandlerState();
}

class _DatePickerHandlerState extends State<DatePickerHandler> {
  late DateTime _selectedDate;

  final List<int> _years =
      List<int>.generate(101, (int index) => 2020 + index); // 2020부터 2120까지
  final List<int> _months =
      List<int>.generate(12, (int index) => index + 1); // 1부터 12까지
  final List<int> _days =
      List<int>.generate(31, (int index) => index + 1); // 1부터 31까지

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  int _clampDay(int year, int month, int day) {
    final maxDay = _daysInMonth(year, month);
    if (day < 1) return 1;
    if (day > maxDay) return maxDay;
    return day;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      child: Container(
        color: Colors.white,
        height: 360,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const StandardText(
                      text: '취소',
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                  const Spacer(),
                  const StandardText(
                    text: '푼 날짜 선택',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _selectedDate),
                    child: StandardText(
                      text: '완료',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(color: Colors.grey[200], height: 1),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: StandardText(
                        text: '년도',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: StandardText(
                        text: '월',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: StandardText(
                        text: '일',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: <Widget>[
                    _buildPickerColumn(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _selectedDate.year - 2020,
                        ),
                        itemExtent: 34.0,
                        useMagnifier: true,
                        magnification: 1.06,
                        onSelectedItemChanged: (int index) {
                          setState(() {
                            final year = _years[index];
                            final day = _clampDay(
                              year,
                              _selectedDate.month,
                              _selectedDate.day,
                            );
                            _selectedDate =
                                DateTime(year, _selectedDate.month, day);
                          });
                        },
                        children: _years.map((int year) {
                          return Center(
                            child: StandardText(
                              text: '$year',
                              fontSize: 17,
                              color: Colors.black87,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildPickerColumn(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _selectedDate.month - 1,
                        ),
                        itemExtent: 34.0,
                        useMagnifier: true,
                        magnification: 1.06,
                        onSelectedItemChanged: (int index) {
                          setState(() {
                            final month = _months[index];
                            final day = _clampDay(
                              _selectedDate.year,
                              month,
                              _selectedDate.day,
                            );
                            _selectedDate =
                                DateTime(_selectedDate.year, month, day);
                          });
                        },
                        children: _months.map((int month) {
                          return Center(
                            child: StandardText(
                              text: '$month',
                              fontSize: 17,
                              color: Colors.black87,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildPickerColumn(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _selectedDate.day - 1,
                        ),
                        itemExtent: 34.0,
                        useMagnifier: true,
                        magnification: 1.06,
                        onSelectedItemChanged: (int index) {
                          setState(() {
                            final requestedDay = _days[index];
                            final day = _clampDay(
                              _selectedDate.year,
                              _selectedDate.month,
                              requestedDay,
                            );
                            _selectedDate = DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              day,
                            );
                          });
                        },
                        children: _days.map((int day) {
                          return Center(
                            child: StandardText(
                              text: '$day',
                              fontSize: 17,
                              color: Colors.black87,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerColumn({required Widget child}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: child,
      ),
    );
  }
}
