import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class ActionButtons extends StatelessWidget {
  final bool isEdit;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const ActionButtons({
    Key? key,
    required this.isEdit,
    required this.onCancel,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeHandler>(context);
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onCancel,
            style: ElevatedButton.styleFrom(
              padding:
                  EdgeInsets.symmetric(horizontal: w * .02, vertical: h * .012),
              backgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const StandardText(text: '취소하기', color: Colors.white),
          ),
        ),
        const SizedBox(width: 25),
        Expanded(
          child: ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              padding:
                  EdgeInsets.symmetric(horizontal: w * .02, vertical: h * .012),
              backgroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: StandardText(
              text: isEdit ? '수정 완료' : '문제 등록',
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
