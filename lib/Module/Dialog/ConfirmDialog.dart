import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Design/AppColors.dart';
import '../Design/AppRadius.dart';
import '../Motion/TossDialog.dart';
import '../Text/StandardText.dart';
import '../Theme/ThemeHandler.dart';

/// 무언가를 하기 전에 한 번 묻는 공용 확인 창. 확정을 누르면 true 다.
///
/// 그동안 화면마다 Dialog 를 직접 만들어서 모양과 버튼 이름이 제각각이었다.
/// 확정 버튼은 '확인' 대신 무엇을 하는지 동사로 적는다(삭제하기, 로그아웃,
/// 나가기). [destructive] 면 확정 버튼을 빨갛게 칠한다.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String cancelLabel = '취소',
  bool destructive = false,
  IconData? icon,
  Color? accentColor,
}) async {
  final result = await showTossDialog<bool>(
    context: context,
    builder: (_) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
      icon: icon,
      accentColor: accentColor,
    ),
  );
  return result == true;
}

/// 사용자가 고른 테마 색. 테마를 찾지 못하면 앱 기본 색을 쓴다.
Color _themeColor(BuildContext context) {
  try {
    return Provider.of<ThemeHandler>(context, listen: false).primaryColor;
  } catch (_) {
    return Theme.of(context).colorScheme.primary;
  }
}

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final IconData? icon;
  final Color? accentColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    this.message,
    required this.confirmLabel,
    this.cancelLabel = '취소',
    this.destructive = false,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? Colors.red : (accentColor ?? _themeColor(context));
    final iconData =
        icon ?? (destructive ? Icons.delete_outline : Icons.help_outline);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              StandardText(
                text: title,
                fontSize: 17,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: 10),
                StandardText(
                  text: message!,
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[50],
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          side: BorderSide(color: Colors.grey[200]!, width: 1),
                        ),
                      ),
                      child: StandardText(
                        text: cancelLabel,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        backgroundColor: color,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                      ),
                      child: StandardText(
                        text: confirmLabel,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
