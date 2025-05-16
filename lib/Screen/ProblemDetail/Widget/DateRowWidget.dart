import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../Module/Text/HandWriteText.dart';
import '../../../Module/Text/UnderlinedText.dart';

Widget buildDateRow(DateTime dt, Color iconColor) {
  final date = DateFormat('yyyy년 M월 d일').format(dt);
  return Row(children: [
    Icon(Icons.calendar_today, color: iconColor),
    const SizedBox(width: 8),
    HandWriteText(text: '푼 날짜', fontSize: 20, color: iconColor),
    const Spacer(),
    UnderlinedText(text: date, fontSize: 18),
  ]);
}

/// 문제 출처 행
Widget buildReferenceRow(String? ref, Color iconColor) => Row(children: [
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.info, color: iconColor),
          const SizedBox(width: 8),
          HandWriteText(text: '문제 출처', fontSize: 20, color: iconColor),
        ]),
        const SizedBox(height: 10),
        UnderlinedText(
            text: (ref?.isNotEmpty == true) ? ref! : '작성한 출처가 없습니다!',
            fontSize: 18),
      ]))
    ]);

/// 한 줄 메모 섹션
Widget buildMemoSection(String? memo, Color iconColor) => Padding(
      padding: const EdgeInsets.all(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.edit, color: iconColor),
          const SizedBox(width: 8),
          HandWriteText(text: '한 줄 메모', fontSize: 20, color: iconColor),
        ]),
        const SizedBox(height: 8),
        UnderlinedText(
            text: (memo?.isNotEmpty == true) ? memo! : '작성한 메모가 없습니다!'),
      ]),
    );
