import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/*
  날짜 선택기를 출력해주는 클래스
 */

class DatePickerHandler extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  DatePickerHandler({required this.initialDate, required this.onDateSelected});

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

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 3,
      child: Column(
        children: <Widget>[
          // 상단 완료 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 10), // 왼쪽 여백
              const Spacer(), // 가운데 비우기
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 날짜 선택 창 닫기
                },
                child: const Text('완료',
                    style: TextStyle(fontSize: 16, color: Colors.blue)),
              ),
            ],
          ),
          // 상단 마킹
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: const Text('년도', style: TextStyle(fontSize: 16)),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: const Text('월', style: TextStyle(fontSize: 16)),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Text('일', style: TextStyle(fontSize: 16)),
                ),
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
                        widget.onDateSelected(_selectedDate);
                      });
                    },
                    children: _years.map((int year) {
                      return Center(
                        child: Text('$year'),
                      );
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
                        widget.onDateSelected(_selectedDate);
                      });
                    },
                    children: _months.map((int month) {
                      return Center(
                        child: Text('$month'),
                      );
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
                        widget.onDateSelected(_selectedDate);
                      });
                    },
                    children: _days.map((int day) {
                      return Center(
                        child: Text('$day'),
                      );
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
