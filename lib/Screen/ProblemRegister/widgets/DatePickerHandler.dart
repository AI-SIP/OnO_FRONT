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

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0), // 좌우 여백 추가
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0), // 모서리를 둥글게 처리
        child: Container(
          color: Colors.white,
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
                    child: const StandardText(
                      text: '완료',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 10), // 오른쪽 여백
                ],
              ),
              const SizedBox(height: 20),
              // 상단 마킹
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: StandardText(
                        text: '년도',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: StandardText(
                        text: '월',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: StandardText(
                        text: '일',
                        fontSize: 16,
                        color: Colors.black,
                      ),
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
                          });
                        },
                        children: _years.map((int year) {
                          return Center(
                            child: StandardText(
                              text: '$year',
                              fontSize: 16,
                              color: Colors.black,
                            ),
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
                          });
                        },
                        children: _months.map((int month) {
                          return Center(
                            child: StandardText(
                              text: '$month',
                              fontSize: 16,
                              color: Colors.black,
                            ),
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
                          });
                        },
                        children: _days.map((int day) {
                          return Center(
                            child: StandardText(
                              text: '$day',
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
