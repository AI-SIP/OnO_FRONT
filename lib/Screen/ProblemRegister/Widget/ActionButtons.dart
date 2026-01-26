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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onSubmit,
        style: ElevatedButton.styleFrom(
          padding:
              EdgeInsets.symmetric(horizontal: w * .01, vertical: h * .007),
          backgroundColor: theme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: StandardText(
          text: isEdit ? '수정 완료' : '작성 완료',
          color: Colors.white,
          fontSize: 15,
        ),
      ),
    );
  }
}
