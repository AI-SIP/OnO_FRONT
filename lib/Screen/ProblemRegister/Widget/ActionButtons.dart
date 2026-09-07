import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Module/Motion/AppHaptic.dart';
import '../../../Module/Motion/PressableScale.dart';
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
    // 작성이 끝나는 자리라 물결 효과 대신 눌림 축소와 진동을 준다.
    return PressableScale(
      onTap: onSubmit,
      haptic: HapticLevel.primary,
      child: Container(
        width: double.infinity,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: StandardText(
          text: isEdit ? '수정 완료' : '작성 완료',
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
