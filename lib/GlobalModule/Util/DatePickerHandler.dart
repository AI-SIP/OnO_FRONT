import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../Theme/StandardText.dart';
import '../Theme/ThemeHandler.dart';

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

  final List<int> _years = List<int>.generate(101, (int index) => 2020 + index); // 2020부터 2120까지
  final List<int> _months = List<int>.generate(12, (int index) => index + 1); // 1부터 12까지
  final List<int> _days = List<int>.generate(31, (int index) => index + 1); // 1부터 31까지

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height / 3,
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 10), // 왼쪽 여백
              const Spacer(), // 가운데 비우기
              TextButton(
                  onPressed: () {
                    // 완료 버튼을 누르면 선택한 날짜만 전달하고 모달 닫기
                    if (Navigator.of(context).canPop()) {
                      Navigator.pop(context, _selectedDate);
                    }
                  },
                  child: StandardText(
                    text: '완료',
                    fontSize: 16,
                    color: themeProvider.primaryColor,
                  )),
            ],
          ),
          // 상단 마킹
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Align(
                    alignment: Alignment.center,
                    child: StandardText(
                        text: '년도', fontSize: 16, color: themeProvider.primaryColor)),
              ),
              Expanded(
                child: Align(
                    alignment: Alignment.center,
                    child: StandardText(
                        text: '월', fontSize: 16, color: themeProvider.primaryColor)),
              ),
              Expanded(
                child: Align(
                    alignment: Alignment.center,
                    child: StandardText(
                        text: '일', fontSize: 16, color: themeProvider.primaryColor)),
              ),
            ],
          ),
          const SizedBox(height: 8), // 텍스트 아래에 약간의 여백 추가
          // 날짜 선택기
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: _selectedDate.year - 2020,
                    ),
                    itemExtent: 32.0,
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        _selectedDate = DateTime(
                          _years[index],
                          _selectedDate.month,
                          _selectedDate.day,
                        );
                      });
                    },
                    children: _years.map((int year) {
                      return Center(
                          child: StandardText(
                              text: '$year', fontSize: 16, color: themeProvider.primaryColor));
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: _selectedDate.month - 1,
                    ),
                    itemExtent: 32.0,
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _months[index],
                          _selectedDate.day,
                        );
                      });
                    },
                    children: _months.map((int month) {
                      return Center(
                          child: StandardText(
                              text: '$month', fontSize: 16, color: themeProvider.primaryColor));
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: _selectedDate.day - 1,
                    ),
                    itemExtent: 32.0,
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _days[index],
                        );
                      });
                    },
                    children: _days.map((int day) {
                      return Center(
                          child: StandardText(
                              text: '$day', fontSize: 16, color: themeProvider.primaryColor));
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}