import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import 'DatePickerHandler.dart';

class DatePickerWidget extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  const DatePickerWidget({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeHandler>(context);

    return Row(
      children: [
        Icon(Icons.calendar_today, color: theme.primaryColor),
        const SizedBox(width: 6),
        StandardText(
          text: '푼 날짜',
          fontSize: 16,
          color: theme.primaryColor,
        ),
        const Spacer(),
        TextButton(
          onPressed: () async {
            FirebaseAnalytics.instance.logEvent(name: 'date_select');
            final d = await showModalBottomSheet<DateTime>(
              context: context,
              builder: (_) => DatePickerHandler(
                initialDate: selectedDate,
                onDateSelected: (d) => Navigator.pop(context, d),
              ),
            );
            if (d != null) onDateChanged(d);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            side: BorderSide(color: theme.primaryColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: StandardText(
            text:
                '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
            fontSize: 14,
            color: theme.primaryColor,
          ),
        ),
      ],
    );
  }
}
