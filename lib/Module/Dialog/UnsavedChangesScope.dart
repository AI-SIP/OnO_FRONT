import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../Util/AppAnalytics.dart';
import '../Design/AppColors.dart';
import '../Design/AppRadius.dart';
import '../Motion/TossDialog.dart';
import '../Text/StandardText.dart';

/// 쓰던 내용이 있으면 뒤로 가기 전에 정말 나갈지 묻는다.
///
/// 앱바 뒤로가기, 안드로이드 뒤로가기, iOS 밀어서 뒤로가기를 모두 막는다.
/// 쓴 것이 없으면 그냥 나간다. 저장이 끝나 화면이 스스로 닫을 때 쓰는
/// `Navigator.pop` 은 막지 않는다.
///
/// 쓴 것이 있는지 화면이 다시 그려질 때마다 알 수 있으면 [hasChanges] 를
/// 넘긴다. 그러면 쓴 것이 없을 때는 iOS 밀어서 뒤로가기가 그대로 살아 있다.
/// 필기처럼 화면을 다시 그리지 않고 바뀌는 것은 [checkChanges] 를 넘긴다.
/// 이때는 늘 막아 두고, 나가려는 순간에 확인한다.
class UnsavedChangesScope extends StatelessWidget {
  final ValueListenable<bool>? hasChanges;
  final bool Function()? checkChanges;
  final Widget child;

  /// 애널리틱스에 남길 화면 이름.
  final String source;
  final String title;
  final String description;

  const UnsavedChangesScope({
    super.key,
    required ValueListenable<bool> this.hasChanges,
    required this.child,
    required this.source,
    this.title = '작성을 그만둘까요?',
    this.description = '지금 나가면 쓰던 내용이 저장되지 않아요.',
  }) : checkChanges = null;

  const UnsavedChangesScope.check({
    super.key,
    required bool Function() this.checkChanges,
    required this.child,
    required this.source,
    this.title = '작성을 그만둘까요?',
    this.description = '지금 나가면 쓰던 내용이 저장되지 않아요.',
  }) : hasChanges = null;

  @override
  Widget build(BuildContext context) {
    final hasChanges = this.hasChanges;
    if (hasChanges == null) {
      return _buildScope(context, canPop: false);
    }
    return ValueListenableBuilder<bool>(
      valueListenable: hasChanges,
      builder: (context, changed, _) => _buildScope(context, canPop: !changed),
    );
  }

  Widget _buildScope(BuildContext context, {required bool canPop}) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final changed = hasChanges?.value ?? checkChanges?.call() ?? false;
        if (!changed) {
          Navigator.of(context).pop();
          return;
        }
        final leave = await confirmLeave(
          context,
          source: source,
          title: title,
          description: description,
        );
        if (leave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}

/// 쓰던 내용을 버리고 나갈지 묻는다. 나가기를 고르면 true 다.
///
/// 뒤로 가기가 아니라 단계를 되돌리는 곳처럼 [UnsavedChangesScope] 로 감쌀 수
/// 없는 자리에서 직접 부른다.
Future<bool> confirmLeave(
  BuildContext context, {
  required String source,
  String title = '작성을 그만둘까요?',
  String description = '지금 나가면 쓰던 내용이 저장되지 않아요.',
  String stayLabel = '계속 쓰기',
  String leaveLabel = '나가기',
}) async {
  final leave = await showTossDialog<bool>(
    context: context,
    builder: (_) => _LeaveDialog(
      title: title,
      description: description,
      stayLabel: stayLabel,
      leaveLabel: leaveLabel,
    ),
  );
  AppAnalytics.logEvent('leave_confirm', {
    'source': source,
    'result': leave == true ? 'leave' : 'stay',
  });
  return leave == true;
}

class _LeaveDialog extends StatelessWidget {
  final String title;
  final String description;
  final String stayLabel;
  final String leaveLabel;

  const _LeaveDialog({
    required this.title,
    required this.description,
    this.stayLabel = '계속 쓰기',
    this.leaveLabel = '나가기',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StandardText(
                text: title,
                fontSize: 17,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              StandardText(
                text: description,
                fontSize: 14,
                color: AppColors.textSecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[50],
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          side: BorderSide(color: Colors.grey[200]!, width: 1),
                        ),
                      ),
                      child: StandardText(
                        text: stayLabel,
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
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                      ),
                      child: StandardText(
                        text: leaveLabel,
                        fontSize: 14,
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
