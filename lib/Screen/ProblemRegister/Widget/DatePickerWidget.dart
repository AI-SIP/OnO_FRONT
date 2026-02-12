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

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              Icons.calendar_today,
              color: theme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: StandardText(
              text: '푼 날짜',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          GestureDetector(
            onTap: () async {
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
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StandardText(
                    text:
                        '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}